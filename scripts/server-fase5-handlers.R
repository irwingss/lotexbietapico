# ============================================================================ #
# HANDLERS Y OUTPUTS ADICIONALES PARA FASE 5 - ANÁLISIS DE RESULTADOS
# ============================================================================ #
# Este archivo contiene outputs y handlers de descarga para la Fase 5
# Para ser incluido en el servidor principal de la app
# ============================================================================ #

# ============================================================================ #
# NOTA: Los outputs de DIAGNÓSTICO DE MATCH (resumen, tabla de puntos perdidos,
# listas y descarga) se encuentran en app_01_muestreo_bietapico.R ya que manejan
# AMBOS casos (Caso 1: matching espacial y Caso 2: matching por códigos).
# No duplicar aquí para evitar sobrescrituras.
# ============================================================================ #
# PUNTOS HUÉRFANOS - Outputs para la tercera pestaña del análisis de grillas
# ============================================================================ #

output$resumen_puntos_huerfanos <- renderPrint({
  diag <- diagnostico_enriquecimiento()
  
  if (is.null(diag)) {
    cat("ℹ️  No hay diagnóstico disponible aún.\n\n")
    cat("El diagnóstico se genera automáticamente después de\n")
    cat("cargar y unificar los datos en la Fase 5.\n")
    return()
  }
  
  cat("═══════════════════════════════════════════\n")
  cat("  RESUMEN DE PUNTOS HUÉRFANOS\n")
  cat("═══════════════════════════════════════════\n\n")
  
  # Validación robusta: verificar si existe n_puntos_perdidos y si es mayor a 0
  n_perdidos <- if (!is.null(diag$n_puntos_perdidos)) diag$n_puntos_perdidos else 0
  
  if (n_perdidos == 0) {
    cat("✅ ¡EXCELENTE!\n")
    cat("No hay puntos huérfanos.\n")
    cat("Todos los puntos de la muestra final tienen resultados de laboratorio.\n\n")
  } else {
    cat("⚠️  ATENCIÓN\n")
    cat("───────────────────────────────────────────\n")
    cat("Se detectaron", n_perdidos, "puntos huérfanos\n\n")
    
    cat("📊 ESTADÍSTICAS\n")
    cat("───────────────────────────────────────────\n")
    cat("Puntos en Muestra Final (Fase 4):", diag$n_puntos_muestra_original, "\n")
    cat("Puntos con resultados de lab:", diag$n_puntos_en_ambos, "\n")
    cat("👻 Puntos huérfanos (sin TPH):", n_perdidos, "\n")
    cat("Porcentaje huérfanos:", round((n_perdidos / diag$n_puntos_muestra_original) * 100, 1), "%\n\n")
    
    cat("❌ IMPACTO\n")
    cat("───────────────────────────────────────────\n")
    cat("Estos puntos NO aparecen en:\n")
    cat("  • Tabla 'Grillas Contaminadas'\n")
    cat("  • Tabla 'Todas las Grillas'\n")
    cat("  • Análisis por Celdas\n")
    cat("  • Análisis por Locaciones\n")
    cat("  • Shapefiles exportados\n\n")
    
    cat("📥 RECOMENDACIÓN\n")
    cat("───────────────────────────────────────────\n")
    cat("1. Descarga el Excel con los códigos exactos\n")
    cat("2. Revisa si hay diferencias de formato\n")
    cat("3. Verifica si faltan resultados de laboratorio\n")
    cat("4. Corrige y vuelve a cargar los datos\n")
  }
  
  cat("═══════════════════════════════════════════\n")
})

output$tabla_puntos_huerfanos <- renderDT({
  diag <- diagnostico_enriquecimiento()
  
  # Si no hay diagnóstico, mostrar mensaje amigable
  if (is.null(diag)) {
    return(datatable(
      data.frame(Mensaje = "ℹ️ No hay diagnóstico disponible aún. Cargue y unifique los datos en la Fase 5."),
      options = list(pageLength = 5, dom = 't', ordering = FALSE, searching = FALSE),
      rownames = FALSE
    ))
  }
  
  # Validación robusta: verificar si existe el dataframe y si tiene filas
  if (is.null(diag$puntos_sin_tph) || 
      !is.data.frame(diag$puntos_sin_tph) || nrow(diag$puntos_sin_tph) == 0) {
    return(datatable(
      data.frame(Mensaje = "✅ Excelente! No hay puntos huérfanos. Todos los puntos tienen resultados de laboratorio."),
      options = list(pageLength = 5, dom = 't', ordering = FALSE, searching = FALSE),
      rownames = FALSE
    ))
  }
  
  puntos_huerfanos <- diag$puntos_sin_tph
  
  # Añadir columna de índice
  puntos_huerfanos <- puntos_huerfanos %>%
    mutate(No = row_number()) %>%
    select(No, everything())
  
  datatable(
    puntos_huerfanos,
    caption = HTML("<strong>⚠️ PUNTOS HUÉRFANOS:</strong> Estos puntos NO tienen resultados de laboratorio y NO aparecen en el análisis"),
    options = list(
      pageLength = 25,
      scrollX = TRUE,
      autoWidth = TRUE,
      dom = 'Bfrtip',
      buttons = list(
        'copy',
        list(extend = 'csv', filename = 'puntos_huerfanos'),
        list(extend = 'excel', filename = 'puntos_huerfanos')
      ),
      columnDefs = list(
        list(width = '40px', targets = 0),  # Columna No
        list(width = '150px', targets = 1)  # Columna PUNTO
      )
    ),
    rownames = FALSE,
    extensions = 'Buttons',
    class = 'cell-border stripe'
  ) %>%
  formatStyle(
    'No',
    backgroundColor = '#fff3cd',
    fontWeight = 'bold'
  ) %>%
  formatStyle(
    'PUNTO',
    backgroundColor = '#fff3cd',
    fontWeight = 'bold',
    color = '#856404'
  ) %>%
  formatStyle(
    'RAZON',
    backgroundColor = '#f8d7da',
    color = '#721c24',
    fontWeight = 'bold'
  )
})

# Descargar puntos huérfanos en Excel
output$descargar_puntos_huerfanos_excel_btn <- downloadHandler(
  filename = function() {
    codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
      paste0(input$codigo_expediente, "_")
    } else {
      ""
    }
    paste0(codigo_exp, "Puntos_Huerfanos-", Sys.Date(), ".xlsx")
  },
  content = function(file) {
    diag <- diagnostico_enriquecimiento()
    
    # Si no hay diagnóstico
    if (is.null(diag)) {
      df_mensaje <- data.frame(
        RESULTADO = "ℹ️ No hay diagnóstico disponible",
        DETALLE = "Cargue y unifique los datos en la Fase 5 para generar el diagnóstico"
      )
      openxlsx::write.xlsx(df_mensaje, file)
      return()
    }
    
    # Validación robusta
    if (is.null(diag$puntos_sin_tph) || !is.data.frame(diag$puntos_sin_tph) || nrow(diag$puntos_sin_tph) == 0) {
      # Crear mensaje si no hay puntos huérfanos
      df_mensaje <- data.frame(
        RESULTADO = "✅ No hay puntos huérfanos",
        DETALLE = "Todos los puntos de la muestra final tienen resultados de laboratorio"
      )
      openxlsx::write.xlsx(df_mensaje, file)
    } else {
      puntos_huerfanos <- diag$puntos_sin_tph %>%
        mutate(No = row_number()) %>%
        select(No, everything())
      
      openxlsx::write.xlsx(puntos_huerfanos, file)
    }
  }
)

# Descargar reporte de puntos huérfanos en TXT
output$descargar_puntos_huerfanos_txt_btn <- downloadHandler(
  filename = function() {
    codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
      paste0(input$codigo_expediente, "_")
    } else {
      ""
    }
    paste0(codigo_exp, "Reporte_Puntos_Huerfanos-", Sys.Date(), ".txt")
  },
  content = function(file) {
    diag <- diagnostico_enriquecimiento()
    
    # Si no hay diagnóstico
    if (is.null(diag)) {
      lineas <- c(
        "═══════════════════════════════════════════════════════════════",
        "  REPORTE DE PUNTOS HUÉRFANOS",
        paste("  Generado:", Sys.time()),
        "═══════════════════════════════════════════════════════════════",
        "",
        "ℹ️ NO HAY DIAGNÓSTICO DISPONIBLE",
        "───────────────────────────────────────────────────────────────",
        "Cargue y unifique los datos en la Fase 5 para generar el diagnóstico."
      )
      writeLines(lineas, file)
      return()
    }
    
    # Validación robusta
    n_perdidos <- if (!is.null(diag$n_puntos_perdidos)) diag$n_puntos_perdidos else 0
    
    lineas <- c(
      "═══════════════════════════════════════════════════════════════",
      "  REPORTE DE PUNTOS HUÉRFANOS",
      paste("  Generado:", Sys.time()),
      "═══════════════════════════════════════════════════════════════",
      "",
      "DEFINICIÓN",
      "───────────────────────────────────────────────────────────────",
      "Puntos huérfanos son aquellos que están en la Muestra Final (Fase 4)",
      "pero NO tienen resultados de laboratorio (sin valores de TPH).",
      "Estos puntos NO aparecen en el análisis de grillas, celdas ni locaciones.",
      "",
      "RESUMEN ESTADÍSTICO",
      "───────────────────────────────────────────────────────────────",
      paste("Puntos en Muestra Final (Fase 4):", diag$n_puntos_muestra_original),
      paste("Puntos con resultados de lab:", diag$n_puntos_en_ambos),
      paste("Puntos huérfanos (sin TPH):", n_perdidos),
      paste("Porcentaje huérfanos:", round((n_perdidos / diag$n_puntos_muestra_original) * 100, 1), "%"),
      ""
    )
    
    if (n_perdidos == 0) {
      lineas <- c(lineas,
        "✅ RESULTADO: SIN PUNTOS HUÉRFANOS",
        "───────────────────────────────────────────────────────────────",
        "Todos los puntos de la muestra final tienen resultados de laboratorio.",
        "El análisis está completo."
      )
    } else {
      lineas <- c(lineas,
        "⚠️  PUNTOS HUÉRFANOS DETECTADOS",
        "───────────────────────────────────────────────────────────────",
        paste("Total de puntos huérfanos:", nrow(diag$puntos_sin_tph)),
        "",
        "LISTADO DETALLADO",
        "───────────────────────────────────────────────────────────────"
      )
      
      for (i in seq_len(nrow(diag$puntos_sin_tph))) {
        punto_info <- diag$puntos_sin_tph[i, ]
        lineas <- c(lineas,
          paste("\n", i, ". PUNTO:", punto_info$PUNTO),
          paste("   LOCACION:", ifelse(is.na(punto_info$LOCACION), "N/A", punto_info$LOCACION))
        )
        
        if ("GRILLA" %in% names(punto_info) && !is.na(punto_info$GRILLA)) {
          lineas <- c(lineas, paste("   GRILLA:", punto_info$GRILLA))
        }
        
        if ("CELDA" %in% names(punto_info) && !is.na(punto_info$CELDA)) {
          lineas <- c(lineas, paste("   CELDA:", punto_info$CELDA))
        }
        
        lineas <- c(lineas, paste("   RAZÓN:", punto_info$RAZON))
      }
      
      lineas <- c(lineas, "",
        "",
        "POSIBLES CAUSAS",
        "───────────────────────────────────────────────────────────────",
        "1. Diferencias en formato de códigos (espacios, caracteres especiales)",
        "2. Muestras no enviadas o no analizadas en laboratorio",
        "3. Errores de transcripción en códigos de punto",
        "4. Muestras aún en proceso de análisis",
        "",
        "RECOMENDACIÓN",
        "───────────────────────────────────────────────────────────────",
        "1. Revisa los códigos de punto en ambos archivos",
        "2. Verifica que no haya espacios extra o caracteres especiales",
        "3. Confirma si faltan resultados de laboratorio",
        "4. Corrige los archivos fuente y vuelve a cargar"
      )
    }
    
    writeLines(lineas, file)
  }
)

# ============================================================================ #
# ANÁLISIS - Outputs originales
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
  
  # Encontrar índices de columnas TPH y prop_exceed (base 0 para JavaScript)
  col_indices <- c()
  if ("TPH" %in% names(celdas_contam)) {
    col_indices <- c(col_indices, which(names(celdas_contam) == "TPH") - 1)
  }
  if ("prop_exceed" %in% names(celdas_contam)) {
    col_indices <- c(col_indices, which(names(celdas_contam) == "prop_exceed") - 1)
  }
  
  # Crear callback JavaScript para colorear encabezados
  header_callback <- paste0(
    "function(thead, data, start, end, display) {",
    "  var colIndices = [", paste(col_indices, collapse = ","), "];",
    "  colIndices.forEach(function(idx) {",
    "    $(thead).find('th').eq(idx).css({",
    "      'background-color': '#00BCD4',",
    "      'color': 'white',",
    "      'font-weight': 'bold'",
    "    });",
    "  });",
    "}"
  )
  
  datatable(
    celdas_contam,
    options = list(
      pageLength = 10, 
      scrollX = TRUE, 
      autoWidth = TRUE,
      headerCallback = JS(header_callback)
    ),
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
  
  # Encontrar índices de columnas TPH y prop_exceed (base 0 para JavaScript)
  col_indices <- c()
  if ("TPH" %in% names(loc_contam)) {
    col_indices <- c(col_indices, which(names(loc_contam) == "TPH") - 1)
  }
  if ("prop_exceed" %in% names(loc_contam)) {
    col_indices <- c(col_indices, which(names(loc_contam) == "prop_exceed") - 1)
  }
  
  # Crear callback JavaScript para colorear encabezados
  header_callback <- paste0(
    "function(thead, data, start, end, display) {",
    "  var colIndices = [", paste(col_indices, collapse = ","), "];",
    "  colIndices.forEach(function(idx) {",
    "    $(thead).find('th').eq(idx).css({",
    "      'background-color': '#00BCD4',",
    "      'color': 'white',",
    "      'font-weight': 'bold'",
    "    });",
    "  });",
    "}"
  )
  
  datatable(
    loc_contam,
    options = list(
      pageLength = 10, 
      scrollX = TRUE, 
      autoWidth = TRUE,
      headerCallback = JS(header_callback)
    ),
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
            vert_grillas <- generar_vertices_grillas(shp_grillas_filtrado, datos_prep, superan_grilla, 
                                                     punto_col = "punto", umbral = umbral)
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
    
    # ========================================================================== #
    # ANÁLISIS UNIFICADO CON EXCLUSIÓN JERÁRQUICA
    # ========================================================================== #
    
    # Paso 1: Identificar locaciones contaminadas (ambos criterios)
    locaciones_contaminadas <- character(0)
    if (!is.null(promedios_locaciones_resultado())) {
      prom_loc <- promedios_locaciones_resultado()
      locaciones_contaminadas <- prom_loc %>%
        filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
        pull(LOCACION) %>%
        unique()
    }
    
    # Paso 2: Identificar celdas contaminadas (ambos criterios)
    celdas_contaminadas <- character(0)
    if (!is.null(promedios_celdas_resultado())) {
      prom_celd <- promedios_celdas_resultado()
      celdas_contaminadas <- prom_celd %>%
        filter(contaminada_por_tph == "Sí" | contaminada_por_proporcion == "Sí") %>%
        pull(CELDA) %>%
        unique()
    }
    
    # Paso 3: Filtrar GRILLAS para análisis unificado
    # Excluir grillas que pertenecen a locaciones o celdas contaminadas
    if (!is.null(vertices_grillas_resultado())) {
      vert_grillas_orig <- vertices_grillas_resultado()
      
      # Identificar grillas a excluir
      vert_grillas_filtrado <- vert_grillas_orig %>%
        filter(
          # NO pertenece a locación contaminada
          !(LOCACION %in% locaciones_contaminadas)
        )
      
      # Si tenemos información de celdas, también excluir grillas de celdas contaminadas
      if ("CELDA" %in% names(datos) && length(celdas_contaminadas) > 0) {
        # Obtener mapeo GRILLA -> CELDA de los datos originales
        grillas_en_celdas_contam <- datos %>%
          filter(!is.na(CELDA), CELDA %in% celdas_contaminadas) %>%
          pull(GRILLA) %>%
          unique()
        
        # Excluir esas grillas
        vert_grillas_filtrado <- vert_grillas_filtrado %>%
          filter(!(COD_GRILLA %in% grillas_en_celdas_contam))
      }
      
      vertices_grillas_unificado(vert_grillas_filtrado)
      
      cat("DEBUG Exclusión Grillas:\n")
      cat("- Grillas originales:", nrow(vert_grillas_orig), "\n")
      cat("- Grillas unificadas:", nrow(vert_grillas_filtrado), "\n")
      cat("- Excluidas:", nrow(vert_grillas_orig) - nrow(vert_grillas_filtrado), "\n")
    }
    
    # Paso 4: Filtrar CELDAS para análisis unificado
    # Combinar vértices de celdas TPH y Proporción
    # Excluir celdas que pertenecen a locaciones contaminadas
    vertices_celdas_combinados <- NULL
    
    if (!is.null(vertices_celdas_tph_resultado()) && !is.null(vertices_celdas_prop_resultado())) {
      # Combinar ambos
      vertices_celdas_combinados <- bind_rows(
        vertices_celdas_tph_resultado(),
        vertices_celdas_prop_resultado()
      ) %>%
        distinct()
    } else if (!is.null(vertices_celdas_tph_resultado())) {
      vertices_celdas_combinados <- vertices_celdas_tph_resultado()
    } else if (!is.null(vertices_celdas_prop_resultado())) {
      vertices_celdas_combinados <- vertices_celdas_prop_resultado()
    }
    
    if (!is.null(vertices_celdas_combinados)) {
      # Excluir celdas de locaciones contaminadas
      vert_celdas_filtrado <- vertices_celdas_combinados %>%
        filter(!(LOCACION %in% locaciones_contaminadas))
      
      vertices_celdas_unificado(vert_celdas_filtrado)
      
      cat("DEBUG Exclusión Celdas:\n")
      cat("- Celdas originales:", nrow(vertices_celdas_combinados), "\n")
      cat("- Celdas unificadas:", nrow(vert_celdas_filtrado), "\n")
      cat("- Excluidas:", nrow(vertices_celdas_combinados) - nrow(vert_celdas_filtrado), "\n")
    }
    
    showNotification("Vértices generados exitosamente (incluye análisis unificado)", type = "message", duration = 5)
    
    # Cambiar a la pestaña de Vértices de Polígonos
    updateTabsetPanel(session, "tabset_fase5", selected = "Vértices de Polígonos")
    
    # Cambiar automáticamente a la sub-pestaña de Análisis unificado
    updateTabsetPanel(session, "tabset_vertices", selected = "🎯 Análisis unificado excluyendo sobreposición")
    
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
  
  datos <- head(vertices_grillas_resultado(), 100)
  
  datatable(
    datos,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Supera umbral TPH", "No contaminada"),
      c("#dc3545", "#28a745")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

output$tabla_vertices_celdas <- renderDT({
  req(vertices_celdas_tph_resultado())
  
  datos <- head(vertices_celdas_tph_resultado(), 100)
  
  datatable(
    datos,
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
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

# ============================================================================ #
# RESUMEN EJECUTIVO DE ANÁLISIS UNIFICADO
# ============================================================================ #

# Resumen de conteos de elementos contaminados
output$resumen_unificado_conteos <- renderUI({
  # Verificar que hay datos
  tiene_grillas <- !is.null(vertices_grillas_unificado())
  tiene_celdas <- !is.null(vertices_celdas_unificado())
  tiene_locaciones <- !is.null(promedios_locaciones_resultado())
  
  if (!tiene_grillas && !tiene_celdas && !tiene_locaciones) {
    return(p("⚠️ No hay datos de análisis unificado disponibles. Genere primero los vértices.", 
             style = "color: #856404; font-weight: bold;"))
  }
  
  # Contar elementos únicos
  n_grillas <- if (tiene_grillas) length(unique(vertices_grillas_unificado()$COD_GRILLA)) else 0
  n_celdas <- if (tiene_celdas) length(unique(vertices_celdas_unificado()$COD_UNIC)) else 0
  
  # Contar locaciones contaminadas
  n_locaciones <- 0
  if (tiene_locaciones) {
    loc_data <- promedios_locaciones_resultado()
    if ("criterio_contaminacion" %in% names(loc_data)) {
      n_locaciones <- loc_data %>% 
        filter(criterio_contaminacion != "No contaminada") %>% 
        nrow()
    }
  }
  
  # Crear tabla de resumen
  div(
    tags$table(class = "table table-bordered table-striped", style = "margin-bottom: 0;",
      tags$thead(
        tags$tr(
          tags$th("Nivel", style = "background-color: #5cb85c; color: white; text-align: center;"),
          tags$th("Cantidad", style = "background-color: #5cb85c; color: white; text-align: center;"),
          tags$th("Descripción", style = "background-color: #5cb85c; color: white; text-align: center;")
        )
      ),
      tags$tbody(
        tags$tr(
          tags$td("📍 Grillas", style = "font-weight: bold;"),
          tags$td(n_grillas, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #d9534f;"),
          tags$td("Grillas individuales que requieren remediación (no pertenecen a celdas/locaciones contaminadas)")
        ),
        tags$tr(
          tags$td("🔲 Celdas", style = "font-weight: bold;"),
          tags$td(n_celdas, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #f0ad4e;"),
          tags$td("Celdas completas que requieren remediación (no pertenecen a locaciones contaminadas)")
        ),
        tags$tr(
          tags$td("🏢 Locaciones", style = "font-weight: bold;"),
          tags$td(n_locaciones, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #5bc0de;"),
          tags$td("Locaciones completas que requieren remediación total")
        ),
        tags$tr(style = "background-color: #f9f9f9; font-weight: bold;",
          tags$td("TOTAL ELEMENTOS", style = "text-align: right;"),
          tags$td(n_grillas + n_celdas + n_locaciones, 
                  style = "text-align: center; font-size: 1.3em; color: #333;"),
          tags$td("Áreas discretas sujetas a remediación")
        )
      )
    )
  )
})

# Lista de códigos de grillas contaminadas
output$lista_grillas_unificado <- renderUI({
  req(vertices_grillas_unificado())
  
  grillas <- unique(vertices_grillas_unificado()$COD_GRILLA)
  
  if (length(grillas) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  # Ordenar alfabéticamente
  grillas <- sort(grillas)
  
  div(
    p(strong(paste("Total:", length(grillas), "grillas")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(grillas, collapse = ", ")
    )
  )
})

# Lista de códigos de celdas contaminadas
output$lista_celdas_unificado <- renderUI({
  req(vertices_celdas_unificado())
  
  celdas <- unique(vertices_celdas_unificado()$COD_UNIC)
  
  if (length(celdas) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  # Ordenar alfabéticamente
  celdas <- sort(celdas)
  
  div(
    p(strong(paste("Total:", length(celdas), "celdas")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(celdas, collapse = ", ")
    )
  )
})

# Lista de códigos de locaciones contaminadas
output$lista_locaciones_contaminadas <- renderUI({
  req(promedios_locaciones_resultado())
  
  loc_data <- promedios_locaciones_resultado()
  
  if (!"criterio_contaminacion" %in% names(loc_data)) {
    return(p("No disponible", style = "color: #999; font-style: italic;"))
  }
  
  locaciones <- loc_data %>% 
    filter(criterio_contaminacion != "No contaminada") %>% 
    pull(LOCACION)
  
  if (length(locaciones) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  # Ordenar alfabéticamente
  locaciones <- sort(locaciones)
  
  div(
    p(strong(paste("Total:", length(locaciones), "locaciones")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(locaciones, collapse = ", ")
    )
  )
})

# Outputs de vértices unificados
output$tabla_vertices_grillas_unificado <- renderDT({
  req(vertices_grillas_unificado())
  
  datos <- vertices_grillas_unificado()
  
  if (nrow(datos) == 0) {
    return(datatable(
      data.frame(Mensaje = "ℹ️ No hay grillas individuales después de aplicar exclusión jerárquica. Todas las grillas pertenecen a celdas o locaciones que se remediarán completas."),
      options = list(dom = 't', ordering = FALSE, searching = FALSE),
      rownames = FALSE
    ))
  }
  
  datatable(
    head(datos, 100),
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
  formatStyle(
    "criterio_contaminacion",
    backgroundColor = styleEqual(
      c("Supera umbral TPH", "No contaminada"),
      c("#dc3545", "#28a745")
    ),
    color = "white",
    fontWeight = "bold"
  )
})

output$tabla_vertices_celdas_unificado <- renderDT({
  req(vertices_celdas_unificado())
  
  datos <- vertices_celdas_unificado()
  
  if (nrow(datos) == 0) {
    return(datatable(
      data.frame(Mensaje = "ℹ️ No hay celdas individuales después de aplicar exclusión jerárquica. Todas las celdas pertenecen a locaciones que se remediarán completas."),
      options = list(dom = 't', ordering = FALSE, searching = FALSE),
      rownames = FALSE
    ))
  }
  
  datatable(
    head(datos, 100),
    options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE),
    rownames = FALSE
  ) %>%
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

# Handlers de descarga para análisis unificado
output$descargar_vertices_grillas_unificado_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_Grillas_UNIFICADO")
  },
  content = function(file) {
    req(vertices_grillas_unificado())
    datos <- vertices_grillas_unificado()
    
    if (nrow(datos) == 0) {
      # Crear mensaje si no hay datos
      df_mensaje <- data.frame(
        MENSAJE = "No hay grillas individuales después de aplicar exclusión jerárquica",
        DETALLE = "Todas las grillas pertenecen a celdas o locaciones que se remediarán completas"
      )
      openxlsx::write.xlsx(df_mensaje, file)
    } else {
      openxlsx::write.xlsx(datos, file)
    }
  }
)

output$descargar_vertices_celdas_unificado_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_Celdas_UNIFICADO")
  },
  content = function(file) {
    req(vertices_celdas_unificado())
    datos <- vertices_celdas_unificado()
    
    if (nrow(datos) == 0) {
      # Crear mensaje si no hay datos
      df_mensaje <- data.frame(
        MENSAJE = "No hay celdas individuales después de aplicar exclusión jerárquica",
        DETALLE = "Todas las celdas pertenecen a locaciones que se remediarán completas"
      )
      openxlsx::write.xlsx(df_mensaje, file)
    } else {
      openxlsx::write.xlsx(datos, file)
    }
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

# Descargar reporte SOLO contaminadas (filtrado)
output$descargar_reporte_solo_contaminadas_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Reporte_SOLO_CONTAMINADAS")
  },
  content = function(file) {
    req(muestra_enriquecida())
    
    # Crear un workbook con múltiples hojas
    wb <- openxlsx::createWorkbook()
    umbral <- input$umbral_tph
    
    # ========== Hoja 1: GRILLAS CONTAMINADAS ==========
    grillas_contaminadas <- muestra_enriquecida() %>%
      mutate(criterio_contaminacion = ifelse(TPH > umbral, "Supera umbral TPH", "No contaminada")) %>%
      filter(criterio_contaminacion != "No contaminada") %>%
      select(criterio_contaminacion, everything())
    
    if (nrow(grillas_contaminadas) > 0) {
      openxlsx::addWorksheet(wb, "Grillas_Contaminadas")
      openxlsx::writeData(wb, "Grillas_Contaminadas", grillas_contaminadas)
    }
    
    # ========== Hoja 2: CELDAS CONTAMINADAS ==========
    if (!is.null(promedios_celdas_resultado())) {
      celdas_contaminadas <- promedios_celdas_resultado() %>%
        filter(criterio_contaminacion != "No contaminada") %>%
        select(criterio_contaminacion, everything())
      
      if (nrow(celdas_contaminadas) > 0) {
        openxlsx::addWorksheet(wb, "Celdas_Contaminadas")
        openxlsx::writeData(wb, "Celdas_Contaminadas", celdas_contaminadas)
      }
    }
    
    # ========== Hoja 3: LOCACIONES CONTAMINADAS ==========
    if (!is.null(promedios_locaciones_resultado())) {
      locaciones_contaminadas <- promedios_locaciones_resultado() %>%
        filter(criterio_contaminacion != "No contaminada") %>%
        select(criterio_contaminacion, everything())
      
      if (nrow(locaciones_contaminadas) > 0) {
        openxlsx::addWorksheet(wb, "Locaciones_Contaminadas")
        openxlsx::writeData(wb, "Locaciones_Contaminadas", locaciones_contaminadas)
      }
    }
    
    # ========== Hoja 4: RESUMEN EJECUTIVO ==========
    resumen_data <- data.frame(
      Nivel = c("Grillas", "Celdas", "Locaciones"),
      Total_Contaminadas = c(
        if (exists("grillas_contaminadas")) nrow(grillas_contaminadas) else 0,
        if (!is.null(promedios_celdas_resultado())) {
          sum(promedios_celdas_resultado()$criterio_contaminacion != "No contaminada")
        } else 0,
        if (!is.null(promedios_locaciones_resultado())) {
          sum(promedios_locaciones_resultado()$criterio_contaminacion != "No contaminada")
        } else 0
      ),
      Umbral_TPH = rep(umbral, 3),
      Fecha_Analisis = rep(as.character(Sys.Date()), 3)
    )
    
    openxlsx::addWorksheet(wb, "RESUMEN", gridLines = TRUE)
    openxlsx::writeData(wb, "RESUMEN", resumen_data)
    
    # Aplicar formato al resumen
    header_style <- openxlsx::createStyle(
      fontSize = 12, 
      fontColour = "#FFFFFF", 
      halign = "center",
      fgFill = "#4F81BD", 
      border = "TopBottomLeftRight", 
      borderColour = "#4F81BD",
      textDecoration = "bold"
    )
    
    openxlsx::addStyle(wb, sheet = "RESUMEN", header_style, rows = 1, cols = 1:4, gridExpand = TRUE)
    
    # Guardar el workbook
    openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  }
)

# ============================================================================ #
# DESCARGAR SHAPEFILES CONTAMINADOS CON LÓGICA JERÁRQUICA
# ============================================================================ #
output$descargar_shapefiles_contaminados_btn <- downloadHandler(
  filename = function() {
    codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
      paste0(input$codigo_expediente, "_")
    } else {
      ""
    }
    paste0(codigo_exp, "Shapefiles_Contaminados_UNIFICADO-", Sys.Date(), ".zip")
  },
  content = function(file) {
    # Requiere que se hayan generado los vértices unificados
    if (is.null(vertices_grillas_unificado()) && is.null(vertices_celdas_unificado())) {
      showNotification("Debe generar los vértices primero (botón 'Generar Vértices')", type = "error", duration = 10)
      return()
    }
    
    tryCatch({
      # Código de expediente para nombres de archivo
      codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
        input$codigo_expediente
      } else {
        "SIN_CODIGO"
      }
      
      # Directorio temporal único
      temp_dir <- file.path(tempdir(), "shapefiles_export", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      
      # Directorio para ZIPs individuales
      zips_dir <- file.path(temp_dir, "zips")
      dir.create(zips_dir, recursive = TRUE, showWarnings = FALSE)
      
      archivos_zip_individuales <- c()
      
      # ==================== SHAPEFILE DE GRILLAS (UNIFICADO) ====================
      if (!is.null(shp_grillas_data()) && !is.null(vertices_grillas_unificado())) {
        vert_grillas_unif <- vertices_grillas_unificado()
        
        if (nrow(vert_grillas_unif) > 0) {
          shp_grillas_original <- shp_grillas_data()
          
          # Obtener grillas únicas del análisis unificado
          grillas_unificado <- vert_grillas_unif %>% 
            pull(COD_GRILLA) %>% 
            unique()
          
          # Filtrar shapefile solo por grillas en análisis unificado
          shp_grillas_unif <- shp_grillas_original %>%
            filter(COD_GRILLA %in% grillas_unificado) %>%
            mutate(
              CRITERIO = "Supera umbral TPH",  # Max 10 chars para shapefile
              TIPO_ANALISIS = "Unificado"       # Max 10 chars
            )
          
          # Validar y escribir shapefile
          nombre_grillas <- paste0(codigo_exp, "_grillas_UNIFICADO.shp")
          ruta_grillas <- file.path(temp_dir, nombre_grillas)
          
          # Eliminar shapefile previo si existe
          if (file.exists(ruta_grillas)) {
            tryCatch({
              st_layers(ruta_grillas)
              unlink(list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_grillas), "\\.*"), full.names = TRUE))
            }, error = function(e) {})
          }
          
          # Validar geometría antes de escribir
          if (!all(st_is_valid(shp_grillas_unif))) {
            shp_grillas_unif <- st_make_valid(shp_grillas_unif)
          }
          
          # Convertir geometrías 3D a 2D (shapefile no soporta 3D Polygon)
          shp_grillas_unif <- st_zm(shp_grillas_unif, drop = TRUE, what = "ZM")
          
          st_write(shp_grillas_unif, ruta_grillas, driver = "ESRI Shapefile", quiet = TRUE, append = FALSE)
          
          # Listar todos los archivos del shapefile de grillas
          archivos_grillas <- list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_grillas), "\\.*"), full.names = TRUE)
          
          # Crear ZIP individual para shapefile de grillas
          nombre_zip_grillas <- paste0(codigo_exp, "_grillas_UNIFICADO.zip")
          ruta_zip_grillas <- file.path(zips_dir, nombre_zip_grillas)
          
          if (requireNamespace("zip", quietly = TRUE)) {
            zip::zip(ruta_zip_grillas, files = basename(archivos_grillas), root = temp_dir, mode = "cherry-pick")
          } else {
            old_wd <- getwd()
            setwd(temp_dir)
            utils::zip(ruta_zip_grillas, files = basename(archivos_grillas))
            setwd(old_wd)
          }
          
          archivos_zip_individuales <- c(archivos_zip_individuales, ruta_zip_grillas)
        }
      }
      
      # ==================== SHAPEFILE DE CELDAS (UNIFICADO) ====================
      if (!is.null(shp_celdas_data()) && !is.null(vertices_celdas_unificado())) {
        vert_celdas_unif <- vertices_celdas_unificado()
        
        if (nrow(vert_celdas_unif) > 0) {
          shp_celdas_original <- shp_celdas_data()
          col_celda_shp <- input$col_celda_shp
          
          # Obtener celdas únicas del análisis unificado con su criterio
          # NOTA CRÍTICA: COD_UNIC en vértices contiene el valor de CELDA de muestra_enriquecida
          # Necesitamos hacer match con la columna del shapefile que puede tener diferente nombre
          celdas_unificado_lookup <- vert_celdas_unif %>%
            select(COD_UNIC, criterio_contaminacion) %>%
            distinct() %>%
            mutate(
              # Normalizar para match (trimws + as.character)
              CELDA_VALUE = trimws(as.character(COD_UNIC)),
              CRITERIO = criterio_contaminacion
            ) %>%
            select(CELDA_VALUE, CRITERIO)
          
          # DEBUG: Mostrar valores únicos para verificar match
          cat("\nDEBUG Exportación Shapefiles Celdas:\n")
          cat("- Celdas únicas en vértices unificados:", length(unique(vert_celdas_unif$COD_UNIC)), "\n")
          cat("- Valores de celda en vértices:", paste(head(unique(vert_celdas_unif$COD_UNIC), 5), collapse = ", "), "...\n")
          cat("- Columna usada del shapefile:", col_celda_shp, "\n")
          cat("- Valores en shapefile:", paste(head(unique(shp_celdas_original[[col_celda_shp]]), 5), collapse = ", "), "...\n")
          
          # Filtrar shapefile solo por celdas en análisis unificado
          # Normalizar la columna del shapefile para match
          shp_celdas_unif <- shp_celdas_original %>%
            mutate(CELDA_VALUE_SHP = trimws(as.character(.data[[col_celda_shp]]))) %>%
            inner_join(celdas_unificado_lookup, by = c("CELDA_VALUE_SHP" = "CELDA_VALUE")) %>%
            mutate(
              CRITERIO = case_when(
                CRITERIO == "Ambos criterios" ~ "Ambos",
                CRITERIO == "Solo TPH promedio" ~ "Solo TPH",
                CRITERIO == "Solo proporción" ~ "Solo Prop",
                TRUE ~ CRITERIO
              ),  # Truncar a max 10 chars
              TIPO_ANALISIS = "Unificado"  # Max 10 chars
            ) %>%
            select(-CELDA_VALUE_SHP)
          
          cat("- Celdas en shapefile después del filtrado:", nrow(shp_celdas_unif), "\n")
          
          # Validar y escribir shapefile
          nombre_celdas <- paste0(codigo_exp, "_celdas_UNIFICADO.shp")
          ruta_celdas <- file.path(temp_dir, nombre_celdas)
          
          # Eliminar shapefile previo si existe
          if (file.exists(ruta_celdas)) {
            tryCatch({
              st_layers(ruta_celdas)
              unlink(list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_celdas), "\\.*"), full.names = TRUE))
            }, error = function(e) {})
          }
          
          # Validar geometría antes de escribir
          if (!all(st_is_valid(shp_celdas_unif))) {
            shp_celdas_unif <- st_make_valid(shp_celdas_unif)
          }
          
          # Convertir geometrías 3D a 2D (shapefile no soporta 3D Polygon)
          shp_celdas_unif <- st_zm(shp_celdas_unif, drop = TRUE, what = "ZM")
          
          st_write(shp_celdas_unif, ruta_celdas, driver = "ESRI Shapefile", quiet = TRUE, append = FALSE)
          
          # Listar todos los archivos del shapefile de celdas
          archivos_celdas <- list.files(temp_dir, pattern = paste0(gsub("\\.shp$", "", nombre_celdas), "\\.*"), full.names = TRUE)
          
          # Crear ZIP individual para shapefile de celdas
          nombre_zip_celdas <- paste0(codigo_exp, "_celdas_UNIFICADO.zip")
          ruta_zip_celdas <- file.path(zips_dir, nombre_zip_celdas)
          
          if (requireNamespace("zip", quietly = TRUE)) {
            zip::zip(ruta_zip_celdas, files = basename(archivos_celdas), root = temp_dir, mode = "cherry-pick")
          } else {
            old_wd <- getwd()
            setwd(temp_dir)
            utils::zip(ruta_zip_celdas, files = basename(archivos_celdas))
            setwd(old_wd)
          }
          
          archivos_zip_individuales <- c(archivos_zip_individuales, ruta_zip_celdas)
        }
      }
      
      # Verificar que se creó al menos un ZIP individual
      if (length(archivos_zip_individuales) == 0) {
        showNotification("No hay shapefiles para exportar después de aplicar exclusión jerárquica. Todas las grillas/celdas pertenecen a niveles superiores contaminados.", type = "warning", duration = 10)
        
        # Crear archivo de texto explicativo en zips_dir
        mensaje_path <- file.path(zips_dir, "INFORMACION.txt")
        writeLines(c(
          "═══════════════════════════════════════════════════════════════",
          "  SHAPEFILES CONTAMINADOS CON EXCLUSIÓN JERÁRQUICA",
          paste("  Generado:", Sys.time()),
          "═══════════════════════════════════════════════════════════════",
          "",
          "ℹ️  NO HAY SHAPEFILES INDIVIDUALES PARA EXPORTAR",
          "───────────────────────────────────────────────────────────────",
          "",
          "Todas las grillas y celdas contaminadas pertenecen a:",
          "  • Locaciones que se remediarán completas, o",
          "  • Celdas que se remediarán completas",
          "",
          "RECOMENDACIÓN:",
          "───────────────────────────────────────────────────────────────",
          "Consulte el análisis a nivel de LOCACIONES para identificar",
          "las áreas completas que requieren remediación."
        ), mensaje_path)
        
        archivos_zip_individuales <- c(mensaje_path)
      }
      
      # Crear ZIP principal con los ZIPs individuales (ZIP de ZIPs)
      if (requireNamespace("zip", quietly = TRUE)) {
        zip::zip(file, files = basename(archivos_zip_individuales), root = zips_dir, mode = "cherry-pick")
      } else {
        # Fallback a utils::zip si zip package no está disponible
        old_wd <- getwd()
        setwd(zips_dir)
        utils::zip(file, files = basename(archivos_zip_individuales))
        setwd(old_wd)
      }
      
      # Mensaje de éxito según lo que se generó
      n_zips <- length(archivos_zip_individuales)
      if (n_zips == 1 && grepl("INFORMACION", basename(archivos_zip_individuales[1]))) {
        showNotification("ZIP generado con información (no hay shapefiles individuales después de exclusión jerárquica)", type = "warning", duration = 5)
      } else {
        showNotification(paste0("ZIP de ZIPs generado exitosamente (", n_zips, " shapefile(s) individuales empaquetados)"), type = "message", duration = 5)
      }
      
    }, error = function(e) {
      registrar_error(e$message, "Descarga shapefiles contaminados")
      showNotification(paste("Error al generar shapefiles:", e$message), type = "error", duration = 10)
    })
  }
)
