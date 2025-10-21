# ============================================================================
# FUNCIÓN: Verificación Espacial de Marcos Shapefile
# ============================================================================
# Propósito: Validar la coherencia espacial entre grillas y celdas
# Autor: Sistema de Análisis OEFA
# Fecha creación: 2025-01-21
# ============================================================================

library(sf)
library(dplyr)

#' Generar o extraer centroides de grillas
#'
#' @param shp_grillas Objeto sf con geometrías de grillas (puntos o polígonos)
#' @param col_grilla Nombre de la columna con códigos de grilla
#' @return Data frame con COD_GRILLA, ESTE, NORTE
generar_centroides_grillas <- function(shp_grillas, col_grilla = "GRILLA") {
  
  cat("\n=== Generando/Extrayendo Centroides de Grillas ===\n")
  
  # Verificar que la columna existe
  if (!col_grilla %in% names(shp_grillas)) {
    stop(paste0("No se encontró la columna '", col_grilla, "' en el shapefile de grillas"))
  }
  
  cat("✓ Columna de grilla encontrada:", col_grilla, "\n")
  
  # Detectar tipo de geometría con manejo de errores
  geom_type <- tryCatch({
    tipos <- st_geometry_type(shp_grillas)
    if (length(tipos) > 0) tipos[1] else "UNKNOWN"
  }, error = function(e) {
    cat("⚠️ No se pudo detectar tipo de geometría:", conditionMessage(e), "\n")
    return("UNKNOWN")
  })
  
  cat("Tipo de geometría detectado:", as.character(geom_type), "\n")
  
  # Verificar si ya tiene ESTE y NORTE en los atributos
  tiene_coordenadas <- all(c("ESTE", "NORTE") %in% names(shp_grillas))
  
  if (tiene_coordenadas) {
    cat("✓ Shapefile ya contiene columnas ESTE y NORTE\n")
    
    # Verificar si son puntos y las coordenadas coinciden con la geometría
    if (geom_type == "POINT") {
      coords_geom <- st_coordinates(shp_grillas)
      tol <- 1e-6
      coinciden <- all(abs(shp_grillas$ESTE - coords_geom[,1]) < tol & 
                      abs(shp_grillas$NORTE - coords_geom[,2]) < tol)
      
      if (coinciden) {
        cat("✓ Coordenadas coinciden con geometría POINT\n")
        # Extraer datos sin usar rename
        datos <- st_drop_geometry(shp_grillas)
        resultado <- data.frame(
          COD_GRILLA = datos[[col_grilla]],
          ESTE = datos$ESTE,
          NORTE = datos$NORTE
        )
        return(resultado)
      } else {
        cat("⚠️ Coordenadas en atributos no coinciden con geometría, recalculando...\n")
      }
    }
  }
  
  # Si no tiene coordenadas o no coinciden, generar centroides
  cat("→ Calculando centroides de geometrías...\n")
  
  # Calcular centroides con manejo de errores
  centroides <- tryCatch({
    st_centroid(shp_grillas)
  }, error = function(e) {
    cat("⚠️ Error al calcular centroides, intentando con st_point_on_surface...\n")
    st_point_on_surface(shp_grillas)
  })
  
  coords <- st_coordinates(centroides)
  
  # Extraer códigos de grilla usando el nombre original de la columna
  codigos_grilla <- st_drop_geometry(shp_grillas)[[col_grilla]]
  
  # Crear data frame resultado
  resultado <- data.frame(
    COD_GRILLA = codigos_grilla,
    ESTE = coords[,1],
    NORTE = coords[,2],
    stringsAsFactors = FALSE
  )
  
  cat("✓ Centroides generados exitosamente\n")
  cat("  Total de grillas:", nrow(resultado), "\n\n")
  
  return(resultado)
}


#' Identificar grillas cuyos centroides caen fuera de cualquier celda
#'
#' @param centroides_grillas Data frame con COD_GRILLA, ESTE, NORTE
#' @param shp_celdas Objeto sf con polígonos de celdas
#' @param col_celda Nombre de la columna con códigos de celda en shp_celdas
#' @return Lista con: grillas_fuera (data frame), n_fuera (número)
identificar_grillas_fuera_celdas <- function(centroides_grillas, shp_celdas, col_celda = "CELDA") {
  
  cat("\n=== Identificando Grillas Fuera de Celdas ===\n")
  
  # Verificar que la columna existe
  if (!col_celda %in% names(shp_celdas)) {
    stop(paste0("No se encontró la columna '", col_celda, "' en el shapefile de celdas"))
  }
  
  cat("✓ Columna de celda encontrada:", col_celda, "\n")
  
  # Obtener CRS de celdas
  crs_celdas <- st_crs(shp_celdas)
  
  # Convertir centroides a objeto sf con el mismo CRS
  centroides_sf <- st_as_sf(
    centroides_grillas,
    coords = c("ESTE", "NORTE"),
    crs = crs_celdas
  )
  
  # Hacer spatial join con st_intersects
  # NO usar select(), mantener todo el objeto sf
  cat("→ Ejecutando st_intersects...\n")
  join_result <- st_join(
    centroides_sf,
    shp_celdas,
    join = st_intersects,
    left = TRUE
  )
  
  # Extraer datos sin geometría
  datos_join <- st_drop_geometry(join_result)
  
  # Crear un sufijo temporal para evitar conflictos si hay columnas duplicadas
  # Obtener el valor de la columna de celda del join
  celda_values <- datos_join[[col_celda]]
  
  # Identificar grillas sin match (columna de celda es NA)
  indices_fuera <- which(is.na(celda_values))
  
  if (length(indices_fuera) > 0) {
    grillas_fuera <- centroides_grillas[indices_fuera, ]
  } else {
    # No hay grillas fuera, retornar data frame vacío con las columnas correctas
    grillas_fuera <- data.frame(
      COD_GRILLA = character(0),
      ESTE = numeric(0),
      NORTE = numeric(0)
    )
  }
  
  n_fuera <- nrow(grillas_fuera)
  n_total <- nrow(centroides_grillas)
  pct_fuera <- if (n_total > 0) round(100 * n_fuera / n_total, 2) else 0
  
  cat("\n📊 RESULTADO:\n")
  cat("  Total de grillas:", n_total, "\n")
  cat("  Grillas FUERA de celdas:", n_fuera, "(", pct_fuera, "%)\n")
  cat("  Grillas DENTRO de celdas:", n_total - n_fuera, "(", 100 - pct_fuera, "%)\n\n")
  
  return(list(
    grillas_fuera = grillas_fuera,
    n_fuera = n_fuera,
    n_total = n_total,
    pct_fuera = pct_fuera
  ))
}


#' Identificar grillas con código de celda mal asignado
#'
#' @param shp_grillas Objeto sf con grillas que contiene columna de celda asignada
#' @param shp_celdas Objeto sf con polígonos de celdas
#' @param col_grilla Nombre de columna de código de grilla
#' @param col_celda_grillas Nombre de columna de celda ASIGNADA en grillas
#' @param col_celda_celdas Nombre de columna de celda en celdas
#' @return Lista con: mal_asignadas (data frame), n_mal_asignadas (número)
identificar_celdas_mal_asignadas <- function(shp_grillas, shp_celdas, 
                                             col_grilla = "GRILLA",
                                             col_celda_grillas = "CELDA",
                                             col_celda_celdas = "CELDA") {
  
  cat("\n=== Verificando Asignación de Códigos de Celda ===\n")
  
  # Verificar que el shapefile de grillas tenga columna de celda
  if (!col_celda_grillas %in% names(shp_grillas)) {
    cat("⚠️ El shapefile de grillas no contiene columna '", col_celda_grillas, "'\n")
    cat("   No se puede verificar asignación de celdas.\n\n")
    return(list(
      mal_asignadas = NULL,
      n_mal_asignadas = 0,
      verificacion_posible = FALSE
    ))
  }
  
  cat("✓ Columna de celda encontrada en grillas:", col_celda_grillas, "\n")
  
  # Generar centroides de grillas
  centroides <- st_centroid(shp_grillas)
  
  # Hacer spatial join para obtener celda REAL donde cae cada centroide
  # Usar suffix para evitar conflictos de nombres de columnas
  cat("→ Ejecutando st_intersects para determinar celda real...\n")
  join_result <- st_join(
    centroides,
    shp_celdas,
    join = st_intersects,
    left = TRUE,
    suffix = c("_GRILLA", "_CELDA")
  )
  
  # Extraer datos sin geometría
  datos_join_raw <- st_drop_geometry(join_result)
  
  # CRÍTICO: Detectar si hay duplicados (celdas apiladas)
  n_grillas_orig <- nrow(shp_grillas)
  n_joins <- nrow(datos_join_raw)
  
  if (n_joins > n_grillas_orig) {
    cat("\n⚠️ ALERTA: Se detectaron CELDAS DUPLICADAS (apiladas)\n")
    cat("  Grillas originales:", n_grillas_orig, "\n")
    cat("  Filas después de join:", n_joins, "\n")
    cat("  Diferencia:", n_joins - n_grillas_orig, "matches extras\n")
    
    # Identificar qué grillas tienen múltiples matches
    col_grilla_temp <- paste0(col_grilla, "_GRILLA")
    if (!col_grilla_temp %in% names(datos_join_raw)) {
      col_grilla_temp <- col_grilla
    }
    
    grillas_con_duplicados <- datos_join_raw %>%
      group_by(.data[[col_grilla_temp]]) %>%
      filter(n() > 1) %>%
      ungroup()
    
    if (nrow(grillas_con_duplicados) > 0) {
      cat("\n📋 Grillas afectadas por celdas duplicadas:\n")
      grillas_unicas_duplicadas <- unique(grillas_con_duplicados[[col_grilla_temp]])
      cat("  Total de grillas afectadas:", length(grillas_unicas_duplicadas), "\n")
      cat("  Códigos:", paste(head(grillas_unicas_duplicadas, 10), collapse = ", "))
      if (length(grillas_unicas_duplicadas) > 10) cat(", ...")
      cat("\n")
      
      # Mostrar ejemplo de celda duplicada
      ejemplo <- grillas_con_duplicados %>% 
        slice(1:2)
      cat("\n  Ejemplo de duplicación detectada:\n")
      print(ejemplo[, c(col_grilla_temp, paste0(col_celda_celdas, "_CELDA"))])
    }
    
    cat("\n→ Eliminando duplicados (tomando primer match por grilla)...\n")
    
    # Tomar solo el primer match por grilla
    datos_join <- datos_join_raw %>%
      group_by(.data[[col_grilla_temp]]) %>%
      slice(1) %>%
      ungroup() %>%
      as.data.frame()
    
  } else {
    cat("✓ No se detectaron celdas duplicadas\n")
    datos_join <- datos_join_raw
  }
  
  # Extraer coordenadas de centroides
  coords <- st_coordinates(centroides)
  
  # Extraer datos originales de grillas
  datos_grillas <- st_drop_geometry(shp_grillas)
  
  # Determinar nombres de columnas después del join
  # Si había duplicados, tendrán sufijos _GRILLA y _CELDA
  col_celda_asignada <- paste0(col_celda_grillas, "_GRILLA")
  col_celda_real <- paste0(col_celda_celdas, "_CELDA")
  
  # Verificar si las columnas con sufijos existen, sino usar originales
  if (!col_celda_asignada %in% names(datos_join)) {
    col_celda_asignada <- col_celda_grillas
  }
  if (!col_celda_real %in% names(datos_join)) {
    col_celda_real <- col_celda_celdas
  }
  
  # Determinar nombre de columna de grilla después del join
  col_grilla_join <- paste0(col_grilla, "_GRILLA")
  if (!col_grilla_join %in% names(datos_join)) {
    col_grilla_join <- col_grilla
  }
  
  cat("→ Columna de grilla:", col_grilla_join, "\n")
  cat("→ Columna de celda asignada:", col_celda_asignada, "\n")
  cat("→ Columna de celda real:", col_celda_real, "\n")
  
  # Comparar celda asignada vs celda real
  comparacion <- data.frame(
    COD_GRILLA = datos_join[[col_grilla_join]],
    CELDA_ASIGNADA = trimws(as.character(datos_join[[col_celda_asignada]])),
    CELDA_REAL = trimws(as.character(datos_join[[col_celda_real]])),
    ESTE_CENTROIDE = coords[,1],
    NORTE_CENTROIDE = coords[,2],
    stringsAsFactors = FALSE
  )
  
  # Identificar mal asignadas
  mal_asignadas <- comparacion %>%
    filter(CELDA_ASIGNADA != CELDA_REAL | is.na(CELDA_REAL)) %>%
    mutate(
      PROBLEMA = case_when(
        is.na(CELDA_REAL) ~ "Centroide fuera de celdas",
        CELDA_ASIGNADA != CELDA_REAL ~ "Código de celda incorrecto"
      )
    )
  
  n_mal_asignadas <- nrow(mal_asignadas)
  n_total <- nrow(comparacion)
  pct_mal <- round(100 * n_mal_asignadas / n_total, 2)
  
  cat("\n📊 RESULTADO:\n")
  cat("  Total de grillas verificadas:", n_total, "\n")
  cat("  Grillas con celda CORRECTA:", n_total - n_mal_asignadas, "\n")
  cat("  Grillas con celda MAL ASIGNADA:", n_mal_asignadas, "(", pct_mal, "%)\n")
  
  if (n_mal_asignadas > 0) {
    tabla_problemas <- mal_asignadas %>%
      count(PROBLEMA) %>%
      rename(Tipo_Problema = PROBLEMA, Cantidad = n)
    cat("\n  Desglose de problemas:\n")
    print(tabla_problemas)
  }
  
  cat("\n")
  
  # Preparar información sobre celdas duplicadas
  tiene_duplicados <- n_joins > n_grillas_orig
  info_duplicados <- NULL
  
  if (tiene_duplicados && exists("grillas_con_duplicados")) {
    info_duplicados <- list(
      n_duplicados = n_joins - n_grillas_orig,
      grillas_afectadas = unique(grillas_con_duplicados[[col_grilla_temp]]),
      ejemplo_duplicacion = if(nrow(grillas_con_duplicados) > 0) {
        head(grillas_con_duplicados, 20)
      } else NULL
    )
  }
  
  return(list(
    mal_asignadas = mal_asignadas,
    todas_verificadas = comparacion,
    n_mal_asignadas = n_mal_asignadas,
    n_total = n_total,
    pct_mal = pct_mal,
    verificacion_posible = TRUE,
    tiene_duplicados = tiene_duplicados,
    info_duplicados = info_duplicados
  ))
}


#' Limpiar shapefile de grillas eliminando las que caen fuera de celdas
#'
#' @param shp_grillas Objeto sf con grillas original
#' @param codigos_fuera Vector de códigos de grillas a eliminar
#' @param col_grilla Nombre de columna de código de grilla
#' @return Objeto sf limpiado
limpiar_shapefile_grillas <- function(shp_grillas, codigos_fuera, col_grilla = "GRILLA") {
  
  cat("\n=== Limpiando Shapefile de Grillas ===\n")
  
  n_original <- nrow(shp_grillas)
  
  if (length(codigos_fuera) == 0) {
    cat("✓ No hay grillas para eliminar\n")
    return(shp_grillas)
  }
  
  # Filtrar grillas
  shp_limpio <- shp_grillas %>%
    filter(!(.data[[col_grilla]] %in% codigos_fuera))
  
  n_limpio <- nrow(shp_limpio)
  n_eliminadas <- n_original - n_limpio
  
  cat("  Grillas originales:", n_original, "\n")
  cat("  Grillas eliminadas:", n_eliminadas, "\n")
  cat("  Grillas en marco limpio:", n_limpio, "\n\n")
  
  return(shp_limpio)
}
