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
        
        # ========== DEBUG: VERIFICAR CÓDIGOS DE GRILLA ==========
        cat("\n==================== DEBUG CÓDIGOS DE GRILLA ====================\n")
        cat("Columna seleccionada en shapefile:", col_grilla_shp, "\n")
        cat("\nPrimeros 10 códigos ÚNICOS en shapefile (", col_grilla_shp, "):\n", sep = "")
        print(head(unique(shp_grillas[[col_grilla_shp]]), 10))
        cat("\nPrimeros 10 códigos ÚNICOS en muestra (grilla de muestra_enriquecida):\n")
        print(head(unique(datos_prep$grilla), 10))
        cat("\nGrillas que superan umbral TPH (", umbral, "):\n", sep = "")
        cat("Total:", length(superan_grilla), "\n")
        print(head(superan_grilla, 20))
        cat("\nCódigos en shapefile después de crear COD_GRILLA:\n")
        print(head(unique(shp_grillas$COD_GRILLA), 10))
        cat("==================================================================\n\n")
        
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
      col_cod_plano_shp <- input$col_cod_plano_celda_shp
      prom_celdas <- promedios_celdas_resultado()
      
      # Crear columnas requeridas en shapefile (LOCACION, AREA y COD_PLANO si existe)
      # Nota: COD_UNIC se crea dinámicamente en generar_vertices_celdas
      if (!is.null(col_cod_plano_shp) && col_cod_plano_shp != "") {
        shp_celdas <- shp_celdas %>%
          mutate(
            LOCACION = .data[[col_locacion_shp]],
            AREA = .data[[col_area_shp]],
            COD_PLANO = .data[[col_cod_plano_shp]]
          )
      } else {
        shp_celdas <- shp_celdas %>%
          mutate(
            LOCACION = .data[[col_locacion_shp]],
            AREA = .data[[col_area_shp]],
            COD_PLANO = NA_character_  # Si no hay columna, usar NA
          )
      }
      
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
  # Verificar que hay datos de vértices generados
  tiene_grillas <- !is.null(vertices_grillas_unificado()) && nrow(vertices_grillas_unificado()) > 0
  tiene_celdas <- !is.null(vertices_celdas_unificado()) && nrow(vertices_celdas_unificado()) > 0
  tiene_locaciones <- !is.null(promedios_locaciones_resultado()) && nrow(promedios_locaciones_resultado()) > 0
  
  # Si no hay ningún dato, mostrar mensaje de advertencia
  if (!tiene_grillas && !tiene_celdas && !tiene_locaciones) {
    return(div(class = "alert alert-warning",
      h5("⚠️ No hay datos de análisis disponibles", style = "margin-top: 0;"),
      p("Para visualizar el resumen ejecutivo:"),
      tags$ol(
        tags$li("Asegúrese de haber cargado archivos de laboratorio"),
        tags$li("Genere los promedios y análisis (pestaña 'Análisis')"),
        tags$li("Cargue los shapefiles (pestaña 'Shapefiles')"),
        tags$li("Presione el botón 'Generar Vértices'")
      )
    ))
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
  if (is.null(vertices_grillas_unificado())) {
    return(p("⏳ Genere vértices primero", style = "color: #999; font-style: italic;"))
  }
  
  grillas <- unique(vertices_grillas_unificado()$COD_GRILLA)
  
  if (length(grillas) == 0) {
    return(div(
      p("✅ Ninguna grilla individual requiere remediación", style = "color: #5cb85c; font-style: italic; margin: 0;"),
      p("(Todas las grillas pertenecen a celdas o locaciones que se remediarán completas)", 
        style = "font-size: 0.85em; color: #666; margin-top: 5px;")
    ))
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
  if (is.null(vertices_celdas_unificado())) {
    return(p("⏳ Genere vértices primero", style = "color: #999; font-style: italic;"))
  }
  
  celdas <- unique(vertices_celdas_unificado()$COD_UNIC)
  
  if (length(celdas) == 0) {
    return(div(
      p("✅ Ninguna celda individual requiere remediación", style = "color: #5cb85c; font-style: italic; margin: 0;"),
      p("(Todas las celdas pertenecen a locaciones que se remediarán completas)", 
        style = "font-size: 0.85em; color: #666; margin-top: 5px;")
    ))
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
  if (is.null(promedios_locaciones_resultado())) {
    return(p("⏳ Genere análisis primero", style = "color: #999; font-style: italic;"))
  }
  
  loc_data <- promedios_locaciones_resultado()
  
  if (!"criterio_contaminacion" %in% names(loc_data)) {
    return(p("⚠️ Análisis incompleto", style = "color: #856404; font-style: italic;"))
  }
  
  locaciones <- loc_data %>% 
    filter(criterio_contaminacion != "No contaminada") %>% 
    pull(LOCACION)
  
  if (length(locaciones) == 0) {
    return(div(
      p("✅ Ninguna locación requiere remediación completa", style = "color: #5cb85c; font-style: italic;")
    ))
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

# ============================================================================ #
# OUTPUTS PARA PESTAÑA "SIN ANÁLISIS JERÁRQUICO"
# ============================================================================ #

# Resumen de conteos SIN jerarquía (todos los elementos contaminados)
output$resumen_sin_jerarquia_conteos <- renderUI({
  # Verificar que hay datos
  req(muestra_enriquecida())
  
  umbral <- input$umbral_tph
  
  # Contar grillas contaminadas (todas, sin filtro)
  n_grillas <- muestra_enriquecida() %>%
    filter(TPH > umbral) %>%
    nrow()
  
  # Contar celdas contaminadas (todas, sin filtro)
  n_celdas <- 0
  if (!is.null(promedios_celdas_resultado())) {
    n_celdas <- promedios_celdas_resultado() %>%
      filter(criterio_contaminacion != "No contaminada") %>%
      nrow()
  }
  
  # Contar locaciones contaminadas
  n_locaciones <- 0
  if (!is.null(promedios_locaciones_resultado())) {
    n_locaciones <- promedios_locaciones_resultado() %>%
      filter(criterio_contaminacion != "No contaminada") %>%
      nrow()
  }
  
  # Crear tabla de resumen
  div(
    tags$table(class = "table table-bordered table-striped", style = "margin-bottom: 0;",
      tags$thead(
        tags$tr(
          tags$th("Nivel", style = "background-color: #5bc0de; color: white; text-align: center;"),
          tags$th("Cantidad", style = "background-color: #5bc0de; color: white; text-align: center;"),
          tags$th("Descripción", style = "background-color: #5bc0de; color: white; text-align: center;")
        )
      ),
      tags$tbody(
        tags$tr(
          tags$td("📍 Grillas", style = "font-weight: bold;"),
          tags$td(n_grillas, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #d9534f;"),
          tags$td("Todas las grillas que superan el umbral TPH")
        ),
        tags$tr(
          tags$td("🔲 Celdas", style = "font-weight: bold;"),
          tags$td(n_celdas, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #f0ad4e;"),
          tags$td("Todas las celdas contaminadas (incluye celdas de locaciones contaminadas)")
        ),
        tags$tr(
          tags$td("🏢 Locaciones", style = "font-weight: bold;"),
          tags$td(n_locaciones, style = "text-align: center; font-size: 1.2em; font-weight: bold; color: #5bc0de;"),
          tags$td("Todas las locaciones contaminadas")
        ),
        tags$tr(style = "background-color: #f9f9f9; font-weight: bold;",
          tags$td("TOTAL ELEMENTOS", style = "text-align: right;"),
          tags$td(n_grillas + n_celdas + n_locaciones, 
                  style = "text-align: center; font-size: 1.3em; color: #333;"),
          tags$td("Total de elementos contaminados (puede haber sobreposición)")
        )
      )
    )
  )
})

# Lista de códigos de grillas SIN jerarquía
output$lista_grillas_sin_jerarquia <- renderUI({
  req(muestra_enriquecida())
  
  umbral <- input$umbral_tph
  
  grillas <- muestra_enriquecida() %>%
    filter(TPH > umbral) %>%
    pull(GRILLA) %>%
    unique() %>%
    sort()
  
  if (length(grillas) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  div(
    p(strong(paste("Total:", length(grillas), "grillas")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(grillas, collapse = ", ")
    )
  )
})

# Lista de códigos de celdas SIN jerarquía
output$lista_celdas_sin_jerarquia <- renderUI({
  req(promedios_celdas_resultado())
  
  celdas <- promedios_celdas_resultado() %>%
    filter(criterio_contaminacion != "No contaminada") %>%
    pull(CELDA) %>%
    unique() %>%
    sort()
  
  if (length(celdas) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  div(
    p(strong(paste("Total:", length(celdas), "celdas")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(celdas, collapse = ", ")
    )
  )
})

# Lista de códigos de locaciones SIN jerarquía (igual que con jerarquía)
output$lista_locaciones_sin_jerarquia <- renderUI({
  req(promedios_locaciones_resultado())
  
  locaciones <- promedios_locaciones_resultado() %>%
    filter(criterio_contaminacion != "No contaminada") %>%
    pull(LOCACION) %>%
    unique() %>%
    sort()
  
  if (length(locaciones) == 0) {
    return(p("Ninguna", style = "color: #999; font-style: italic;"))
  }
  
  div(
    p(strong(paste("Total:", length(locaciones), "locaciones")), style = "margin-bottom: 5px;"),
    tags$div(style = "max-height: 200px; overflow-y: auto; background: #f9f9f9; padding: 8px; border-radius: 4px; font-size: 0.9em;",
      paste(locaciones, collapse = ", ")
    )
  )
})

# ============================================================================ #
# DESCARGAR REPORTE CONTAMINADAS CON JERARQUÍA
# ============================================================================ #

output$descargar_reporte_jerarquia_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Reporte_CONTAMINADAS_JERARQUIA")
  },
  content = function(file) {
    req(vertices_grillas_unificado())
    req(vertices_celdas_unificado())
    req(promedios_locaciones_resultado())
    
    tryCatch({
      # Crear un workbook con múltiples hojas
      wb <- openxlsx::createWorkbook()
      umbral <- input$umbral_tph
      
      # ========== Hoja 1: GRILLAS CONTAMINADAS (CON JERARQUÍA) ==========
      # Solo grillas que NO pertenecen a celdas o locaciones contaminadas
      if (!is.null(vertices_grillas_unificado())) {
        grillas_jerarquia <- muestra_enriquecida() %>%
          filter(GRILLA %in% unique(vertices_grillas_unificado()$COD_GRILLA)) %>%
          mutate(criterio_contaminacion = "Supera umbral TPH") %>%
          select(criterio_contaminacion, everything())
        
        if (nrow(grillas_jerarquia) > 0) {
          openxlsx::addWorksheet(wb, "Grillas_Jerarquia")
          openxlsx::writeData(wb, "Grillas_Jerarquia", grillas_jerarquia)
        }
      }
      
      # ========== Hoja 2: CELDAS CONTAMINADAS (CON JERARQUÍA) ==========
      # Solo celdas que NO pertenecen a locaciones contaminadas
      if (!is.null(vertices_celdas_unificado()) && !is.null(promedios_celdas_resultado())) {
        # Extraer códigos únicos de celdas después de exclusión jerárquica
        celdas_jerarquia_codigos <- unique(vertices_celdas_unificado()$COD_UNIC)
        
        celdas_jerarquia <- promedios_celdas_resultado() %>%
          filter(CELDA %in% celdas_jerarquia_codigos) %>%
          filter(criterio_contaminacion != "No contaminada") %>%
          select(criterio_contaminacion, everything())
        
        if (nrow(celdas_jerarquia) > 0) {
          openxlsx::addWorksheet(wb, "Celdas_Jerarquia")
          openxlsx::writeData(wb, "Celdas_Jerarquia", celdas_jerarquia)
        }
      }
      
      # ========== Hoja 3: LOCACIONES CONTAMINADAS ==========
      # Locaciones contaminadas (nivel más alto, siempre se incluye)
      if (!is.null(promedios_locaciones_resultado())) {
        locaciones_contaminadas <- promedios_locaciones_resultado() %>%
          filter(criterio_contaminacion != "No contaminada") %>%
          select(criterio_contaminacion, everything())
        
        if (nrow(locaciones_contaminadas) > 0) {
          openxlsx::addWorksheet(wb, "Locaciones")
          openxlsx::writeData(wb, "Locaciones", locaciones_contaminadas)
        }
      }
      
      # ========== Hoja 4: RESUMEN EJECUTIVO CON JERARQUÍA ==========
      n_grillas_jer <- if (exists("grillas_jerarquia")) nrow(grillas_jerarquia) else 0
      n_celdas_jer <- if (exists("celdas_jerarquia")) nrow(celdas_jerarquia) else 0
      n_locaciones_jer <- if (exists("locaciones_contaminadas")) nrow(locaciones_contaminadas) else 0
      
      resumen_data <- data.frame(
        Nivel = c("📍 Grillas Individuales", "🔲 Celdas Completas", "🏢 Locaciones Completas", "═ TOTAL ÁREAS DISCRETAS"),
        Cantidad = c(n_grillas_jer, n_celdas_jer, n_locaciones_jer, n_grillas_jer + n_celdas_jer + n_locaciones_jer),
        Descripcion = c(
          "Grillas que NO pertenecen a celdas/locaciones contaminadas",
          "Celdas que NO pertenecen a locaciones contaminadas",
          "Locaciones completas contaminadas",
          "Total de áreas sujetas a remediación (sin duplicación)"
        ),
        Umbral_TPH = rep(umbral, 4),
        Fecha_Analisis = rep(as.character(Sys.Date()), 4)
      )
      
      openxlsx::addWorksheet(wb, "RESUMEN_JERARQUIA", gridLines = TRUE)
      openxlsx::writeData(wb, "RESUMEN_JERARQUIA", resumen_data)
      
      # Aplicar formato al resumen
      header_style <- openxlsx::createStyle(
        fontSize = 12, 
        fontColour = "#FFFFFF", 
        halign = "center",
        fgFill = "#d9534f", 
        border = "TopBottomLeftRight", 
        borderColour = "#d9534f",
        textDecoration = "bold"
      )
      
      openxlsx::addStyle(wb, sheet = "RESUMEN_JERARQUIA", header_style, rows = 1, cols = 1:5, gridExpand = TRUE)
      
      # Hoja 5: EXPLICACIÓN DE LA JERARQUÍA
      explicacion <- data.frame(
        Seccion = c(
          "ANÁLISIS CON JERARQUÍA",
          "",
          "Lógica aplicada:",
          "1. Nivel más alto",
          "2. Nivel medio",
          "3. Nivel individual",
          "",
          "Ventaja:",
          "",
          "Ejemplo práctico:",
          "",
          "",
          "Importante:"
        ),
        Contenido = c(
          paste("Generado el:", Sys.time()),
          "",
          "Prima LOCACIÓN sobre CELDAS, y CELDAS sobre GRILLAS",
          "Si una LOCACIÓN está contaminada, se remedia COMPLETA (no se listan sus celdas/grillas)",
          "Si una CELDA está contaminada (y su locación NO), se remedia COMPLETA (no se listan sus grillas)",
          "Solo se listan GRILLAS individuales si NO pertenecen a celdas/locaciones contaminadas",
          "",
          "Evita duplicación: no acusa grillas de celdas que ya se van a remediar completas",
          "",
          "Si Locación A tiene 3 celdas contaminadas, solo se reporta 'Locación A' (no sus 3 celdas)",
          "Si Celda C-01 tiene 5 grillas contaminadas, solo se reporta 'Celda C-01' (no sus 5 grillas)",
          "Solo si una grilla aislada está contaminada (sin celda/locación contaminada), se reporta individualmente",
          ""
        )
      )
      
      openxlsx::addWorksheet(wb, "EXPLICACION", gridLines = TRUE)
      openxlsx::writeData(wb, "EXPLICACION", explicacion, colNames = FALSE)
      
      # Guardar el workbook
      openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      
      showNotification("Reporte con jerarquía generado exitosamente", type = "message", duration = 5)
      
    }, error = function(e) {
      registrar_error(e$message, "Descarga reporte con jerarquía")
      showNotification(paste("Error al generar reporte con jerarquía:", e$message), type = "error", duration = 10)
    })
  }
)

# ============================================================================ #
# DESCARGAR VÉRTICES CON JERARQUÍA (EXCEL)
# ============================================================================ #

output$descargar_vertices_jerarquia_btn <- downloadHandler(
  filename = function() {
    generar_nombre_archivo_fase5("Vertices_JERARQUIA")
  },
  content = function(file) {
    tryCatch({
      # Crear un workbook con múltiples hojas
      wb <- openxlsx::createWorkbook()
      umbral <- input$umbral_tph
      
      tiene_datos <- FALSE
      
      # ========== Hoja 1: VÉRTICES DE GRILLAS (CON JERARQUÍA) - FORMATO COMPLETO ==========
      if (!is.null(vertices_grillas_unificado()) && nrow(vertices_grillas_unificado()) > 0) {
        
        # Preparar datos ordenados por LOCACION y codigo_punto
        datos_grillas <- vertices_grillas_unificado() %>%
          select(LOCACION, codigo_punto, COD_GRILLA, AREA, tph, ESTE, NORTE) %>%
          arrange(LOCACION, codigo_punto, ESTE, NORTE)
        
        # Agregar columna de número de vértice
        datos_grillas <- datos_grillas %>%
          group_by(LOCACION, codigo_punto) %>%
          mutate(Vertice = row_number()) %>%
          ungroup() %>%
          select(LOCACION, codigo_punto, COD_GRILLA, AREA, tph, Vertice, ESTE, NORTE)
        
        # Crear worksheet
        openxlsx::addWorksheet(wb, "Vertices_Grillas")
        
        # ========== ENCABEZADOS DE 2 FILAS ==========
        
        # Fila 1: Encabezados principales (algunos fusionados)
        fila1_headers <- c(
          "Pozo/Locación",
          "Punto de muestreo que supera el Nivel de Intervención",
          "Código de la rejilla a la que pertenece",
          "Área de la rejilla a la que pertenece (m2)",
          "TPH mg/kg",
          "Coordenadas de los vértices del perímetro del punto de muestreo que supera el Nivel de Intervención UTM WGS84, Zona 17M",
          "",  # Fusionado con anterior
          ""   # Fusionado con anterior
        )
        
        # Fila 2: Sub-encabezados (solo para columnas 6-8)
        fila2_headers <- c(
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "Vértice",
          "Este",
          "Norte"
        )
        
        # Escribir encabezados
        openxlsx::writeData(wb, "Vertices_Grillas", t(fila1_headers), startRow = 1, colNames = FALSE)
        openxlsx::writeData(wb, "Vertices_Grillas", t(fila2_headers), startRow = 2, colNames = FALSE)
        
        # Escribir datos (empezando en fila 3)
        openxlsx::writeData(wb, "Vertices_Grillas", datos_grillas, startRow = 3, colNames = FALSE)
        
        # ========== FUSIONES DE ENCABEZADOS ==========
        
        # Fusionar columnas 1-5 en fila 1 y 2 (verticalmente)
        for (col in 1:5) {
          openxlsx::mergeCells(wb, "Vertices_Grillas", cols = col, rows = 1:2)
        }
        
        # Fusionar columnas 6-8 en fila 1 (horizontalmente)
        openxlsx::mergeCells(wb, "Vertices_Grillas", cols = 6:8, rows = 1)
        
        # ========== FUSIONES DE DATOS ==========
        
        # Calcular rangos de fusión para cada locación y punto
        datos_con_rangos <- datos_grillas %>%
          mutate(row_num = row_number() + 2) %>%  # +2 porque empezamos en fila 3
          group_by(LOCACION) %>%
          mutate(
            loc_start = min(row_num),
            loc_end = max(row_num)
          ) %>%
          group_by(LOCACION, codigo_punto) %>%
          mutate(
            punto_start = min(row_num),
            punto_end = max(row_num)
          ) %>%
          ungroup()
        
        # Fusionar columna 1 (LOCACION) por grupos de locación
        rangos_locacion <- datos_con_rangos %>%
          select(LOCACION, loc_start, loc_end) %>%
          distinct() %>%
          filter(loc_end > loc_start)  # Solo fusionar si hay más de 1 fila
        
        if (nrow(rangos_locacion) > 0) {
          for (i in 1:nrow(rangos_locacion)) {
            openxlsx::mergeCells(wb, "Vertices_Grillas", 
                                cols = 1, 
                                rows = rangos_locacion$loc_start[i]:rangos_locacion$loc_end[i])
          }
        }
        
        # Fusionar columnas 2-5 (punto, grilla, area, tph) por grupos de punto
        rangos_punto <- datos_con_rangos %>%
          select(LOCACION, codigo_punto, punto_start, punto_end) %>%
          distinct() %>%
          filter(punto_end > punto_start)  # Solo fusionar si hay más de 1 vértice
        
        if (nrow(rangos_punto) > 0) {
          for (i in 1:nrow(rangos_punto)) {
            for (col in 2:5) {
              openxlsx::mergeCells(wb, "Vertices_Grillas",
                                  cols = col,
                                  rows = rangos_punto$punto_start[i]:rangos_punto$punto_end[i])
            }
          }
        }
        
        # ========== ESTILOS Y COLORES ==========
        
        # Estilo para encabezados principales (fila 1, columnas 1-5 y fusión 6-8)
        style_header_main <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#000000",
          halign = "center",
          valign = "center",
          fgFill = "#92D050",
          border = "TopBottomLeftRight",
          textDecoration = "bold",
          wrapText = TRUE
        )
        
        # Estilo para sub-encabezados de coordenadas (fila 2, columnas 6-8)
        style_header_coords <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#000000",
          halign = "center",
          valign = "center",
          fgFill = "#C6E0B4",
          border = "TopBottomLeftRight",
          textDecoration = "bold"
        )
        
        # Aplicar estilos a encabezados
        openxlsx::addStyle(wb, "Vertices_Grillas", style_header_main, rows = 1:2, cols = 1:5, gridExpand = TRUE)
        openxlsx::addStyle(wb, "Vertices_Grillas", style_header_main, rows = 1, cols = 6:8, gridExpand = TRUE)
        openxlsx::addStyle(wb, "Vertices_Grillas", style_header_coords, rows = 2, cols = 6:8, gridExpand = TRUE)
        
        # Estilo para columna LOCACION (azul claro)
        style_locacion <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#D9E1F2",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para columnas punto, grilla, area (verde oliva)
        style_punto_grilla <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#A9D08E",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para columna TPH (rojo con texto blanco)
        style_tph <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#FFFFFF",
          halign = "center",
          valign = "center",
          fgFill = "#FF0000",
          border = "TopBottomLeftRight",
          textDecoration = "bold"
        )
        
        # Estilo para columnas de coordenadas (verde claro)
        style_coords <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#E2EFDA",
          border = "TopBottomLeftRight"
        )
        
        # Aplicar estilos a datos
        num_rows_datos <- nrow(datos_grillas)
        if (num_rows_datos > 0) {
          # Columna 1: LOCACION
          openxlsx::addStyle(wb, "Vertices_Grillas", style_locacion, rows = 3:(3 + num_rows_datos - 1), cols = 1, gridExpand = TRUE)
          
          # Columnas 2-4: punto, grilla, area
          openxlsx::addStyle(wb, "Vertices_Grillas", style_punto_grilla, rows = 3:(3 + num_rows_datos - 1), cols = 2:4, gridExpand = TRUE)
          
          # Columna 5: TPH
          openxlsx::addStyle(wb, "Vertices_Grillas", style_tph, rows = 3:(3 + num_rows_datos - 1), cols = 5, gridExpand = TRUE)
          
          # Columnas 6-8: Vértice, Este, Norte
          openxlsx::addStyle(wb, "Vertices_Grillas", style_coords, rows = 3:(3 + num_rows_datos - 1), cols = 6:8, gridExpand = TRUE)
        }
        
        # ========== AJUSTAR ANCHOS DE COLUMNA ==========
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 1, widths = 15)  # Locación
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 2, widths = 25)  # Punto
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 3, widths = 20)  # Código grilla
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 4, widths = 15)  # Área
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 5, widths = 12)  # TPH
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 6, widths = 10)  # Vértice
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 7, widths = 15)  # Este
        openxlsx::setColWidths(wb, "Vertices_Grillas", cols = 8, widths = 15)  # Norte
        
        # Ajustar altura de filas de encabezado
        openxlsx::setRowHeights(wb, "Vertices_Grillas", rows = 1, heights = 45)
        openxlsx::setRowHeights(wb, "Vertices_Grillas", rows = 2, heights = 20)
        
        tiene_datos <- TRUE
      }
      
      # ========== Hoja 2: VÉRTICES DE CELDAS (CON JERARQUÍA) - FORMATO COMPLETO ==========
      if (!is.null(vertices_celdas_unificado()) && nrow(vertices_celdas_unificado()) > 0) {
        
        # Preparar datos ordenados por LOCACION y COD_UNIC
        datos_celdas <- vertices_celdas_unificado() %>%
          select(LOCACION, COD_UNIC, puntos_superan, AREA, ESTE, NORTE, tph_celda, prop_superan_pct) %>%
          arrange(LOCACION, COD_UNIC, ESTE, NORTE)
        
        # Agregar columna de número de vértice
        datos_celdas <- datos_celdas %>%
          group_by(LOCACION, COD_UNIC) %>%
          mutate(Vertice = row_number()) %>%
          ungroup() %>%
          select(LOCACION, COD_UNIC, puntos_superan, AREA, Vertice, ESTE, NORTE, tph_celda, prop_superan_pct)
        
        # Crear worksheet
        openxlsx::addWorksheet(wb, "Vertices_Celdas")
        
        # ========== ENCABEZADOS DE 2 FILAS ==========
        
        # Fila 1: Encabezados principales
        fila1_headers <- c(
          "Pozo/Locación",
          "Celdas contaminadas",
          "Código de los puntos que superaron el nivel de intervención dentro de la celda",
          "Área de la celda contaminada",
          "Coordenadas de los vértices del perímetro del punto de muestreo que supera el Nivel de Intervención UTM WGS84, Zona 17M",
          "",  # Fusionado con anterior
          "",  # Fusionado con anterior
          "TPH mg/kg (Promedio ponderado)",
          "Proporción de puntos contaminados"
        )
        
        # Fila 2: Sub-encabezados
        fila2_headers <- c(
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "",  # Fusionado con fila 1
          "Vértice",
          "Este",
          "Norte",
          "",  # Fusionado con fila 1
          ""   # Fusionado con fila 1
        )
        
        # Escribir encabezados
        openxlsx::writeData(wb, "Vertices_Celdas", t(fila1_headers), startRow = 1, colNames = FALSE)
        openxlsx::writeData(wb, "Vertices_Celdas", t(fila2_headers), startRow = 2, colNames = FALSE)
        
        # Escribir datos (empezando en fila 3)
        openxlsx::writeData(wb, "Vertices_Celdas", datos_celdas, startRow = 3, colNames = FALSE)
        
        # ========== FUSIONES DE ENCABEZADOS ==========
        
        # Fusionar columnas 1-4, 8-9 en fila 1 y 2 (verticalmente)
        for (col in c(1:4, 8:9)) {
          openxlsx::mergeCells(wb, "Vertices_Celdas", cols = col, rows = 1:2)
        }
        
        # Fusionar columnas 5-7 en fila 1 (horizontalmente)
        openxlsx::mergeCells(wb, "Vertices_Celdas", cols = 5:7, rows = 1)
        
        # ========== FUSIONES DE DATOS ==========
        
        # Calcular rangos de fusión para cada locación y celda
        datos_con_rangos <- datos_celdas %>%
          mutate(row_num = row_number() + 2) %>%  # +2 porque empezamos en fila 3
          group_by(LOCACION) %>%
          mutate(
            loc_start = min(row_num),
            loc_end = max(row_num)
          ) %>%
          group_by(LOCACION, COD_UNIC) %>%
          mutate(
            celda_start = min(row_num),
            celda_end = max(row_num)
          ) %>%
          ungroup()
        
        # Fusionar columna 1 (LOCACION) por grupos de locación
        rangos_locacion <- datos_con_rangos %>%
          select(LOCACION, loc_start, loc_end) %>%
          distinct() %>%
          filter(loc_end > loc_start)
        
        if (nrow(rangos_locacion) > 0) {
          for (i in 1:nrow(rangos_locacion)) {
            openxlsx::mergeCells(wb, "Vertices_Celdas", 
                                cols = 1, 
                                rows = rangos_locacion$loc_start[i]:rangos_locacion$loc_end[i])
          }
        }
        
        # Fusionar columnas 2-4, 8-9 por grupos de celda
        rangos_celda <- datos_con_rangos %>%
          select(LOCACION, COD_UNIC, celda_start, celda_end) %>%
          distinct() %>%
          filter(celda_end > celda_start)
        
        if (nrow(rangos_celda) > 0) {
          for (i in 1:nrow(rangos_celda)) {
            for (col in c(2:4, 8:9)) {
              openxlsx::mergeCells(wb, "Vertices_Celdas",
                                  cols = col,
                                  rows = rangos_celda$celda_start[i]:rangos_celda$celda_end[i])
            }
          }
        }
        
        # ========== ESTILOS Y COLORES ==========
        
        # Estilo para encabezados principales
        style_header_main <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#000000",
          halign = "center",
          valign = "center",
          fgFill = "#92D050",
          border = "TopBottomLeftRight",
          textDecoration = "bold",
          wrapText = TRUE
        )
        
        # Estilo para sub-encabezados de coordenadas
        style_header_coords <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#000000",
          halign = "center",
          valign = "center",
          fgFill = "#C6E0B4",
          border = "TopBottomLeftRight",
          textDecoration = "bold"
        )
        
        # Aplicar estilos a encabezados
        openxlsx::addStyle(wb, "Vertices_Celdas", style_header_main, rows = 1:2, cols = c(1:4, 8:9), gridExpand = TRUE)
        openxlsx::addStyle(wb, "Vertices_Celdas", style_header_main, rows = 1, cols = 5:7, gridExpand = TRUE)
        openxlsx::addStyle(wb, "Vertices_Celdas", style_header_coords, rows = 2, cols = 5:7, gridExpand = TRUE)
        
        # Estilo para columna LOCACION (azul claro)
        style_locacion <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#D9E1F2",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para columna celda (verde claro)
        style_celda <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#E2EFDA",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para puntos superan (blanco)
        style_puntos <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#FFFFFF",
          border = "TopBottomLeftRight",
          wrapText = TRUE
        )
        
        # Estilo para área (verde claro)
        style_area <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#E2EFDA",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para coordenadas (blanco)
        style_coords <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#FFFFFF",
          border = "TopBottomLeftRight"
        )
        
        # Estilo para TPH (rojo con texto blanco)
        style_tph <- openxlsx::createStyle(
          fontSize = 10,
          fontColour = "#FFFFFF",
          halign = "center",
          valign = "center",
          fgFill = "#FF0000",
          border = "TopBottomLeftRight",
          textDecoration = "bold"
        )
        
        # Estilo para proporción (verde claro)
        style_prop <- openxlsx::createStyle(
          fontSize = 10,
          halign = "center",
          valign = "center",
          fgFill = "#E2EFDA",
          border = "TopBottomLeftRight"
        )
        
        # Aplicar estilos a datos
        num_rows_datos <- nrow(datos_celdas)
        if (num_rows_datos > 0) {
          openxlsx::addStyle(wb, "Vertices_Celdas", style_locacion, rows = 3:(3 + num_rows_datos - 1), cols = 1, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_celda, rows = 3:(3 + num_rows_datos - 1), cols = 2, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_puntos, rows = 3:(3 + num_rows_datos - 1), cols = 3, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_area, rows = 3:(3 + num_rows_datos - 1), cols = 4, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_coords, rows = 3:(3 + num_rows_datos - 1), cols = 5:7, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_tph, rows = 3:(3 + num_rows_datos - 1), cols = 8, gridExpand = TRUE)
          openxlsx::addStyle(wb, "Vertices_Celdas", style_prop, rows = 3:(3 + num_rows_datos - 1), cols = 9, gridExpand = TRUE)
        }
        
        # ========== AJUSTAR ANCHOS DE COLUMNA ==========
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 1, widths = 15)   # Locación
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 2, widths = 18)   # Celda
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 3, widths = 35)   # Puntos superan
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 4, widths = 15)   # Área
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 5, widths = 10)   # Vértice
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 6, widths = 15)   # Este
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 7, widths = 15)   # Norte
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 8, widths = 15)   # TPH
        openxlsx::setColWidths(wb, "Vertices_Celdas", cols = 9, widths = 18)   # Proporción
        
        # Ajustar altura de filas de encabezado
        openxlsx::setRowHeights(wb, "Vertices_Celdas", rows = 1, heights = 50)
        openxlsx::setRowHeights(wb, "Vertices_Celdas", rows = 2, heights = 20)
        
        tiene_datos <- TRUE
      }
      
      # ========== Hoja 3: LOCACIONES CONTAMINADAS - FORMATO COMPLETO ==========
      # Lista todas las celdas de cada locación contaminada
      if (!is.null(promedios_locaciones_resultado()) && !is.null(shp_celdas_data()) && !is.null(muestra_enriquecida())) {
        locs_contaminadas <- promedios_locaciones_resultado() %>%
          filter(criterio_contaminacion != "No contaminada")
        
        if (nrow(locs_contaminadas) > 0) {
          # Crear lista de códigos de puntos contaminados por locación
          puntos_por_locacion <- muestra_enriquecida() %>%
            filter(TPH > input$umbral_tph) %>%
            group_by(LOCACION) %>%
            summarise(
              puntos_contaminados = paste(sort(unique(PUNTO)), collapse = ", "),
              .groups = "drop"
            )
          
          # Unir puntos contaminados a locaciones
          locs_contaminadas <- locs_contaminadas %>%
            left_join(puntos_por_locacion, by = "LOCACION") %>%
            mutate(puntos_contaminados = ifelse(is.na(puntos_contaminados), "", puntos_contaminados))
          
          # Obtener shapefile de celdas con atributos
          # El shapefile ya tiene las columnas estandarizadas durante la carga
          shp_celdas_attrs <- shp_celdas_data() %>%
            st_drop_geometry()
          
          # Detectar columna de código de celda
          col_celda <- NULL
          if ("COD_CELDA" %in% names(shp_celdas_attrs)) {
            col_celda <- "COD_CELDA"
          } else if ("CELDA" %in% names(shp_celdas_attrs)) {
            col_celda <- "CELDA"
          } else if ("COD_UNIC" %in% names(shp_celdas_attrs)) {
            col_celda <- "COD_UNIC"
          }
          
          # Si no encontramos columna de celda, usar la primera columna
          if (is.null(col_celda)) {
            col_celda <- names(shp_celdas_attrs)[1]
          }
          
          # Seleccionar y renombrar columnas
          shp_celdas_attrs <- shp_celdas_attrs %>%
            select(any_of(c(col_celda, "LOCACION", "AREA", "COD_PLANO"))) %>%
            rename(COD_CELDA = 1)  # Renombrar primera columna a COD_CELDA
          
          # Crear tabla expandida: para cada locación contaminada, listar todas sus celdas
          datos_locaciones <- locs_contaminadas %>%
            select(LOCACION, puntos_contaminados, TPH, prop_exceed) %>%
            inner_join(
              shp_celdas_attrs,
              by = "LOCACION",
              relationship = "many-to-many"
            ) %>%
            arrange(LOCACION, COD_CELDA) %>%
            select(LOCACION, puntos_contaminados, COD_CELDA, any_of("COD_PLANO"), AREA, TPH, prop_exceed)
          
          # Verificar que hay datos
          if (nrow(datos_locaciones) > 0) {
            
            # Crear worksheet
            openxlsx::addWorksheet(wb, "Locaciones_Contaminadas")
            
            # ========== ENCABEZADOS DINÁMICOS ==========
            # Detectar si COD_PLANO existe
            tiene_cod_plano <- "COD_PLANO" %in% names(datos_locaciones)
            
            if (tiene_cod_plano) {
              headers <- c(
                "Pozo/Locación",
                "Código de los puntos que superaron el nivel de intervención dentro de la celda",
                "Código de la Celda",
                "Código de la celda en el plano",
                "Área de la celda contaminada (m2)",
                "TPH mg/kg (Promedio ponderado)",
                "Proporción de puntos contaminados"
              )
              # Índices de columnas para fusionar
              cols_fusionar <- c(1, 2, 6, 7)
            } else {
              headers <- c(
                "Pozo/Locación",
                "Código de los puntos que superaron el nivel de intervención dentro de la celda",
                "Código de la Celda",
                "Área de la celda contaminada (m2)",
                "TPH mg/kg (Promedio ponderado)",
                "Proporción de puntos contaminados"
              )
              # Índices de columnas para fusionar (sin COD_PLANO)
              cols_fusionar <- c(1, 2, 5, 6)
            }
            
            # Escribir encabezados
            openxlsx::writeData(wb, "Locaciones_Contaminadas", t(headers), startRow = 1, colNames = FALSE)
            
            # Escribir datos (empezando en fila 2)
            openxlsx::writeData(wb, "Locaciones_Contaminadas", datos_locaciones, startRow = 2, colNames = FALSE)
            
            # ========== FUSIONES DE DATOS ==========
            
            # Calcular rangos de fusión para cada locación
            datos_con_rangos <- datos_locaciones %>%
              mutate(row_num = row_number() + 1) %>%  # +1 porque empezamos en fila 2
              group_by(LOCACION) %>%
              mutate(
                loc_start = min(row_num),
                loc_end = max(row_num)
              ) %>%
              ungroup()
            
            # Fusionar columnas (Locación, puntos, TPH, proporción) por locación
            rangos_locacion <- datos_con_rangos %>%
              select(LOCACION, loc_start, loc_end) %>%
              distinct() %>%
              filter(loc_end > loc_start)
            
            if (nrow(rangos_locacion) > 0) {
              for (i in 1:nrow(rangos_locacion)) {
                # Fusionar columnas según si tiene o no COD_PLANO
                for (col in cols_fusionar) {
                  openxlsx::mergeCells(wb, "Locaciones_Contaminadas",
                                      cols = col,
                                      rows = rangos_locacion$loc_start[i]:rangos_locacion$loc_end[i])
                }
              }
            }
            
            # ========== ESTILOS Y COLORES ==========
            
            # Estilo para encabezados
            style_header <- openxlsx::createStyle(
              fontSize = 10,
              fontColour = "#000000",
              halign = "center",
              valign = "center",
              fgFill = "#92D050",
              border = "TopBottomLeftRight",
              textDecoration = "bold",
              wrapText = TRUE
            )
            
            openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_header, rows = 1, cols = 1:7, gridExpand = TRUE)
            
            # Estilo para columna LOCACION (azul claro)
            style_locacion <- openxlsx::createStyle(
              fontSize = 10,
              halign = "center",
              valign = "center",
              fgFill = "#D9E1F2",
              border = "TopBottomLeftRight"
            )
            
            # Estilo para puntos (blanco)
            style_puntos <- openxlsx::createStyle(
              fontSize = 10,
              halign = "center",
              valign = "center",
              fgFill = "#FFFFFF",
              border = "TopBottomLeftRight",
              wrapText = TRUE
            )
            
            # Estilo para códigos de celda (blanco)
            style_celda <- openxlsx::createStyle(
              fontSize = 10,
              halign = "center",
              valign = "center",
              fgFill = "#FFFFFF",
              border = "TopBottomLeftRight"
            )
            
            # Estilo para área (blanco)
            style_area <- openxlsx::createStyle(
              fontSize = 10,
              halign = "center",
              valign = "center",
              fgFill = "#FFFFFF",
              border = "TopBottomLeftRight"
            )
            
            # Estilo para TPH (rojo con texto blanco)
            style_tph <- openxlsx::createStyle(
              fontSize = 10,
              fontColour = "#FFFFFF",
              halign = "center",
              valign = "center",
              fgFill = "#FF0000",
              border = "TopBottomLeftRight",
              textDecoration = "bold"
            )
            
            # Estilo para proporción (verde claro)
            style_prop <- openxlsx::createStyle(
              fontSize = 10,
              halign = "center",
              valign = "center",
              fgFill = "#E2EFDA",
              border = "TopBottomLeftRight"
            )
            
            # Aplicar estilos a datos (dinámico según si tiene COD_PLANO)
            num_rows_datos <- nrow(datos_locaciones)
            if (num_rows_datos > 0) {
              openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_locacion, rows = 2:(2 + num_rows_datos - 1), cols = 1, gridExpand = TRUE)
              openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_puntos, rows = 2:(2 + num_rows_datos - 1), cols = 2, gridExpand = TRUE)
              
              if (tiene_cod_plano) {
                # Con COD_PLANO: col 3 = celda, col 4 = plano, col 5 = área, col 6 = TPH, col 7 = prop
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_celda, rows = 2:(2 + num_rows_datos - 1), cols = 3:4, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_area, rows = 2:(2 + num_rows_datos - 1), cols = 5, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_tph, rows = 2:(2 + num_rows_datos - 1), cols = 6, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_prop, rows = 2:(2 + num_rows_datos - 1), cols = 7, gridExpand = TRUE)
              } else {
                # Sin COD_PLANO: col 3 = celda, col 4 = área, col 5 = TPH, col 6 = prop
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_celda, rows = 2:(2 + num_rows_datos - 1), cols = 3, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_area, rows = 2:(2 + num_rows_datos - 1), cols = 4, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_tph, rows = 2:(2 + num_rows_datos - 1), cols = 5, gridExpand = TRUE)
                openxlsx::addStyle(wb, "Locaciones_Contaminadas", style_prop, rows = 2:(2 + num_rows_datos - 1), cols = 6, gridExpand = TRUE)
              }
            }
            
            # ========== AJUSTAR ANCHOS DE COLUMNA (dinámico) ==========
            openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 1, widths = 15)   # Locación
            openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 2, widths = 45)   # Puntos
            
            if (tiene_cod_plano) {
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 3, widths = 18)   # Cód celda
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 4, widths = 18)   # Cód plano
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 5, widths = 15)   # Área
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 6, widths = 15)   # TPH
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 7, widths = 18)   # Proporción
            } else {
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 3, widths = 18)   # Cód celda
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 4, widths = 15)   # Área
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 5, widths = 15)   # TPH
              openxlsx::setColWidths(wb, "Locaciones_Contaminadas", cols = 6, widths = 18)   # Proporción
            }
            
            # Ajustar altura de fila de encabezado
            openxlsx::setRowHeights(wb, "Locaciones_Contaminadas", rows = 1, heights = 45)
            
            tiene_datos <- TRUE
          }
        }
      }
      
      # ========== Hoja 4: RESUMEN EJECUTIVO ==========
      n_grillas <- if (!is.null(vertices_grillas_unificado())) length(unique(vertices_grillas_unificado()$COD_GRILLA)) else 0
      n_celdas <- if (!is.null(vertices_celdas_unificado())) length(unique(vertices_celdas_unificado()$COD_UNIC)) else 0
      n_locaciones <- 0
      if (!is.null(promedios_locaciones_resultado())) {
        n_locaciones <- promedios_locaciones_resultado() %>% 
          filter(criterio_contaminacion != "No contaminada") %>% 
          nrow()
      }
      
      resumen_data <- data.frame(
        Nivel = c("📍 Grillas Individuales", "🔲 Celdas Completas", "🏢 Locaciones Completas", "═ TOTAL POLÍGONOS"),
        Cantidad_Elementos = c(n_grillas, n_celdas, n_locaciones, n_grillas + n_celdas + n_locaciones),
        Descripcion = c(
          "Vértices de grillas que NO pertenecen a celdas/locaciones contaminadas",
          "Vértices de celdas que NO pertenecen a locaciones contaminadas",
          "Locaciones completas (promedios, no tienen vértices)",
          "Total de polígonos discretos para remediación"
        ),
        Hoja_Excel = c("Vertices_Grillas", "Vertices_Celdas", "Locaciones_Contaminadas", "---"),
        Umbral_TPH = rep(umbral, 4),
        Fecha_Generacion = rep(as.character(Sys.Date()), 4)
      )
      
      openxlsx::addWorksheet(wb, "RESUMEN", gridLines = TRUE)
      openxlsx::writeData(wb, "RESUMEN", resumen_data)
      
      # Aplicar formato al resumen
      header_style <- openxlsx::createStyle(
        fontSize = 12, 
        fontColour = "#FFFFFF", 
        halign = "center",
        fgFill = "#5cb85c", 
        border = "TopBottomLeftRight", 
        borderColour = "#5cb85c",
        textDecoration = "bold"
      )
      openxlsx::addStyle(wb, sheet = "RESUMEN", header_style, rows = 1, cols = 1:6, gridExpand = TRUE)
      
      # ========== Hoja 5: EXPLICACIÓN ==========
      explicacion <- data.frame(
        Seccion = c(
          "VÉRTICES DE POLÍGONOS CON JERARQUÍA",
          "",
          "Contenido:",
          "• Hoja 'Vertices_Grillas'",
          "• Hoja 'Vertices_Celdas'",
          "• Hoja 'Locaciones_Contaminadas'",
          "",
          "Lógica jerárquica aplicada:",
          "1. LOCACIÓN > CELDA > GRILLA",
          "2. Prima nivel superior",
          "3. Exclusión automática",
          "",
          "¿Para qué sirven estos vértices?",
          "",
          "",
          "",
          "Nota importante:"
        ),
        Contenido = c(
          paste("Generado el:", Sys.time()),
          "",
          "Este archivo contiene las coordenadas (vértices) de los polígonos contaminados",
          "Coordenadas de grillas individuales (sin celdas/locaciones contaminadas)",
          "Coordenadas de celdas completas (sin locaciones contaminadas)",
          "Promedios de locaciones contaminadas (nivel más alto)",
          "",
          "",
          "Si una locación está contaminada, NO se listan sus celdas ni grillas",
          "Si una celda está contaminada, NO se listan sus grillas individuales",
          "Solo se listan grillas individuales que NO pertenecen a niveles superiores contaminados",
          "",
          "Para importar en software GIS (ArcGIS, QGIS, etc.)",
          "Para delimitar áreas de remediación",
          "Para calcular superficies exactas de intervención",
          "Para generar mapas de campo",
          "Los vértices están en formato ESTE (X), NORTE (Y) en sistema de coordenadas UTM"
        )
      )
      
      openxlsx::addWorksheet(wb, "EXPLICACION", gridLines = TRUE)
      openxlsx::writeData(wb, "EXPLICACION", explicacion, colNames = FALSE)
      
      # Verificar si hay datos para exportar
      if (!tiene_datos) {
        # Si no hay datos, agregar una nota
        openxlsx::addWorksheet(wb, "INFORMACION")
        info <- data.frame(
          Mensaje = c(
            "No hay vértices disponibles para exportar.",
            "",
            "Posibles razones:",
            "1. No se han generado vértices aún (presione el botón 'Generar Vértices')",
            "2. Todos los elementos contaminados se remedian a nivel de LOCACIÓN completa",
            "3. No hay shapefiles de grillas/celdas cargados"
          )
        )
        openxlsx::writeData(wb, "INFORMACION", info, colNames = FALSE)
      }
      
      # Guardar el workbook
      openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      
      if (tiene_datos) {
        showNotification("Excel de vértices con jerarquía generado exitosamente", type = "message", duration = 5)
      } else {
        showNotification("Excel generado con información (no hay vértices disponibles)", type = "warning", duration = 5)
      }
      
    }, error = function(e) {
      error_msg <- if (!is.null(e$message) && nchar(e$message) > 0) {
        e$message
      } else {
        paste("Error en línea:", deparse(conditionCall(e)), collapse = " ")
      }
      
      # Registrar error con información adicional
      registrar_error(error_msg, "Descarga vértices con jerarquía")
      
      # Mostrar notificación al usuario
      showNotification(paste("Error al generar Excel de vértices:", error_msg), type = "error", duration = 10)
      
      # Log adicional en consola para debugging
      cat("\n❌ ERROR en descarga de vértices con jerarquía:\n")
      cat("Mensaje:", error_msg, "\n")
      cat("Clase:", class(e), "\n")
      print(e)
    })
  }
)

# ============================================================================ #
# TEXTO PARA LAS CONCLUSIONES - Nueva pestaña de Fase 5
# ============================================================================ #

# Variable reactiva para almacenar el texto generado
texto_conclusiones_generado <- reactiveVal(NULL)

# Indicador de disponibilidad
output$texto_conclusiones_disponible <- reactive({
  !is.null(texto_conclusiones_generado())
})
outputOptions(output, "texto_conclusiones_disponible", suspendWhenHidden = FALSE)

# Mensaje informativo sobre disponibilidad
output$info_texto_conclusiones_disponible <- renderUI({
  if (is.null(texto_conclusiones_generado())) {
    div(class = "alert alert-warning",
      h5("⚠️ Texto no generado"),
      p("Presione el botón ", tags$b("'Generar Texto de Conclusiones'"), " para crear el documento.")
    )
  } else {
    div(class = "alert alert-success",
      h5("✅ Texto generado exitosamente"),
      p("El texto ha sido generado con los datos del análisis. Puede descargarlo usando el botón de la izquierda.")
    )
  }
})

# Outputs para selectores de columna de área en shapefiles
output$selector_col_area_grillas <- renderUI({
  if (!is.null(columnas_shp_grillas()) && length(columnas_shp_grillas()) > 0) {
    cols <- columnas_shp_grillas()
    col_sugerida <- col_area_grillas_detectada()
    
    tagList(
      selectInput("col_area_grillas_manual",
                 "Shapefile de Grillas - Columna de Área:",
                 choices = cols,
                 selected = if(!is.null(col_sugerida)) col_sugerida else cols[1]),
      if (!is.null(col_sugerida)) {
        p(style = "font-size: 0.8em; color: #28a745; margin-top: -10px;",
          icon("check-circle"), " Detectada automáticamente: ", tags$b(col_sugerida))
      } else {
        p(style = "font-size: 0.8em; color: #ff9800; margin-top: -10px;",
          icon("exclamation-triangle"), " No detectada, seleccione manualmente")
      }
    )
  } else {
    p(style = "font-size: 0.85em; color: #999; font-style: italic;",
      "⏳ Cargue el shapefile de grillas en la sección 5C para habilitar")
  }
})

output$selector_col_area_celdas <- renderUI({
  if (!is.null(columnas_shp_celdas()) && length(columnas_shp_celdas()) > 0) {
    cols <- columnas_shp_celdas()
    col_sugerida <- col_area_celdas_detectada()
    
    tagList(
      selectInput("col_area_celdas_manual",
                 "Shapefile de Celdas - Columna de Área:",
                 choices = cols,
                 selected = if(!is.null(col_sugerida)) col_sugerida else cols[1]),
      if (!is.null(col_sugerida)) {
        p(style = "font-size: 0.8em; color: #28a745; margin-top: -10px;",
          icon("check-circle"), " Detectada automáticamente: ", tags$b(col_sugerida))
      } else {
        p(style = "font-size: 0.8em; color: #ff9800; margin-top: -10px;",
          icon("exclamation-triangle"), " No detectada, seleccione manualmente")
      }
    )
  } else {
    p(style = "font-size: 0.85em; color: #999; font-style: italic;",
      "⏳ Cargue el shapefile de celdas en la sección 5C para habilitar")
  }
})

# Handler para generar el texto
observeEvent(input$generar_texto_conclusiones_btn, {
  req(muestra_enriquecida(), promedios_celdas_resultado(), promedios_locaciones_resultado())
  req(input$umbral_tph)
  
  tryCatch({
    showNotification("Generando texto de conclusiones...", type = "message", duration = 3)
    
    # Obtener datos
    muestra <- muestra_enriquecida()
    celdas <- promedios_celdas_resultado()
    locaciones <- promedios_locaciones_resultado()
    umbral <- input$umbral_tph
    
    vert_grillas <- vertices_grillas_unificado()
    vert_celdas <- vertices_celdas_unificado()
    
    # Información del usuario
    nombre_lote <- input$nombre_lote_conclusiones
    nombre_empresa <- input$nombre_empresa_conclusiones
    area_grilla <- input$area_grilla_conclusiones
    lado_grilla <- input$lado_grilla_conclusiones
    
    # Obtener shapefiles y columnas de área
    shp_grillas <- shp_grillas_data()
    shp_celdas <- shp_celdas_data()
    col_area_grillas <- input$col_area_grillas_manual
    col_area_celdas <- input$col_area_celdas_manual
    
    # Generar texto usando función auxiliar
    texto <- generar_texto_conclusiones(
      muestra = muestra,
      celdas = celdas,
      locaciones = locaciones,
      umbral = umbral,
      vert_grillas = vert_grillas,
      vert_celdas = vert_celdas,
      nombre_lote = nombre_lote,
      nombre_empresa = nombre_empresa,
      area_grilla = area_grilla,
      lado_grilla = lado_grilla,
      shp_grillas = shp_grillas,
      shp_celdas = shp_celdas,
      col_area_grillas = col_area_grillas,
      col_area_celdas = col_area_celdas
    )
    
    # Guardar el texto generado
    texto_conclusiones_generado(texto)
    
    showNotification("✅ Texto de conclusiones generado exitosamente", type = "message", duration = 5)
    
  }, error = function(e) {
    registrar_error(e$message, "Generación de texto de conclusiones")
    showNotification(paste("Error al generar texto:", e$message), type = "error", duration = 10)
  })
})

# Mostrar el texto generado
output$texto_conclusiones_display <- renderUI({
  texto <- texto_conclusiones_generado()
  
  if (is.null(texto)) {
    div(class = "alert alert-secondary",
      p(style = "text-align: center; color: #999; margin: 50px 0;",
        "El texto aparecerá aquí una vez que presione el botón 'Generar Texto de Conclusiones'")
    )
  } else {
    tags$pre(
      style = "margin: 0; padding: 0; font-family: 'Courier New', monospace; font-size: 12px; white-space: pre-wrap; word-wrap: break-word; line-height: 1.6;",
      texto
    )
  }
})

# Handler para copiar al portapapeles
observeEvent(input$copiar_texto_conclusiones_btn, {
  req(texto_conclusiones_generado())
  
  tryCatch({
    # Crear un textarea temporal con el texto
    texto <- texto_conclusiones_generado()
    
    # Usar JavaScript para copiar al portapapeles
    js_code <- sprintf(
      "
      var textarea = document.createElement('textarea');
      textarea.value = %s;
      textarea.style.position = 'fixed';
      textarea.style.opacity = 0;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      ",
      jsonlite::toJSON(texto, auto_unbox = TRUE)
    )
    
    shinyjs::runjs(js_code)
    
    showNotification("✅ Texto copiado al portapapeles exitosamente", 
                     type = "message", 
                     duration = 3)
    
  }, error = function(e) {
    showNotification(paste("Error al copiar:", e$message), 
                     type = "warning", 
                     duration = 5)
  })
})

# Handler de descarga
output$descargar_texto_conclusiones_btn <- downloadHandler(
  filename = function() {
    paste0("Texto_Conclusiones_", input$nombre_lote_conclusiones, "_", format(Sys.Date(), "%Y%m%d"), ".txt")
  },
  content = function(file) {
    req(texto_conclusiones_generado())
    writeLines(texto_conclusiones_generado(), file, useBytes = TRUE)
  }
)
