# ============================================================================ #
# HANDLERS Y OUTPUTS ADICIONALES PARA FASE 5 - ANÁLISIS DE RESULTADOS
# ============================================================================ #
# Este archivo contiene outputs y handlers de descarga para la Fase 5
# Para ser incluido en el servidor principal de la app
# ============================================================================ #

# Función auxiliar para generar nombre de archivo con prefijo de código de expediente
generar_nombre_archivo_fase5 <- function(nombre_base, extension = ".xlsx") {
  codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
    paste0(input$codigo_expediente, "_")
  } else {
    ""
  }
  paste0(codigo_exp, nombre_base, "-", Sys.Date(), extension)
}

# ANÁLISIS NIVEL CELDAS - Outputs
output$resumen_celdas_analisis <- renderPrint({
  req(promedios_celdas_resultado())
  
  prom_celdas <- promedios_celdas_resultado()
  umbral <- input$umbral_tph
  
  contam_tph <- sum(prom_celdas$contaminada_por_tph == "Sí", na.rm = TRUE)
  contam_prop <- sum(prom_celdas$contaminada_por_proporcion == "Sí", na.rm = TRUE)
  
  # Contaminadas únicas (ambos criterios)
  celdas_contam_unicas <- prom_celdas %>%
    filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
    pull(CELDA) %>%
    unique() %>%
    sort()
  
  cat("ANÁLISIS POR CELDAS\n")
  cat("===================\n\n")
  cat("Total de celdas:", nrow(prom_celdas), "\n")
  cat("Contaminadas por TPH promedio:", contam_tph, "\n")
  cat("Contaminadas por proporción (>50%):", contam_prop, "\n")
  cat("Contaminadas únicas (ambos criterios):", length(celdas_contam_unicas), "\n\n")
  cat("Códigos contaminados:\n")
  if (length(celdas_contam_unicas) > 0) {
    cat(paste(celdas_contam_unicas, collapse = ", "))
  }
})

output$tabla_promedios_celdas <- renderDT({
  req(promedios_celdas_resultado())
  
  # Mover criterio_contaminacion a primera columna
  datos <- promedios_celdas_resultado()
  if ("criterio_contaminacion" %in% names(datos)) {
    datos <- datos %>% select(criterio_contaminacion, everything())
  }
  
  datatable(
    datos,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatRound(columns = c("TPH", "se", "IC95_low", "IC95_high", "prop_exceed"), digits = 2) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Ambos criterios", "Solo TPH promedio", "Solo proporción", "No contaminada"),
      c("#dc3545", "#ff6b6b", "#ffa500", "#28a745")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

output$tabla_celdas_contaminadas <- renderDT({
  req(promedios_celdas_resultado())
  
  prom_celdas <- promedios_celdas_resultado()
  celdas_contam <- prom_celdas %>%
    filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
    select(criterio_contaminacion, everything())
  
  datatable(
    celdas_contam,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatRound(columns = c("TPH", "IC95_low", "IC95_high", "prop_exceed"), digits = 2) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Ambos criterios", "Solo TPH promedio", "Solo proporción"),
      c("#dc3545", "#ff6b6b", "#ffa500")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

# ANÁLISIS NIVEL LOCACIONES - Outputs
output$resumen_locaciones_analisis <- renderPrint({
  req(promedios_locaciones_resultado())
  
  prom_loc <- promedios_locaciones_resultado()
  
  contam_tph <- sum(prom_loc$contaminada_por_tph == "Sí", na.rm = TRUE)
  contam_prop <- sum(prom_loc$contaminada_por_proporcion == "Sí", na.rm = TRUE)
  
  # Contaminadas únicas (ambos criterios)
  loc_contam_unicas <- prom_loc %>%
    filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
    pull(LOCACION) %>%
    unique() %>%
    sort()
  
  cat("ANÁLISIS POR LOCACIONES\n")
  cat("=======================\n\n")
  cat("Total de locaciones:", nrow(prom_loc), "\n")
  cat("Contaminadas por TPH promedio:", contam_tph, "\n")
  cat("Contaminadas por proporción (>50%):", contam_prop, "\n")
  cat("Contaminadas únicas (ambos criterios):", length(loc_contam_unicas), "\n\n")
  cat("Códigos contaminados:\n")
  if (length(loc_contam_unicas) > 0) {
    cat(paste(loc_contam_unicas, collapse = ", "))
  }
})

output$tabla_promedios_locaciones <- renderDT({
  req(promedios_locaciones_resultado())
  
  # Mover criterio_contaminacion a primera columna
  datos <- promedios_locaciones_resultado()
  if ("criterio_contaminacion" %in% names(datos)) {
    datos <- datos %>% select(criterio_contaminacion, everything())
  }
  
  datatable(
    datos,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatRound(columns = c("TPH", "se", "IC95_low", "IC95_high", "prop_exceed"), digits = 2) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Ambos criterios", "Solo TPH promedio", "Solo proporción", "No contaminada"),
      c("#dc3545", "#ff6b6b", "#ffa500", "#28a745")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

output$tabla_locaciones_contaminadas <- renderDT({
  req(promedios_locaciones_resultado())
  
  prom_loc <- promedios_locaciones_resultado()
  loc_contam <- prom_loc %>%
    filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
    select(criterio_contaminacion, everything())
  
  datatable(
    loc_contam,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatRound(columns = c("TPH", "IC95_low", "IC95_high", "prop_exceed"), digits = 2) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Ambos criterios", "Solo TPH promedio", "Solo proporción"),
      c("#dc3545", "#ff6b6b", "#ffa500")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

# GENERACIÓN DE VÉRTICES
observeEvent(input$generar_vertices_btn, {
  req(muestra_enriquecida())
  
  if (is.null(shp_grillas_data()) && is.null(shp_celdas_data())) {
    showNotification("Debe cargar al menos un shapefile", type = "error")
    return()
  }
  
  showNotification("Generando vértices...", type = "message", duration = 5)
  
  tryCatch({
    umbral <- input$umbral_tph
    datos <- muestra_enriquecida()
    
    # Procesar shapefile de grillas
    if (!is.null(shp_grillas_data())) {
      req(input$col_grilla_shp, input$col_locacion_grilla_shp, input$col_area_grilla_shp)
      
      shp_grillas <- shp_grillas_data()
      col_grilla_shp <- input$col_grilla_shp
      col_locacion_shp <- input$col_locacion_grilla_shp
      col_area_shp <- input$col_area_grilla_shp
      
      # Crear columnas requeridas por generar_vertices_grillas
      shp_grillas <- shp_grillas %>%
        mutate(
          COD_GRILLA = .data[[col_grilla_shp]],
          LOCACION = .data[[col_locacion_shp]],
          AREA = .data[[col_area_shp]]
        )
      
      # Preparar datos con columnas en minúscula (requeridas por generar_vertices_grillas)
      datos_prep <- datos
      if ("GRILLA" %in% names(datos)) {
        datos_prep <- datos_prep %>% 
          mutate(
            grilla = GRILLA,
            punto = if("PUNTO" %in% names(.)) PUNTO else punto,
            tph = if("TPH" %in% names(.)) TPH else tph
          )
        
        superan_grilla <- datos_prep %>% filter(tph > umbral) %>% pull(grilla) %>% unique()
        
        if (length(superan_grilla) > 0) {
          # Filtrar shapefile por las grillas contaminadas
          shp_grillas_filtrado <- shp_grillas %>% filter(COD_GRILLA %in% superan_grilla)
          
          if (nrow(shp_grillas_filtrado) > 0) {
            vert_grillas <- generar_vertices_grillas(shp_grillas_filtrado, datos_prep, superan_grilla)
            vertices_grillas_resultado(vert_grillas)
          }
        }
      }
    }
    
    # Procesar shapefile de celdas
    if (!is.null(shp_celdas_data()) && !is.null(promedios_celdas_resultado())) {
      req(input$col_celda_shp, input$col_locacion_celda_shp, input$col_area_celda_shp)
      
      shp_celdas <- shp_celdas_data()
      col_celda_shp <- input$col_celda_shp
      col_locacion_shp <- input$col_locacion_celda_shp
      col_area_shp <- input$col_area_celda_shp
      prom_celdas <- promedios_celdas_resultado()
      
      # Crear columnas requeridas en shapefile (LOCACION y AREA)
      # Nota: COD_UNIC se crea dinámicamente en generar_vertices_celdas
      shp_celdas <- shp_celdas %>%
        mutate(
          LOCACION = .data[[col_locacion_shp]],
          AREA = .data[[col_area_shp]]
        )
      
      # Preparar datos con columnas en minúscula (requeridas por generar_vertices_celdas)
      datos_prep <- datos
      if ("CELDA" %in% names(datos)) {
        datos_prep <- datos_prep %>% 
          mutate(
            celda = CELDA,
            punto = if("PUNTO" %in% names(.)) PUNTO else punto,
            tph = if("TPH" %in% names(.)) TPH else tph
          )
      }
      
      # Preparar promedios con columnas en minúscula
      prom_celdas_prep <- prom_celdas
      if ("CELDA" %in% names(prom_celdas)) {
        prom_celdas_prep <- prom_celdas_prep %>% 
          mutate(
            celda = CELDA,
            tph = if("TPH" %in% names(.)) TPH else tph
          )
      }
      
      superan_celdas_tph <- prom_celdas %>% filter(TPH > umbral) %>% pull(CELDA)
      superan_celdas_prop <- prom_celdas %>% filter(prop_exceed > 0.5) %>% pull(CELDA)
      
      if (length(superan_celdas_tph) > 0) {
        shp_celdas_tph <- shp_celdas %>% filter(.data[[col_celda_shp]] %in% superan_celdas_tph)
        if (nrow(shp_celdas_tph) > 0) {
          vert_celdas_tph <- generar_vertices_celdas(
            shp_celdas_tph, prom_celdas_prep, datos_prep, superan_celdas_tph, 
            shp_code_col = col_celda_shp, umbral = umbral
          )
          vertices_celdas_tph_resultado(vert_celdas_tph)
        }
      }
      
      if (length(superan_celdas_prop) > 0) {
        shp_celdas_prop <- shp_celdas %>% filter(.data[[col_celda_shp]] %in% superan_celdas_prop)
        if (nrow(shp_celdas_prop) > 0) {
          vert_celdas_prop <- generar_vertices_celdas(
            shp_celdas_prop, prom_celdas_prep, datos_prep, superan_celdas_prop, 
            shp_code_col = col_celda_shp, umbral = umbral
          )
          vertices_celdas_prop_resultado(vert_celdas_prop)
        }
      }
    }
    
    showNotification("Vértices generados exitosamente", type = "message")
    updateTabsetPanel(session, "tabset_fase5", selected = "Vértices de Polígonos")
    
  }, error = function(e) {
    registrar_error(e, "Generación de Vértices")
    showNotification(paste("Error al generar vértices:", conditionMessage(e)), type = "error", duration = 10)
  })
})

# Outputs de vértices
output$estado_vertices <- renderPrint({
  cat("ESTADO DE GENERACIÓN DE VÉRTICES\n")
  cat("=================================\n\n")
  
  if (!is.null(vertices_grillas_resultado())) {
    cat("✓ Vértices de grillas:", nrow(vertices_grillas_resultado()), "vértices\n")
  } else {
    cat("✗ Vértices de grillas: No generados\n")
  }
  
  if (!is.null(vertices_celdas_tph_resultado())) {
    cat("✓ Vértices de celdas (TPH):", nrow(vertices_celdas_tph_resultado()), "vértices\n")
  } else {
    cat("✗ Vértices de celdas (TPH): No generados\n")
  }
  
  if (!is.null(vertices_celdas_prop_resultado())) {
    cat("✓ Vértices de celdas (Proporción):", nrow(vertices_celdas_prop_resultado()), "vértices\n")
  } else {
    cat("✗ Vértices de celdas (Proporción): No generados\n")
  }
})

output$tabla_vertices_grillas <- renderDT({
  req(vertices_grillas_resultado())
  datatable(
    head(vertices_grillas_resultado(), 100),
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  )
})

output$tabla_vertices_celdas <- renderDT({
  req(vertices_celdas_tph_resultado())
  datatable(
    head(vertices_celdas_tph_resultado(), 100),
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  )
})

# RESUMEN FINAL
output$reporte_final_resultados <- renderPrint({
  req(muestra_enriquecida())
  
  datos <- muestra_enriquecida()
  umbral <- input$umbral_tph
  
  cat("REPORTE FINAL DE ANÁLISIS\n")
  cat("=========================\n\n")
  cat("Umbral TPH:", umbral, "mg/kg\n\n")
  
  grillas_contam <- datos %>% filter(TPH > umbral)
  cat("NIVEL GRILLA\n")
  cat("Total puntos:", nrow(datos), "\n")
  cat("Contaminados:", nrow(grillas_contam), "\n\n")
  
  if (!is.null(promedios_celdas_resultado())) {
    prom_celdas <- promedios_celdas_resultado()
    cat("NIVEL CELDA\n")
    cat("Total celdas:", nrow(prom_celdas), "\n")
    cat("Contaminadas (TPH):", sum(prom_celdas$contaminada_por_tph == "Sí"), "\n")
    cat("Contaminadas (Prop):", sum(prom_celdas$contaminada_por_proporcion == "Sí"), "\n\n")
  }
  
  if (!is.null(promedios_locaciones_resultado())) {
    prom_loc <- promedios_locaciones_resultado()
    cat("NIVEL LOCACIÓN\n")
    cat("Total locaciones:", nrow(prom_loc), "\n")
    cat("Contaminadas (TPH):", sum(prom_loc$contaminada_por_tph == "Sí"), "\n")
    cat("Contaminadas (Prop):", sum(prom_loc$contaminada_por_proporcion == "Sí"), "\n")
  }
})

output$codigos_grillas_contaminadas <- renderPrint({
  req(muestra_enriquecida())
  datos <- muestra_enriquecida()
  umbral <- input$umbral_tph
  
  codigos <- datos %>% filter(TPH > umbral) %>% pull(GRILLA) %>% unique() %>% sort()
  
  cat("Total:", length(codigos), "\n\n")
  if (length(codigos) > 0) {
    cat(paste(codigos, collapse = "\n"))
  }
})

output$codigos_celdas_contaminadas <- renderPrint({
  req(promedios_celdas_resultado())
  prom_celdas <- promedios_celdas_resultado()
  
  cod_tph <- prom_celdas %>% filter(contaminada_por_tph == "Sí") %>% pull(CELDA)
  cod_prop <- prom_celdas %>% filter(contaminada_por_proporcion == "Sí") %>% pull(CELDA)
  
  cat("Por TPH:", length(cod_tph), "\n")
  if (length(cod_tph) > 0) cat(paste(cod_tph, collapse = ", "), "\n\n")
  
  cat("Por Proporción:", length(cod_prop), "\n")
  if (length(cod_prop) > 0) cat(paste(cod_prop, collapse = ", "))
})

output$codigos_locaciones_contaminadas <- renderPrint({
  req(promedios_locaciones_resultado())
  prom_loc <- promedios_locaciones_resultado()
  
  cod_tph <- prom_loc %>% filter(contaminada_por_tph == "Sí") %>% pull(LOCACION)
  cod_prop <- prom_loc %>% filter(contaminada_por_proporcion == "Sí") %>% pull(LOCACION)
  
  cat("Por TPH:", length(cod_tph), "\n")
  if (length(cod_tph) > 0) cat(paste(cod_tph, collapse = ", "), "\n\n")
  
  cat("Por Proporción:", length(cod_prop), "\n")
  if (length(cod_prop) > 0) cat(paste(cod_prop, collapse = ", "))
})

# ============================================================================ #
# HANDLERS DE DESCARGA - FASE 5
# ============================================================================ #

# Descargar muestra enriquecida
output$descargar_muestra_enriquecida_btn <- downloadHandler(
  filename = function() {
    codigo_exp <- ifelse(
      !is.null(input$codigo_expediente) && input$codigo_expediente != "",
      paste0(input$codigo_expediente, "_"),
      ""
    )
    paste0(codigo_exp, "Muestra_Final_ENRIQUECIDA-", Sys.Date(), ".xlsx")
  },
  content = function(file) {
    req(muestra_enriquecida())
    openxlsx::write.xlsx(muestra_enriquecida(), file)
  }
)

output$descargar_grillas_contaminadas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Grillas_Contaminadas")
  },
  content = function(file) {
    req(muestra_enriquecida())
    datos <- muestra_enriquecida()
    umbral <- input$umbral_tph
    grillas_contam <- datos %>% filter(TPH > umbral)
    openxlsx::write.xlsx(grillas_contam, file)
  }
)

output$descargar_promedios_celdas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Promedios_Celdas_Completo")
  },
  content = function(file) {
    req(promedios_celdas_resultado())
    datos <- promedios_celdas_resultado()
    if ("criterio_contaminacion" %in% names(datos)) {
      datos <- datos %>% select(criterio_contaminacion, everything())
    }
    openxlsx::write.xlsx(datos, file)
  }
)

output$descargar_celdas_contaminadas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Celdas_Contaminadas")
  },
  content = function(file) {
    req(promedios_celdas_resultado())
    prom_celdas <- promedios_celdas_resultado()
    celdas_contam <- prom_celdas %>%
      filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
      select(criterio_contaminacion, everything())
    openxlsx::write.xlsx(celdas_contam, file)
  }
)

output$descargar_promedios_locaciones_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Promedios_Locaciones_Completo")
  },
  content = function(file) {
    req(promedios_locaciones_resultado())
    datos <- promedios_locaciones_resultado()
    if ("criterio_contaminacion" %in% names(datos)) {
      datos <- datos %>% select(criterio_contaminacion, everything())
    }
    openxlsx::write.xlsx(datos, file)
  }
)

output$descargar_locaciones_contaminadas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Locaciones_Contaminadas")
  },
  content = function(file) {
    req(promedios_locaciones_resultado())
    prom_loc <- promedios_locaciones_resultado()
    loc_contam <- prom_loc %>%
      filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
      select(criterio_contaminacion, everything())
    openxlsx::write.xlsx(loc_contam, file)
  }
)

output$descargar_vertices_grillas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_Grillas_Contaminadas")
  },
  content = function(file) {
    req(vertices_grillas_resultado())
    openxlsx::write.xlsx(vertices_grillas_resultado(), file)
  }
)

output$descargar_vertices_celdas_tph_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_Celdas_TPH")
  },
  content = function(file) {
    req(vertices_celdas_tph_resultado())
    openxlsx::write.xlsx(vertices_celdas_tph_resultado(), file)
  }
)

output$descargar_vertices_celdas_prop_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_Celdas_Proporcion")
  },
  content = function(file) {
    req(vertices_celdas_prop_resultado())
    openxlsx::write.xlsx(vertices_celdas_prop_resultado(), file)
  }
)

output$descargar_reporte_completo_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Reporte_Completo_Resultados")
  },
  content = function(file) {
    req(muestra_enriquecida())
    
    # Crear un workbook con múltiples hojas
    wb <- openxlsx::createWorkbook()
    
    # Hoja 1: Muestra enriquecida
    openxlsx::addWorksheet(wb, "Muestra_Enriquecida")
    openxlsx::writeData(wb, "Muestra_Enriquecida", muestra_enriquecida())
    
    # Hoja 2: Promedios por celdas
    if (!is.null(promedios_celdas_resultado())) {
      openxlsx::addWorksheet(wb, "Promedios_Celdas")
      openxlsx::writeData(wb, "Promedios_Celdas", promedios_celdas_resultado())
    }
    
    # Hoja 3: Promedios por locaciones
    if (!is.null(promedios_locaciones_resultado())) {
      openxlsx::addWorksheet(wb, "Promedios_Locaciones")
      openxlsx::writeData(wb, "Promedios_Locaciones", promedios_locaciones_resultado())
    }
    
    # Hoja 4: Todas las Grillas con criterio de contaminación
    umbral <- input$umbral_tph
    todas_grillas <- muestra_enriquecida() %>%
      mutate(criterio_contaminacion = ifelse(TPH > umbral, "Supera umbral TPH", "No contaminada")) %>%
      select(criterio_contaminacion, everything())
    
    openxlsx::addWorksheet(wb, "Todas_las_Grillas")
    openxlsx::writeData(wb, "Todas_las_Grillas", todas_grillas)
    
    # Guardar el workbook
    openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  }
)

# ============================================================================ #
# DESCARGAR SHAPEFILES CONTAMINADOS (GRILLAS Y CELDAS)
# ============================================================================ #
output$descargar_shapefiles_contaminados_btn <- downloadHandler(
  filename = function() {
    codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
      paste0(input$codigo_expediente, "_")
    } else {
      ""
    }
    paste0(codigo_exp, "Shapefiles_Contaminados-", Sys.Date(), ".zip")
  },
  content = function(file) {
    req(muestra_enriquecida())
    
    tryCatch({
      umbral <- input$umbral_tph
      datos <- muestra_enriquecida()
      
      # Código de expediente para nombres de archivo
      codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
        input$codigo_expediente
      } else {
        "SIN_CODIGO"
      }
      
      # Directorio temporal único
      temp_dir <- file.path(tempdir(), "shapefiles_export", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      
      archivos_creados <- c()
      
      # ==================== SHAPEFILE DE GRILLAS ====================
      if (!is.null(shp_grillas_data())) {
        shp_grillas_original <- shp_grillas_data()
        
        # Agregar columna CRITERIO_CONTAMINACION
        shp_grillas_contam <- shp_grillas_original %>%
          mutate(
            CRITERIO_CONTAMINACION = ifelse(
              COD_GRILLA %in% (datos %>% filter(TPH > umbral) %>% pull(GRILLA) %>% unique()),
              "Supera umbral TPH",
              "No contaminada"
            )
          )
        
        # Escribir shapefile
        nombre_grillas <- paste0(codigo_exp, "_grillas_contam.shp")
        ruta_grillas <- file.path(temp_dir, nombre_grillas)
        st_write(shp_grillas_contam, ruta_grillas, driver = "ESRI Shapefile", quiet = TRUE, delete_layer = TRUE)
        
        # Listar todos los archivos del shapefile
        archivos_grillas <- list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_grillas), "\\.*"), full.names = TRUE)
        archivos_creados <- c(archivos_creados, archivos_grillas)
      }
      
      # ==================== SHAPEFILE DE CELDAS ====================
      if (!is.null(shp_celdas_data()) && !is.null(promedios_celdas_resultado())) {
        shp_celdas_original <- shp_celdas_data()
        prom_celdas <- promedios_celdas_resultado()
        
        # Identificar columna de código de celda del shapefile
        col_celda_shp <- input$col_celda_shp
        
        # Crear lookup de criterio por celda
        celdas_contam_lookup <- prom_celdas %>%
          mutate(
            CRITERIO = case_when(
              contaminada_por_tph == "Sí" & contaminada_por_proporcion == "Sí" ~ "Ambos criterios",
              contaminada_por_tph == "Sí" ~ "Solo TPH promedio",
              contaminada_por_proporcion == "Sí" ~ "Solo proporción",
              TRUE ~ "No contaminada"
            )
          ) %>%
          select(CELDA, CRITERIO)
        
        # Agregar columna CRITERIO_CONTAMINACION al shapefile
        shp_celdas_contam <- shp_celdas_original %>%
          mutate(CELDA_KEY = .data[[col_celda_shp]]) %>%
          left_join(celdas_contam_lookup, by = c("CELDA_KEY" = "CELDA")) %>%
          mutate(
            CRITERIO_CONTAMINACION = ifelse(is.na(CRITERIO), "No contaminada", CRITERIO)
          ) %>%
          select(-CELDA_KEY, -CRITERIO)
        
        # Escribir shapefile
        nombre_celdas <- paste0(codigo_exp, "_celdas_contam.shp")
        ruta_celdas <- file.path(temp_dir, nombre_celdas)
        st_write(shp_celdas_contam, ruta_celdas, driver = "ESRI Shapefile", quiet = TRUE, delete_layer = TRUE)
        
        # Listar todos los archivos del shapefile
        archivos_celdas <- list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_celdas), "\\.*"), full.names = TRUE)
        archivos_creados <- c(archivos_creados, archivos_celdas)
      }
      
      # Verificar que se creó al menos un shapefile
      if (length(archivos_creados) == 0) {
        stop("No se pudieron generar shapefiles. Asegúrate de haber cargado los shapefiles de grillas y/o celdas.")
      }
      
      # Crear ZIP con todos los archivos
      if (requireNamespace("zip", quietly = TRUE)) {
        zip::zip(file, files = basename(archivos_creados), root = temp_dir, mode = "cherry-pick")
      } else {
        # Fallback a utils::zip si zip package no está disponible
        old_wd <- getwd()
        setwd(temp_dir)
        utils::zip(file, files = basename(archivos_creados))
        setwd(old_wd)
      }
      
      showNotification("Shapefiles contaminados generados exitosamente", type = "message")
      
    }, error = function(e) {
      registrar_error(e$message, "Descarga shapefiles contaminados")
      showNotification(paste("Error al generar shapefiles:", e$message), type = "error", duration = 10)
    })
  }
)
