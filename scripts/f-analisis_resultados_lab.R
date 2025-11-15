# ============================================================================ #
# FUNCIONES PARA ANÁLISIS DE RESULTADOS DE LABORATORIO
# ============================================================================ #
# Este script contiene funciones para analizar resultados de laboratorio TPH
# incluyendo cálculos estadísticos con diseño de muestreo complejo (survey)
# ============================================================================ #

library(dplyr)
library(tidyr)
library(stringr)
library(survey)
library(sf)  # Para matching espacial con shapefiles

# ---------------------------------------------------------------------------- #
# FUNCIÓN: limpiar_resultados_laboratorio
# Limpia y procesa los datos de resultados de laboratorio (REMA/RAR)
# Esta es la BASE PRINCIPAL que se enriquecerá con otras fuentes
# ---------------------------------------------------------------------------- #
limpiar_resultados_laboratorio <- function(resultados_lab) {
  # NOTA: Se asume que las columnas ya están en MAYÚSCULAS (por estandarizar_columnas)
  
  # Convertir a caracteres y llenar locaciones vacías
  resultados_clean <- resultados_lab %>%
    dplyr::mutate(LOCACION = as.character(LOCACION)) %>%
    tidyr::fill(LOCACION, .direction = "down")
  
  # Extraer locación desde el nombre del punto si LOCACION sigue vacía
  resultados_clean <- resultados_clean %>%
    mutate(
      # Si LOCACION está vacía o es NA, extraerla del PUNTO
      LOCACION = ifelse(
        is.na(LOCACION) | LOCACION == "",
        PUNTO %>%
          str_remove("-[^-]+$") %>%
          str_replace("L-X,6,", "") %>%
          str_replace_all("(?<!PZ)PZ(?!EA)", ""),
        LOCACION
      ),
      
      # Limpiar código de punto: eliminar PZ pero mantener PZEA
      PUNTO_LIMPIO = PUNTO %>%
        str_replace_all("(?<!PZ)PZ(?!EA)", "") %>%
        str_replace("^EA", "PZEA")
    )
  
  # Renombrar PUNTO_LIMPIO a PUNTO
  resultados_clean <- resultados_clean %>%
    select(-PUNTO) %>%
    rename(PUNTO = PUNTO_LIMPIO)
  
  return(resultados_clean)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: unificar_rar_muestra
# Une los datos del RAR con los datos de la muestra seleccionada
# ---------------------------------------------------------------------------- #
unificar_rar_muestra <- function(rar_data, muestra_data, columnas_seleccionadas = NULL) {
  # Columnas por defecto si no se especifican
  if (is.null(columnas_seleccionadas)) {
    columnas_seleccionadas <- c("norte", "este", "grilla", "celda", 
                                 "superposiciones", "cod_colectora", "punto")
  }
  
  # Filtrar solo las columnas que existen en muestra_data
  columnas_existentes <- intersect(columnas_seleccionadas, names(muestra_data))
  
  # Unir las tablas
  juntos <- left_join(
    rar_data, 
    muestra_data %>% dplyr::select(all_of(columnas_existentes)), 
    by = "punto"
  )
  
  return(juntos)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: enriquecer_caso1_espacial
# CASO 1: Expedientes antiguos - Enriquece resultados_lab con matching ESPACIAL
# Usa st_intersects para asegurar que el punto caiga DENTRO de la grilla
# ---------------------------------------------------------------------------- #
enriquecer_caso1_espacial <- function(resultados_lab, coordenadas_puntos, marco_grillas_sf) {
  # NOTA: Todas las columnas ya están en MAYÚSCULAS
  
  # ==== CAPTURAR PUNTOS ORIGINALES PARA DIAGNÓSTICO ====
  puntos_lab_original <- unique(trimws(as.character(resultados_lab$PUNTO)))
  puntos_coord_original <- unique(trimws(as.character(coordenadas_puntos$PUNTO)))
  
  # Paso 1: Enriquecer con coordenadas de puntos (por código de punto)
  if (is.null(coordenadas_puntos)) {
    stop("Se requiere el archivo de coordenadas para el Caso 1")
  }
  
  # Verificar que coordenadas tenga las columnas necesarias
  if (!all(c("PUNTO", "NORTE", "ESTE") %in% names(coordenadas_puntos))) {
    stop("El archivo de coordenadas debe contener: PUNTO, NORTE, ESTE")
  }
  
  # Identificar puntos en cada archivo
  puntos_solo_en_lab <- setdiff(puntos_lab_original, puntos_coord_original)
  puntos_solo_en_coord <- setdiff(puntos_coord_original, puntos_lab_original)
  puntos_en_ambos <- intersect(puntos_lab_original, puntos_coord_original)
  
  # Seleccionar columnas útiles de coordenadas
  cols_coord <- intersect(
    c("PUNTO", "NORTE", "ESTE", "ALTITUD", "PROF", "CA"),
    names(coordenadas_puntos)
  )
  
  resultados_enriq <- resultados_lab %>%
    left_join(
      coordenadas_puntos %>% select(all_of(cols_coord)),
      by = "PUNTO",
      suffix = c("", "_COORD")
    )
  
  # Si hay columnas duplicadas, preferir las del archivo de coordenadas
  if ("PROF_COORD" %in% names(resultados_enriq)) {
    resultados_enriq <- resultados_enriq %>%
      mutate(PROF = coalesce(PROF_COORD, PROF)) %>%
      select(-PROF_COORD)
  }
  
  # Paso 2: MATCHING ESPACIAL con marco de grillas (si existe)
  if (!is.null(marco_grillas_sf)) {
    # Verificar que tenemos coordenadas NORTE y ESTE
    if (!all(c("NORTE", "ESTE") %in% names(resultados_enriq))) {
      warning("No se puede hacer matching espacial: faltan coordenadas NORTE/ESTE")
      return(resultados_enriq)
    }
    
    # Filtrar registros con coordenadas válidas
    datos_con_coords <- resultados_enriq %>%
      filter(!is.na(NORTE) & !is.na(ESTE))
    
    datos_sin_coords <- resultados_enriq %>%
      filter(is.na(NORTE) | is.na(ESTE))
    
    if (nrow(datos_con_coords) == 0) {
      warning("No hay registros con coordenadas válidas para matching espacial")
      return(resultados_enriq)
    }
    
    # Convertir puntos a objeto sf
    # Asumir sistema de coordenadas UTM (el más común en Perú es EPSG:32718 - WGS 84 / UTM zone 18S)
    puntos_sf <- st_as_sf(
      datos_con_coords,
      coords = c("ESTE", "NORTE"),
      crs = st_crs(marco_grillas_sf),  # Usar el mismo CRS del shapefile
      remove = FALSE  # Mantener las columnas ESTE y NORTE
    )
    
    # MATCHING ESPACIAL con st_join usando st_intersects
    # st_intersects asegura que el punto esté DENTRO del polígono, no cerca
    puntos_enriquecidos_sf <- st_join(
      puntos_sf,
      marco_grillas_sf,
      join = st_intersects,  # ← Punto debe estar DENTRO
      left = TRUE,  # Mantener todos los puntos, incluso sin match
      suffix = c("", "_MARCO")
    )
    
    # Convertir de vuelta a data.frame
    puntos_enriquecidos <- puntos_enriquecidos_sf %>%
      st_drop_geometry()
    
    # Resolver duplicados de LOCACION si existen
    if ("LOCACION_MARCO" %in% names(puntos_enriquecidos)) {
      puntos_enriquecidos <- puntos_enriquecidos %>%
        mutate(LOCACION = coalesce(LOCACION_MARCO, LOCACION)) %>%
        select(-LOCACION_MARCO)
    }
    
    # Combinar con los datos sin coordenadas
    if (nrow(datos_sin_coords) > 0) {
      resultados_final <- bind_rows(puntos_enriquecidos, datos_sin_coords)
    } else {
      resultados_final <- puntos_enriquecidos
    }
    
    # ==== CAPTURAR PUNTOS PROBLEMÁTICOS PARA DIAGNÓSTICO ====
    
    # Puntos sin coordenadas
    puntos_sin_coords_df <- resultados_final %>%
      filter(is.na(NORTE) | is.na(ESTE)) %>%
      select(PUNTO, LOCACION, any_of(c("TPH", "PROF"))) %>%
      mutate(RAZON = "No tiene coordenadas en archivo de coordenadas")
    
    # Puntos sin match espacial (tienen coordenadas pero no cayeron en ninguna grilla)
    puntos_sin_match_espacial <- resultados_final %>%
      filter(!is.na(NORTE) & !is.na(ESTE) & is.na(GRILLA)) %>%
      select(PUNTO, LOCACION, NORTE, ESTE, any_of(c("TPH", "PROF"))) %>%
      mutate(RAZON = "El punto no cae dentro de ninguna grilla del shapefile")
    
    # Reportar estadísticas de matching
    n_total <- nrow(resultados_final)
    n_con_match <- sum(!is.na(resultados_final$GRILLA))
    n_sin_match <- n_total - n_con_match
    
    message(sprintf(
      "Matching espacial completado:\n  - Total registros: %d\n  - Con match espacial: %d (%.1f%%)\n  - Sin match espacial: %d (%.1f%%)",
      n_total, n_con_match, (n_con_match/n_total)*100, n_sin_match, (n_sin_match/n_total)*100
    ))
    
    # ==== CREAR DIAGNÓSTICO COMPLETO ====
    diagnostico <- list(
      # Matching Lab-Coordenadas
      n_puntos_lab_original = length(puntos_lab_original),
      n_puntos_coord_original = length(puntos_coord_original),
      n_puntos_en_ambos = length(puntos_en_ambos),
      n_puntos_solo_lab = length(puntos_solo_en_lab),
      n_puntos_solo_coord = length(puntos_solo_en_coord),
      puntos_solo_en_lab = puntos_solo_en_lab,
      puntos_solo_en_coord = puntos_solo_en_coord,
      
      # Matching espacial
      n_puntos_finales = n_total,
      n_con_match_espacial = n_con_match,
      n_sin_match_espacial = n_sin_match,
      n_sin_coordenadas = nrow(puntos_sin_coords_df),
      puntos_sin_coordenadas = puntos_sin_coords_df,
      puntos_sin_match_espacial = puntos_sin_match_espacial,
      
      # Indicadores de problemas
      tiene_problema_coords = length(puntos_solo_en_lab) > 0,
      tiene_problema_espacial = n_sin_match > 0
    )
    
    # Retornar datos y diagnóstico
    return(list(
      datos = resultados_final,
      diagnostico = diagnostico
    ))
    
  } else {
    # Si no hay shapefile, retornar solo con coordenadas (sin diagnóstico espacial)
    diagnostico <- list(
      n_puntos_lab_original = length(puntos_lab_original),
      n_puntos_coord_original = length(puntos_coord_original),
      n_puntos_en_ambos = length(puntos_en_ambos),
      n_puntos_solo_lab = length(puntos_solo_en_lab),
      n_puntos_solo_coord = length(puntos_solo_en_coord),
      puntos_solo_en_lab = puntos_solo_en_lab,
      puntos_solo_en_coord = puntos_solo_en_coord,
      n_puntos_finales = nrow(resultados_enriq),
      tiene_problema_coords = length(puntos_solo_en_lab) > 0
    )
    
    return(list(
      datos = resultados_enriq,
      diagnostico = diagnostico
    ))
  }
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: enriquecer_caso1 (LEGACY - mantener por compatibilidad)
# CASO 1: Expedientes antiguos - Enriquece resultados_lab con coordenadas y marco_grillas
# ---------------------------------------------------------------------------- #
enriquecer_caso1 <- function(resultados_lab, coordenadas_puntos, marco_grillas) {
  # NOTA: Todas las columnas ya están en MAYÚSCULAS
  
  # Paso 1: Enriquecer con coordenadas de puntos (por código de punto)
  if (!is.null(coordenadas_puntos)) {
    # Seleccionar columnas útiles de coordenadas
    cols_coord <- intersect(
      c("PUNTO", "NORTE", "ESTE", "ALTITUD", "PROF", "CA"),
      names(coordenadas_puntos)
    )
    
    resultados_enriq <- resultados_lab %>%
      left_join(
        coordenadas_puntos %>% select(all_of(cols_coord)),
        by = "PUNTO",
        suffix = c("", "_COORD")
      )
    
    # Si hay columnas duplicadas, preferir las del archivo de coordenadas
    if ("PROF_COORD" %in% names(resultados_enriq)) {
      resultados_enriq <- resultados_enriq %>%
        mutate(PROF = coalesce(PROF_COORD, PROF)) %>%
        select(-PROF_COORD)
    }
  } else {
    resultados_enriq <- resultados_lab
  }
  
  # Paso 2: Enriquecer con marco de grillas (por grilla o crear join con locacion+celda)
  if (!is.null(marco_grillas)) {
    # Intentar unir por punto si existe en marco_grillas
    if ("PUNTO" %in% names(marco_grillas)) {
      cols_marco <- intersect(
        c("PUNTO", "LOCACION", "CELDA_COD_PLANO", "CELDA", "GRILLA", "AREA"),
        names(marco_grillas)
      )
      
      resultados_enriq <- resultados_enriq %>%
        left_join(
          marco_grillas %>% select(all_of(cols_marco)),
          by = "PUNTO",
          suffix = c("", "_MARCO")
        )
      
      # Resolver duplicados de locacion
      if ("LOCACION_MARCO" %in% names(resultados_enriq)) {
        resultados_enriq <- resultados_enriq %>%
          mutate(LOCACION = coalesce(LOCACION_MARCO, LOCACION)) %>%
          select(-LOCACION_MARCO)
      }
    }
  }
  
  return(resultados_enriq)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: enriquecer_caso2
# CASO 2: Expedientes recientes - Une resultados_lab con muestra_final de Fase 4
# RETORNA: lista con $datos y $diagnostico para identificar puntos perdidos
# ---------------------------------------------------------------------------- #
enriquecer_caso2 <- function(resultados_lab, muestra_final) {
  # NOTA: Todas las columnas ya están en MAYÚSCULAS
  
  # ==== DIAGNÓSTICO PREVIO ====
  # Capturar puntos originales antes del join
  puntos_muestra_original <- unique(trimws(as.character(muestra_final$PUNTO)))
  puntos_lab_original <- unique(trimws(as.character(resultados_lab$PUNTO)))
  
  # Normalizar códigos de punto para comparación (trimws ya aplicado)
  muestra_final_norm <- muestra_final %>%
    mutate(PUNTO_ORIGINAL = PUNTO,
           PUNTO = trimws(as.character(PUNTO)))
  
  resultados_lab_norm <- resultados_lab %>%
    mutate(PUNTO_ORIGINAL = PUNTO,
           PUNTO = trimws(as.character(PUNTO)))
  
  # Identificar qué puntos están en cada archivo
  puntos_solo_en_muestra <- setdiff(puntos_muestra_original, puntos_lab_original)
  puntos_solo_en_lab <- setdiff(puntos_lab_original, puntos_muestra_original)
  puntos_en_ambos <- intersect(puntos_muestra_original, puntos_lab_original)
  
  # La muestra final ya tiene toda la información necesaria
  # Solo necesitamos unir los valores de TPH desde resultados_lab
  
  # Unir por PUNTO
  datos_enriquecidos <- muestra_final_norm %>%
    left_join(
      resultados_lab_norm %>% select(PUNTO, LOCACION, TPH, PROF),
      by = "PUNTO",
      suffix = c("", "_LAB")
    )
  
  # Resolver duplicados
  if ("LOCACION_LAB" %in% names(datos_enriquecidos)) {
    datos_enriquecidos <- datos_enriquecidos %>%
      mutate(LOCACION = coalesce(LOCACION_LAB, LOCACION)) %>%
      select(-LOCACION_LAB)
  }
  
  if ("PROF_LAB" %in% names(datos_enriquecidos)) {
    datos_enriquecidos <- datos_enriquecidos %>%
      mutate(PROF = coalesce(PROF_LAB, PROF)) %>%
      select(-PROF_LAB)
  }
  
  # ==== CAPTURAR PUNTOS SIN TPH ANTES DE FILTRAR ====
  puntos_sin_tph <- datos_enriquecidos %>%
    filter(is.na(TPH)) %>%
    select(PUNTO, LOCACION, any_of(c("GRILLA", "CELDA", "COD_GRILLA", "COD_CELDA"))) %>%
    mutate(RAZON = "No se encontró en archivo de laboratorio")
  
  # Filtrar solo puntos que tienen TPH (están en resultados_lab)
  datos_enriquecidos <- datos_enriquecidos %>%
    filter(!is.na(TPH))
  
  # ==== CREAR DIAGNÓSTICO COMPLETO ====
  diagnostico <- list(
    n_puntos_muestra_original = length(puntos_muestra_original),
    n_puntos_lab_original = length(puntos_lab_original),
    n_puntos_en_ambos = length(puntos_en_ambos),
    n_puntos_solo_muestra = length(puntos_solo_en_muestra),
    n_puntos_solo_lab = length(puntos_solo_en_lab),
    n_puntos_perdidos = nrow(puntos_sin_tph),
    n_puntos_finales = nrow(datos_enriquecidos),
    puntos_solo_en_muestra = puntos_solo_en_muestra,
    puntos_solo_en_lab = puntos_solo_en_lab,
    puntos_sin_tph = puntos_sin_tph,
    tiene_problema = length(puntos_solo_en_muestra) > 0
  )
  
  # Retornar datos y diagnóstico
  return(list(
    datos = datos_enriquecidos,
    diagnostico = diagnostico
  ))
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: calcular_promedios_celdas
# Calcula promedios de TPH por celda usando diseño de muestreo complejo
# ---------------------------------------------------------------------------- #
calcular_promedios_celdas <- function(muestra_final_e, umbral = 10000) {
  # NOTA: Columnas en MAYÚSCULAS
  # Crear objeto survey
  survey_design_obj <- svydesign(
    ids = ~ PUNTO,    
    strata = ~ LOCACION + CELDA,    
    probs = ~ 1,    
    data = muestra_final_e,
    nest = TRUE
  )
  
  # Calcular promedios por celda
  Promedio_celdas <- svyby(
    ~ TPH, 
    ~ CELDA, 
    survey_design_obj, 
    svymean, 
    na.rm = TRUE, 
    keep.var = TRUE
  )
  
  # Valor crítico para IC 95%
  z <- qnorm(0.975)
  
  # Añadir intervalos de confianza
  Promedio_celdas <- Promedio_celdas %>%
    mutate(
      IC95_low = TPH - z * se,
      IC95_high = TPH + z * se,
      RSE = (se / TPH) * 100,
      impactada = ifelse(TPH > umbral, 1, 0)
    ) %>% 
    mutate(
      IC95_low = ifelse(IC95_low < 1, 0, IC95_low) %>% round(2),
      IC95_high = ifelse(IC95_high < 1, 0, IC95_high) %>% round(2),
      range = IC95_high - IC95_low
    )
  
  # Calcular proporción de puntos > umbral por celda
  Promedio_prop <- svyby(
    ~ I(TPH > umbral),
    ~ CELDA,
    survey_design_obj,
    svymean,
    na.rm = TRUE,
    keep.var = TRUE
  ) %>% 
    rename(
      prop_exceed = `I(TPH > umbral)TRUE`,
      se_prop = `se.I(TPH > umbral)TRUE`
    ) %>%
    mutate(
      IC95_low_prop = pmax(prop_exceed - z * se_prop, 0),
      IC95_high_prop = pmin(prop_exceed + z * se_prop, 1)
    ) %>% 
    select(CELDA, prop_exceed, se_prop, IC95_low_prop, IC95_high_prop)
  
  # Conteo de puntos por celda
  conteo_puntos_celda <- muestra_final_e %>%
    group_by(CELDA) %>%
    summarise(
      n_puntos_total = n(),
      n_puntos_impactados = sum(TPH > umbral, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Unir todo
  Promedio_celdas_final <- Promedio_celdas %>%
    left_join(
      Promedio_prop %>% select(CELDA, prop_exceed, IC95_low_prop, IC95_high_prop),
      by = "CELDA"
    ) %>%
    left_join(conteo_puntos_celda, by = "CELDA") %>%
    mutate(
      impactada_por_tph = ifelse(TPH > umbral, "Sí", "No"),
      impactada_por_proporcion = ifelse(prop_exceed > 0.5, "Sí", "No"),
      criterio_de_impacto = case_when(
        impactada_por_tph == "Sí" & impactada_por_proporcion == "Sí" ~ "Ambos criterios",
        impactada_por_tph == "Sí" ~ "Solo TPH promedio",
        impactada_por_proporcion == "Sí" ~ "Solo proporción",
        TRUE ~ "No impactada"
      )
    )
  
  return(Promedio_celdas_final)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: calcular_promedios_locaciones
# Calcula promedios de TPH por locación usando diseño de muestreo complejo
# ---------------------------------------------------------------------------- #
calcular_promedios_locaciones <- function(muestra_final_e, umbral = 10000) {
  # NOTA: Columnas en MAYÚSCULAS
  # Crear objeto survey
  survey_design_obj <- svydesign(
    ids = ~ PUNTO,    
    strata = ~ LOCACION,    
    probs = ~ 1,    
    data = muestra_final_e,
    nest = TRUE
  )
  
  # Calcular promedios por locación
  Promedio_locaciones <- svyby(
    ~ TPH, 
    ~ LOCACION, 
    survey_design_obj, 
    svymean, 
    na.rm = TRUE, 
    keep.var = TRUE
  )
  
  # Eliminar rownames
  rownames(Promedio_locaciones) <- NULL
  
  # Valor crítico para IC 95%
  z <- qnorm(0.975)
  
  # Añadir intervalos de confianza
  Promedio_locaciones <- Promedio_locaciones %>%
    mutate(
      IC95_low = TPH - z * se,
      IC95_high = TPH + z * se,
      RSE = (se / TPH) * 100,
      impactada = ifelse(TPH > umbral, 1, 0)
    ) %>% 
    mutate(
      IC95_low = ifelse(IC95_low < 1, 0, IC95_low) %>% round(2),
      IC95_high = ifelse(IC95_high < 1, 0, IC95_high) %>% round(2),
      range = IC95_high - IC95_low
    )
  
  # Calcular proporción de puntos > umbral por locación
  Promedio_prop <- svyby(
    ~ I(TPH > umbral),
    ~ LOCACION,
    survey_design_obj,
    svymean,
    na.rm = TRUE,
    keep.var = TRUE
  ) %>% 
    rename(
      prop_exceed = `I(TPH > umbral)TRUE`,
      se_prop = `se.I(TPH > umbral)TRUE`
    ) %>%
    mutate(
      IC95_low_prop = pmax(prop_exceed - z * se_prop, 0),
      IC95_high_prop = pmin(prop_exceed + z * se_prop, 1)
    ) %>% 
    select(LOCACION, prop_exceed, se_prop, IC95_low_prop, IC95_high_prop)
  
  # Conteo de puntos por locación
  conteo_puntos_loc <- muestra_final_e %>%
    group_by(LOCACION) %>%
    summarise(
      n_puntos_total = n(),
      n_puntos_impactados = sum(TPH > umbral, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Unir todo
  Promedio_locaciones_final <- Promedio_locaciones %>%
    left_join(
      Promedio_prop %>% select(LOCACION, prop_exceed, IC95_low_prop, IC95_high_prop),
      by = "LOCACION"
    ) %>%
    left_join(conteo_puntos_loc, by = "LOCACION") %>%
    mutate(
      impactada_por_tph = ifelse(TPH > umbral, "Sí", "No"),
      impactada_por_proporcion = ifelse(prop_exceed > 0.5, "Sí", "No"),
      criterio_de_impacto = case_when(
        impactada_por_tph == "Sí" & impactada_por_proporcion == "Sí" ~ "Ambos criterios",
        impactada_por_tph == "Sí" ~ "Solo TPH promedio",
        impactada_por_proporcion == "Sí" ~ "Solo proporción",
        TRUE ~ "No impactada"
      )
    )
  
  return(Promedio_locaciones_final)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: get_vertices
# Extrae vértices de polígonos que coinciden con códigos específicos
# ---------------------------------------------------------------------------- #
get_vertices <- function(sf_obj, code_col, codes) {
  # Filtrar los features por código
  sf_filtrado <- sf_obj %>%
    filter(.data[[code_col]] %in% codes)
  
  # Si no hay coincidencias, devolver tibble vacío
  if (nrow(sf_filtrado) == 0) {
    return(tibble::tibble(
      !!code_col := character(),
      part_id = integer(),
      ring_id = integer(),
      vertex_id = integer(),
      X = double(),
      Y = double()
    ))
  }
  
  # Casting progresivo para preservar estructura
  sf_pts <- sf_filtrado %>%
    st_cast("MULTIPOLYGON") %>%
    st_cast("POLYGON") %>%
    group_by(.data[[code_col]]) %>%
    mutate(part_id = dplyr::row_number()) %>%
    ungroup() %>%
    st_cast("MULTILINESTRING") %>%
    st_cast("LINESTRING") %>%
    group_by(.data[[code_col]], part_id) %>%
    mutate(ring_id = dplyr::row_number()) %>%
    ungroup() %>%
    st_cast("POINT") %>%
    group_by(.data[[code_col]], part_id, ring_id) %>%
    mutate(vertex_id = dplyr::row_number()) %>%
    ungroup()
  
  # Extraer coordenadas
  coords <- sf::st_coordinates(sf_pts)
  out <- dplyr::bind_cols(
    sf_pts |> st_drop_geometry() |> select(all_of(code_col), part_id, ring_id, vertex_id),
    as.data.frame(coords)[, c("X", "Y")]
  )
  
  # Ordenar
  out %>% arrange(.data[[code_col]], part_id, ring_id, vertex_id)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: generar_vertices_grillas
# Genera tabla de vértices de grillas impactadas con información enriquecida
# ---------------------------------------------------------------------------- #
generar_vertices_grillas <- function(shp_marco_grillas, muestra_final_e, 
                                     superan_grilla, punto_col = "punto", 
                                     umbral = 10000) {
  # Obtener vértices de las grillas impactadas
  vertices_grillas <- get_vertices(
    sf_obj = shp_marco_grillas,
    code_col = "COD_GRILLA",
    codes = superan_grilla
  )
  
  # Función auxiliar para normalizar llaves
  to_key <- function(x) trimws(as.character(x))
  
  # Lookup (punto, tph, grilla)
  lk_punto_grilla <- muestra_final_e %>%
    filter(grilla %in% superan_grilla) %>%
    transmute(
      codigo_punto = .data[[punto_col]],
      COD_GRILLA = to_key(grilla),
      tph
    ) %>%
    distinct()
  
  # Atributos de grilla desde shapefile
  attrs_grillas <- shp_marco_grillas %>%
    st_drop_geometry() %>%
    transmute(
      COD_GRILLA = to_key(COD_GRILLA),
      LOCACION,
      AREA
    )
  
  # Unir todo con los vértices
  vertices_grillas_enriq <- vertices_grillas %>%
    mutate(COD_GRILLA = to_key(COD_GRILLA)) %>%
    left_join(attrs_grillas, by = "COD_GRILLA") %>%
    inner_join(lk_punto_grilla, by = "COD_GRILLA") %>%
    mutate(
      criterio_de_impacto = ifelse(tph > umbral, "Supera umbral TPH", "No impactada")
    ) %>%
    relocate(criterio_de_impacto, codigo_punto, tph, LOCACION, COD_GRILLA, AREA, .before = part_id) %>%
    rename(ESTE = X, NORTE = Y)
  
  return(vertices_grillas_enriq)
}

# ---------------------------------------------------------------------------- #
# FUNCIÓN: generar_vertices_celdas
# Genera tabla de vértices de celdas impactadas con información enriquecida
# ---------------------------------------------------------------------------- #
generar_vertices_celdas <- function(shp_marco_celdas, Promedio_celdas_final, 
                                    muestra_final_e, celdas_vec, 
                                    shp_code_col = "COD_UNIC", 
                                    umbral = 10000) {
  # Función auxiliar
  to_key <- function(x) trimws(as.character(x))
  
  # Normalizar códigos
  codes <- unique(to_key(as.character(celdas_vec)))
  
  # Obtener vértices
  vtx <- get_vertices(
    sf_obj = shp_marco_celdas,
    code_col = shp_code_col,
    codes = codes
  )
  
  # Normalizar nombre del código a COD_UNIC
  if (shp_code_col != "COD_UNIC") {
    vtx <- vtx %>% rename(COD_UNIC = all_of(shp_code_col))
  }
  
  # Atributos desde shapefile
  attrs_celdas <- shp_marco_celdas %>%
    st_drop_geometry() %>%
    transmute(
      COD_UNIC = to_key(.data[[shp_code_col]]),
      LOCACION, 
      AREA,
      COD_PLANO = if("COD_PLANO" %in% names(.)) COD_PLANO else NA_character_
    )
  
  # Promedio TPH por celda
  prom_celdas <- Promedio_celdas_final %>%
    transmute(
      COD_UNIC = to_key(celda),
      tph_celda = tph
    ) %>%
    distinct()
  
  # Tabla de puntos con códigos y TPH
  mf_puntos <- muestra_final_e %>%
    transmute(
      COD_UNIC = to_key(celda),
      punto = as.character(punto),
      tph = as.numeric(tph)
    )
  
  # Totales y superan por celda
  totales_por_celda <- mf_puntos %>%
    filter(COD_UNIC %in% codes) %>%
    group_by(COD_UNIC) %>%
    summarise(n_puntos_total = n_distinct(punto), .groups = "drop")
  
  puntos_superan_df <- mf_puntos %>%
    filter(COD_UNIC %in% codes, !is.na(tph), tph > umbral) %>%
    group_by(COD_UNIC) %>%
    summarise(
      puntos_superan = paste(sort(unique(punto)), collapse = "; "),
      n_puntos_superan = dplyr::n_distinct(punto),
      .groups = "drop"
    )
  
  # Proporción
  prop_superan <- totales_por_celda %>%
    left_join(puntos_superan_df, by = "COD_UNIC") %>%
    mutate(
      n_puntos_superan = coalesce(n_puntos_superan, 0L),
      prop_superan_pct = if_else(
        n_puntos_total > 0,
        round(100 * n_puntos_superan / n_puntos_total, 2),
        NA_real_
      )
    ) %>%
    select(COD_UNIC, puntos_superan, prop_superan_pct)
  
  # Unir todo
  out <- vtx %>%
    mutate(COD_UNIC = to_key(COD_UNIC)) %>%
    left_join(attrs_celdas, by = "COD_UNIC") %>%
    left_join(prom_celdas, by = "COD_UNIC") %>%
    left_join(prop_superan, by = "COD_UNIC") %>%
    mutate(
      # Calcular proporción decimal para comparación
      prop_decimal = prop_superan_pct / 100,
      # Determinar criterio de impacto
      impactada_por_tph = ifelse(!is.na(tph_celda) & tph_celda > umbral, TRUE, FALSE),
      impactada_por_proporcion = ifelse(!is.na(prop_decimal) & prop_decimal > 0.5, TRUE, FALSE),
      criterio_de_impacto = case_when(
        impactada_por_tph & impactada_por_proporcion ~ "Ambos criterios",
        impactada_por_tph ~ "Solo TPH promedio",
        impactada_por_proporcion ~ "Solo proporción",
        TRUE ~ "No impactada"
      )
    ) %>%
    select(-prop_decimal, -impactada_por_tph, -impactada_por_proporcion) %>%
    relocate(criterio_de_impacto, COD_UNIC, LOCACION, AREA, tph_celda, puntos_superan, prop_superan_pct, .before = part_id) %>%
    rename(ESTE = X, NORTE = Y)
  
  return(out)
}
