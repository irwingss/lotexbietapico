# ============================================================================ #
# FUNCIÓN PARA GENERAR TEXTO DE CONCLUSIONES SIGUIENDO PLANTILLA EXACTA
# ============================================================================ #

# Función auxiliar para clasificar y formatear locaciones
clasificar_locaciones <- function(locaciones_vec) {
  if (length(locaciones_vec) == 0) return("")
  
  # Clasificar
  pozos <- locaciones_vec[!grepl("MNF|BAT", locaciones_vec, ignore.case = TRUE)]
  manifolds <- locaciones_vec[grepl("MNF", locaciones_vec, ignore.case = TRUE)]
  baterias <- locaciones_vec[grepl("BAT", locaciones_vec, ignore.case = TRUE)]
  
  # Construir texto
  partes <- c()
  
  if (length(pozos) > 0) {
    partes <- c(partes, paste0("pozos: ", paste(sort(pozos), collapse = ", ")))
  }
  
  if (length(manifolds) > 0) {
    if (length(manifolds) == 1) {
      partes <- c(partes, paste0("manifold: ", manifolds))
    } else {
      partes <- c(partes, paste0("manifolds: ", paste(sort(manifolds), collapse = ", ")))
    }
  }
  
  if (length(baterias) > 0) {
    if (length(baterias) == 1) {
      partes <- c(partes, paste0("batería: ", baterias))
    } else {
      partes <- c(partes, paste0("baterías: ", paste(sort(baterias), collapse = ", ")))
    }
  }
  
  # Unir con "; " y " y " para el último
  if (length(partes) == 1) {
    return(partes[1])
  } else if (length(partes) == 2) {
    return(paste(partes, collapse = "; y "))
  } else {
    return(paste0(paste(partes[-length(partes)], collapse = "; "), "; y ", partes[length(partes)]))
  }
}

generar_texto_conclusiones <- function(muestra, celdas, locaciones, umbral, 
                                       vert_grillas, vert_celdas,
                                       nombre_lote, nombre_empresa, 
                                       area_grilla, lado_grilla,
                                       shp_grillas = NULL, shp_celdas = NULL,
                                       col_area_grillas = NULL, col_area_celdas = NULL) {
  
  # ============ CALCULAR ESTADÍSTICAS ============
  n_total_grillas <- nrow(muestra)
  n_locaciones_total <- length(unique(muestra$LOCACION))
  
  # Grillas que NO superan umbral
  grillas_no_contaminadas <- muestra %>% filter(TPH <= umbral)
  n_grillas_limpias <- nrow(grillas_no_contaminadas)
  locaciones_con_grillas_limpias <- sort(unique(grillas_no_contaminadas$LOCACION))
  n_locs_con_limpias <- length(locaciones_con_grillas_limpias)
  
  # Grillas que SÍ superan umbral
  grillas_contaminadas <- muestra %>% filter(TPH > umbral)
  n_grillas_contaminadas <- nrow(grillas_contaminadas)
  locaciones_con_grillas_contaminadas <- sort(unique(grillas_contaminadas$LOCACION))
  n_locs_con_contaminadas <- length(locaciones_con_grillas_contaminadas)
  
  # ============ GENERAR DETALLE DE PUNTOS CONTAMINADOS POR LOCACIÓN ============
  detalle_puntos_contaminados <- ""
  if (n_grillas_contaminadas > 0) {
    # Agrupar por locación
    puntos_por_loc <- grillas_contaminadas %>%
      group_by(LOCACION) %>%
      summarise(puntos = list(PUNTO), .groups = 'drop')
    
    # Clasificar locaciones
    puntos_por_loc$tipo <- ifelse(grepl("MNF", puntos_por_loc$LOCACION, ignore.case = TRUE), "manifold",
                                   ifelse(grepl("BAT", puntos_por_loc$LOCACION, ignore.case = TRUE), "bateria", "pozo"))
    
    # Ordenar por tipo y luego por locación
    puntos_por_loc <- puntos_por_loc %>%
      arrange(factor(tipo, levels = c("pozo", "manifold", "bateria")), LOCACION)
    
    # Formatear por tipo
    detalle_por_tipo <- list()
    
    for (tipo_actual in c("pozo", "manifold", "bateria")) {
      locs_tipo <- puntos_por_loc %>% filter(tipo == tipo_actual)
      
      if (nrow(locs_tipo) > 0) {
        detalles_tipo <- sapply(1:nrow(locs_tipo), function(i) {
          loc <- locs_tipo$LOCACION[i]
          pts <- locs_tipo$puntos[[i]]
          if (length(pts) == 1) {
            paste0(loc, " (punto de muestro ", pts[1], ")")
          } else {
            paste0(loc, " (puntos de muestro ", paste(pts, collapse = ", "), ")")
          }
        })
        
        # Agregar etiqueta del tipo
        if (tipo_actual == "pozo") {
          if (nrow(locs_tipo) == 1) {
            detalle_por_tipo[[tipo_actual]] <- paste0("pozo: ", paste(detalles_tipo, collapse = "; "))
          } else {
            detalle_por_tipo[[tipo_actual]] <- paste0("pozos: ", paste(detalles_tipo, collapse = "; "))
          }
        } else if (tipo_actual == "manifold") {
          if (nrow(locs_tipo) == 1) {
            detalle_por_tipo[[tipo_actual]] <- paste0("manifold: ", paste(detalles_tipo, collapse = "; "))
          } else {
            detalle_por_tipo[[tipo_actual]] <- paste0("manifolds: ", paste(detalles_tipo, collapse = "; "))
          }
        } else if (tipo_actual == "bateria") {
          if (nrow(locs_tipo) == 1) {
            detalle_por_tipo[[tipo_actual]] <- paste0("batería: ", paste(detalles_tipo, collapse = "; "))
          } else {
            detalle_por_tipo[[tipo_actual]] <- paste0("baterías: ", paste(detalles_tipo, collapse = "; "))
          }
        }
      }
    }
    
    # Unir con "; " y " y " para el último
    if (length(detalle_por_tipo) == 1) {
      detalle_puntos_contaminados <- detalle_por_tipo[[1]]
    } else if (length(detalle_por_tipo) == 2) {
      detalle_puntos_contaminados <- paste(detalle_por_tipo, collapse = "; y ")
    } else {
      detalle_puntos_contaminados <- paste0(
        paste(detalle_por_tipo[-length(detalle_por_tipo)], collapse = "; "),
        "; y ", detalle_por_tipo[[length(detalle_por_tipo)]]
      )
    }
  }
  
  # Grillas contaminadas con jerarquía aplicada
  n_grillas_jerarquia <- if (!is.null(vert_grillas) && nrow(vert_grillas) > 0) {
    length(unique(vert_grillas$COD_GRILLA))
  } else { 0 }
  
  # Celdas contaminadas con jerarquía aplicada
  n_celdas_jerarquia <- if (!is.null(vert_celdas) && nrow(vert_celdas) > 0) {
    length(unique(vert_celdas$COD_UNIC))
  } else { 0 }
  
  # Locaciones contaminadas
  locaciones_contaminadas <- locaciones %>%
    filter(criterio_contaminacion != "No contaminada")
  n_locaciones_contaminadas <- nrow(locaciones_contaminadas)
  
  # ============ IDENTIFICAR PUNTOS EXCLUIDOS POR JERARQUÍA ============
  # Puntos que pertenecen a locaciones contaminadas (excluidos de grillas individuales)
  puntos_en_locs_contaminadas <- ""
  if (n_locaciones_contaminadas > 0) {
    locs_cont_vec <- locaciones_contaminadas$LOCACION
    puntos_excluidos <- grillas_contaminadas %>%
      filter(LOCACION %in% locs_cont_vec) %>%
      arrange(LOCACION, PUNTO)
    
    if (nrow(puntos_excluidos) > 0) {
      puntos_por_loc_excl <- puntos_excluidos %>%
        group_by(LOCACION) %>%
        summarise(puntos = list(PUNTO), .groups = 'drop')
      
      detalles_excl <- sapply(1:nrow(puntos_por_loc_excl), function(i) {
        paste(puntos_por_loc_excl$puntos[[i]], collapse = ", ")
      })
      puntos_en_locs_contaminadas <- paste(detalles_excl, collapse = ", ")
    }
  }
  
  # ============ CALCULAR ÁREAS REALES Y GENERAR LISTAS CON ÁREAS ============
  
  # GRILLAS: Extraer códigos + áreas individuales
  codigos_grillas_jerarquia <- "[NINGUNA]"
  areas_grillas_individuales <- list()
  area_grillas_jerarquia <- 0
  
  if (n_grillas_jerarquia > 0) {
    codigos_grillas_jer <- unique(vert_grillas$COD_GRILLA)
    
    if (!is.null(shp_grillas) && !is.null(col_area_grillas)) {
      # Detectar columna de código de grilla en shapefile
      cols_shp <- names(shp_grillas)
      col_grilla_shp <- cols_shp[which(toupper(cols_shp) %in% c("GRILLA", "COD_GRILLA", "COD_GRILLAS"))][1]
      
      if (!is.na(col_grilla_shp) && col_area_grillas %in% cols_shp) {
        # Filtrar shapefile por códigos de jerarquía
        shp_filtrado <- shp_grillas[toupper(trimws(as.character(shp_grillas[[col_grilla_shp]]))) %in% 
                                     toupper(trimws(as.character(codigos_grillas_jer))), ]
        
        if (nrow(shp_filtrado) > 0) {
          # Extraer código y área de cada grilla
          for (i in 1:nrow(shp_filtrado)) {
            cod <- as.character(shp_filtrado[[col_grilla_shp]][i])
            area_val <- round(as.numeric(shp_filtrado[[col_area_grillas]][i]), 2)
            areas_grillas_individuales[[cod]] <- area_val
          }
          
          # Sumar áreas
          area_grillas_jerarquia <- sum(as.numeric(shp_filtrado[[col_area_grillas]]), na.rm = TRUE)
          
          # Generar lista con códigos + áreas
          codigos_ordenados <- sort(names(areas_grillas_individuales))
          lista_con_areas <- sapply(codigos_ordenados, function(cod) {
            paste0(cod, " (", areas_grillas_individuales[[cod]], " m²)")
          })
          codigos_grillas_jerarquia <- paste(lista_con_areas, collapse = ", ")
        }
      }
    }
    
    # Fallback: sin áreas del shapefile
    if (area_grillas_jerarquia == 0) {
      area_grillas_jerarquia <- n_grillas_jerarquia * area_grilla
      # Lista sin áreas individuales
      codigos_grillas_jerarquia <- paste(sort(codigos_grillas_jer), collapse = ", ")
    }
  }
  
  # CELDAS: Extraer códigos + áreas individuales
  codigos_celdas_jerarquia <- "[NINGUNA]"
  areas_celdas_individuales <- list()
  area_celdas_jerarquia <- 0
  
  if (n_celdas_jerarquia > 0) {
    codigos_celdas_jer <- unique(vert_celdas$COD_UNIC)
    
    if (!is.null(shp_celdas) && !is.null(col_area_celdas)) {
      # Detectar columna de código de celda en shapefile
      cols_shp <- names(shp_celdas)
      col_celda_shp <- cols_shp[which(toupper(cols_shp) %in% c("CELDA", "COD_CELDA", "COD_CELDAS", "COD_UNIC"))][1]
      
      if (!is.na(col_celda_shp) && col_area_celdas %in% cols_shp) {
        # Filtrar shapefile por códigos de jerarquía
        shp_filtrado <- shp_celdas[toupper(trimws(as.character(shp_celdas[[col_celda_shp]]))) %in% 
                                    toupper(trimws(as.character(codigos_celdas_jer))), ]
        
        if (nrow(shp_filtrado) > 0) {
          # Extraer código y área de cada celda
          for (i in 1:nrow(shp_filtrado)) {
            cod <- as.character(shp_filtrado[[col_celda_shp]][i])
            area_val <- round(as.numeric(shp_filtrado[[col_area_celdas]][i]), 2)
            areas_celdas_individuales[[cod]] <- area_val
          }
          
          # Sumar áreas
          area_celdas_jerarquia <- sum(as.numeric(shp_filtrado[[col_area_celdas]]), na.rm = TRUE)
          
          # Generar lista con códigos + áreas
          codigos_ordenados <- sort(names(areas_celdas_individuales))
          lista_con_areas <- sapply(codigos_ordenados, function(cod) {
            paste0(cod, " (", areas_celdas_individuales[[cod]], " m²)")
          })
          codigos_celdas_jerarquia <- paste(lista_con_areas, collapse = ", ")
        }
      }
    }
    
    # Fallback: sin áreas del shapefile
    if (area_celdas_jerarquia == 0) {
      area_celdas_jerarquia <- n_celdas_jerarquia * area_grilla * 3
      # Lista sin áreas individuales
      codigos_celdas_jerarquia <- paste(sort(codigos_celdas_jer), collapse = ", ")
    }
  }
  
  # LOCACIONES: Extraer nombres + áreas individuales (suma de sus celdas)
  locs_contaminadas_nombres <- "[NINGUNA]"
  areas_locaciones_individuales <- list()
  area_locaciones <- 0
  
  if (n_locaciones_contaminadas > 0) {
    locs_contaminadas_vec <- locaciones_contaminadas$LOCACION
    
    if (!is.null(shp_celdas) && !is.null(col_area_celdas)) {
      # Detectar columna de locación en shapefile
      cols_shp <- names(shp_celdas)
      col_loc_shp <- cols_shp[which(toupper(cols_shp) %in% c("LOCACION", "UBICACION", "LOCATION", "LOC"))][1]
      
      if (!is.na(col_loc_shp) && col_area_celdas %in% cols_shp) {
        # Para cada locación, sumar áreas de sus celdas
        for (loc in locs_contaminadas_vec) {
          shp_loc <- shp_celdas[toupper(trimws(as.character(shp_celdas[[col_loc_shp]]))) == toupper(trimws(as.character(loc))), ]
          
          if (nrow(shp_loc) > 0) {
            area_loc <- sum(as.numeric(shp_loc[[col_area_celdas]]), na.rm = TRUE)
            areas_locaciones_individuales[[loc]] <- round(area_loc, 2)
          }
        }
        
        # Área total de locaciones
        area_locaciones <- sum(unlist(areas_locaciones_individuales), na.rm = TRUE)
        
        # Generar lista con nombres + áreas
        if (length(areas_locaciones_individuales) > 0) {
          locs_ordenadas <- sort(names(areas_locaciones_individuales))
          lista_con_areas <- sapply(locs_ordenadas, function(loc) {
            paste0(loc, " (", areas_locaciones_individuales[[loc]], " m²)")
          })
          locs_contaminadas_nombres <- paste(lista_con_areas, collapse = ", ")
        }
      }
    }
    
    # Fallback: sin áreas del shapefile
    if (area_locaciones == 0) {
      area_locaciones <- n_locaciones_contaminadas * 500
      # Lista sin áreas individuales
      locs_contaminadas_nombres <- paste(sort(locs_contaminadas_vec), collapse = ", ")
    }
  }
  
  # ÁREA TOTAL A REMEDIAR
  area_total_remediar <- area_grillas_jerarquia + area_celdas_jerarquia + area_locaciones
  
  # ============ GENERAR TEXTO SIGUIENDO PLANTILLA EXACTA ============
  
  texto <- paste0(
    "Resultados a nivel de rejilla (grilla)\n",
    "\n",
    "Ahora bien, de los resultados de laboratorio del muestreo de suelo realizado por el equipo de supervisión del OEFA, en las ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", n_total_grillas, ") áreas ubicadas en [ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locaciones_total), ") ",
    "locaciones descritas en la Tabla N.º 1. Se aprecia lo siguiente:\n",
    "\n",
    "Las concentraciones de TPH, en [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_limpias, ") áreas ubicadas en las ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_limpias), ") locaciones (no supervisadas anteriormente), ",
    "correspondientes a los ", clasificar_locaciones(locaciones_con_grillas_limpias),
    ", no superaron el nivel de intervención de ", format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, ".\n",
    "\n",
    "Las concentraciones de TPH, en [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_contaminadas, ") áreas ubicada en ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_contaminadas), ") locaciones (no supervisadas anteriormente) ",
    "correspondientes a los pozos: ", detalle_puntos_contaminados, ", ",
    "superan el nivel de intervención de ", format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, ".\n",
    "\n",
    "Para los fines de la supervisión, el punto de muestreo representa un área de ", area_grilla, " m2, ",
    "es decir, un cuadrante de ", lado_grilla, " m de lado cuyo centroide tiene las coordenadas del punto de monitoreo.\n",
    "\n",
    "Considerando que la conclusión, vista más adelante, contempla una jerarquía de Locación sobre Celda sobre Rejilla para la acusación de incumplimiento en la remediación, es decir, solo se sugiere la remediación de grillas que no pertenezcan a celdas completas contaminadas ni locaciones completas contaminadas; y, en la misma línea, solo se sugiere la remediación de celdas que no pertenezcan a locaciones completas contaminadas; con el fin de evitar doble acusación. En consecuencia, a continuación, se presenta un cuadro que detalla el área de la parcela de rejillas cuyo punto muestreo superó el nivel de intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, 
    ", por locación supervisada:\n",
    "\n",
    "Tabla X1. Coordenadas de los vértices del polígono del área de rejillas cuyo punto de muestreo superó el Nivel de Intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, "\n",
    "\n",
    "[PLACE HOLDER TABLA X1]\n",
    "\n",
    "\n",
    "Resultados a nivel de celda\n",
    "\n",
    "Para determinar el estado de contaminación por hidrocarburos totales de petróleo (TPH) en las celdas remediadas, se aplicaron dos enfoques metodológicos complementarios, con base en los criterios establecidos en el Estudio Ambiental del ",
    nombre_lote, ":\n",
    "\n",
    "Promedio ponderado de TPH: Se calculó el promedio ponderado de los valores de TPH correspondientes a los puntos de monitoreo ubicados dentro del polígono de cada celda. Si dicho promedio supera el nivel de intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg, se considera que existe evidencia técnica suficiente para calificar a la celda como contaminada, debiendo ser sujeta a procesos de remediación en su totalidad.\n",
    "Proporción de puntos contaminados: Se estimó la proporción de puntos de monitoreo dentro del polígono de cada celda cuyos valores de TPH superan el umbral de ",
    format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg. Si esta proporción es mayor o igual al 50.0% respecto al total de puntos evaluados en la celda, también se considera que existe evidencia técnica suficiente para clasificarla como contaminada, recomendando su remediación integral.\n",
    "\n",
    "Considerando que la conclusión, vista más adelante, contempla una jerarquía de Locación sobre Celda sobre Rejilla para la acusación de incumplimiento en la remediación, es decir, solo se sugiere la remediación de grillas que no pertenezcan a celdas completas contaminadas ni locaciones completas contaminadas; y, en la misma línea, solo se sugiere la remediación de celdas que no pertenezcan a locaciones completas contaminadas; con el fin de evitar doble acusación. En consecuencia, a continuación, se presenta un cuadro que detalla el área de la parcela de celdas cuyo promedio de muestreo superó el nivel de intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, 
    "o cuya proporción de puntos que supera dicho umbral está sobre el 50%, por locación supervisada:\n",
    "\n",
    "Tabla X2. Coordenadas de los vértices del polígono del área de celdas cuyo promedio ponderado o proporción de puntos contaminados superó el Nivel de Intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, "\n",
    "\n",
    "[PLACE HOLDER TABLA X2]\n",
    "\n",
    "\n",
    "Resultados a nivel de locación\n",
    "\n",
    "Para determinar el estado de contaminación por hidrocarburos totales de petróleo (TPH) en las locaciones remediadas, se aplicaron dos enfoques metodológicos complementarios, con base en los criterios establecidos en el Estudio Ambiental del ",
    nombre_lote, ":\n",
    "\n",
    "Promedio ponderado de TPH: Se calculó el promedio ponderado de los valores de TPH correspondientes a los puntos de monitoreo ubicados dentro del polígono de cada locación. Si dicho promedio supera el nivel de intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg, se considera que existe evidencia técnica suficiente para calificar a la locación como contaminada, debiendo ser sujeta a procesos de remediación en su totalidad.\n",
    "Proporción de puntos contaminados: Se estimó la proporción de puntos de monitoreo dentro de los polígonos de cada locación cuyos valores de TPH superan el umbral de ",
    format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg. Si esta proporción es mayor o igual al 50.0% respecto al total de puntos evaluados en la locación, también se considera que existe evidencia técnica suficiente para clasificarla como contaminada, recomendando su remediación integral.\n",
    "\n",
        "Considerando que la conclusión, vista más adelante, contempla una jerarquía de Locación sobre Celda sobre Rejilla para la acusación de incumplimiento en la remediación, es decir, solo se sugiere la remediación de grillas que no pertenezcan a celdas completas contaminadas ni locaciones completas contaminadas; y, en la misma línea, solo se sugiere la remediación de celdas que no pertenezcan a locaciones completas contaminadas; con el fin de evitar doble acusación. En consecuencia, a continuación, se presenta un cuadro que detalla el área de la parcela de todas las celdas de las locaciones cuyo promedio de muestreo superó el nivel de intervención de intervención ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, 
    "o cuya proporción de puntos que supera dicho umbral está sobre el 50%, por locación supervisada:\n",
    "\n",
    "Tabla X3. Coordenadas de los vértices del polígono del área de celdas de las locaciones cuyo promedio ponderado o proporción de puntos contaminados superó el Nivel de Intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, "\n",
    "\n",
    "[PLACE HOLDER TABLA X3]\n",
    "\n",
    "\n",
    "Resultados globales\n",
    "\n",
    "A fin de evitar duplicidad en las conclusiones y conforme a los criterios establecidos para la evaluación a nivel de rejilla, celda y locación, se adoptaron las siguientes reglas de prelación para la interpretación de los resultados:\n",
    "\n",
    "Prioridad de locaciones sobre celdas o rejillas: En caso se haya determinado la necesidad de remediación integral a nivel de locación, esta conclusión prevalece sobre cualquier resultado de remediación parcial a nivel de celda o rejilla correspondiente. Es decir, se prioriza la remediación de toda la locación, sin necesidad de considerar individualmente otras unidades espaciales contenidas en ella.\n",
    "\n",
    "Prioridad de celdas sobre rejillas: De igual forma, si una celda ha sido clasificada como contaminada y, por tanto, sujeta a remediación, esta determinación se antepone a los resultados de rejillas individuales contenidas dentro de dicha celda que también hayan sido calificadas como contaminadas.\n",
    "\n",
    "En consecuencia, se concluye como sujeto de remediación ", round(area_total_remediar, 2), " m² que constituye:\n",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_grillas_jerarquia), ") rejillas con un área total de ", 
    round(area_grillas_jerarquia, 2), " m² de las ", n_grillas_contaminadas, 
    " descritas en el Cuadro N° 9: ", codigos_grillas_jerarquia,
    if (n_locaciones_contaminadas > 0 && nchar(puntos_en_locs_contaminadas) > 0) 
      paste0("; exceptuando las rejillas de los puntos de monitoreo de la locación ", locs_contaminadas_nombres, ": ", puntos_en_locs_contaminadas, ".") 
    else ".", "\n",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_celdas_jerarquia), ") celda con un área total de ",
    round(area_celdas_jerarquia, 2), " m² de las ", 
    if (!is.null(celdas) && nrow(celdas) > 0) nrow(celdas %>% filter(criterio_contaminacion != "No contaminada")) else "XX",
    " descritas en el Cuadro N°10: ", codigos_celdas_jerarquia,
    if (n_locaciones_contaminadas > 0) paste0("; exceptuando las celdas de la locación ", locs_contaminadas_nombres, ".") else ".", "\n",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locaciones_contaminadas), ") locación completa con un área total de ",
    round(area_locaciones, 2), " m² descrita en el Cuadro N° 11: ", locs_contaminadas_nombres, ".\n",
    "\n",
    "Asimismo, en las siguientes imágenes, se presenta la ubicación espacial de los puntos de muestreo de suelo donde superó el nivel de intervención de ",
    format(umbral, big.mark = ",", decimal.mark = "."), " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, ".\n",
    "\n",
    "Figura X. Plano de ubicación de puntos de muestreo de suelo – EA000\n",
    "[PLACEHOLDER DE PLANOS]\n",
    "\n",
    "En ese orden de ideas, de acuerdo con el análisis antes desarrollado, se concluye lo siguiente:\n",
    "\n",
    nombre_empresa, " cumplió con remediar [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_limpias, ") áreas ubicadas en las ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_limpias), ") locaciones (no supervisadas anteriormente), ",
    "correspondientes a los ", clasificar_locaciones(locaciones_con_grillas_limpias),
    ", no superaron el nivel de intervención de ", format(umbral, big.mark = ",", decimal.mark = "."),
    " mg/kg conforme a lo establecido en el Estudio Ambiental del ", nombre_lote,
    ", las mismas que se pueden observar en los planos anexados al presente informe (anexo N.º 3). Por tanto, corresponde recomendar el archivo del presente extremo del hecho analizado.\n",
    "\n",
    nombre_empresa, " no cumplió con remediar [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_contaminadas, ") áreas ubicada en ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_contaminadas), ") locaciones (no supervisadas anteriormente) ",
    "correspondientes a los pozos: ", detalle_puntos_contaminados, ", ",
    "superan el nivel de intervención de ", format(umbral, big.mark = ",", decimal.mark = "."), 
    " mg/kg establecido en el Estudio Ambiental del ", nombre_lote, ".\n",
    "\n",
    "En las [ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locaciones_total), ") locaciones supervisadas, las áreas por remediar representan un total de ", 
    round(area_total_remediar, 2), " m². Esta área total se divide en ", round(area_grillas_jerarquia, 2), 
    " m² que constituye [ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_grillas_jerarquia), ") rejillas de las ", n_grillas_contaminadas, " descritas en el Cuadro N° 9; ",
    round(area_celdas_jerarquia, 2), " m² que constituye [ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_celdas_jerarquia), 
    ") celda descrita en el Cuadro N° 10; y ", round(area_locaciones, 2), " m² que constituye ", 
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locaciones_contaminadas), ") locación descrita en el Cuadro N°11. ",
    "Por tanto, corresponde recomendar el inicio de un procedimiento administrativo sancionador (PAS) en el presente extremo del hecho analizado.\n",
    "\n",
    "[CONTINUAN DATOS GENERALES DE LAS SUPERVISIONES EN ", toupper(nombre_lote), " HASTA EL INICIO DE CONCLUSIONES]\n",
    "\n",
    "CONCLUSIONES\n",
    nombre_empresa, " cumplió con remediar [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_limpias, ") áreas ubicadas en las ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_limpias), ") locaciones (no supervisadas anteriormente), ",
    "correspondientes a los ", clasificar_locaciones(locaciones_con_grillas_limpias),
    ", no superaron el nivel de intervención de ", format(umbral, big.mark = ",", decimal.mark = "."),
    " mg/kg conforme a lo establecido en el Estudio Ambiental del ", nombre_lote, ".\n",
    "\n",
    nombre_empresa, " no cumplió con remediar [ESCRIBIR_NUMERO_TEXTUAL] (", n_grillas_contaminadas, ") áreas ubicada en ",
    "[ESCRIBIR_NUMERO_TEXTUAL] (", sprintf("%02d", n_locs_con_contaminadas), ") locaciones (no supervisadas anteriormente) ",
    "correspondientes a los ", detalle_puntos_contaminados, ".\n",
    "\n",
    "\n",
    "═══════════════════════════════════════════════════════════════════════\n",
    "NOTAS IMPORTANTES:\n",
    if (!is.null(shp_grillas) && !is.null(shp_celdas)) {
      "- Las áreas fueron calculadas automáticamente desde los shapefiles:\n"
    } else {
      "- ADVERTENCIA: No se cargaron shapefiles. Las áreas son ESTIMACIONES:\n"
    },
    "  · Grillas individuales: ", round(area_grillas_jerarquia, 2), " m²",
    if (is.null(shp_grillas) || is.null(col_area_grillas)) " (estimación basada en área de grilla configurada)\n" else " (calculado desde shapefile)\n",
    "  · Celdas completas: ", round(area_celdas_jerarquia, 2), " m²",
    if (is.null(shp_celdas) || is.null(col_area_celdas)) " (estimación: promedio 3 grillas por celda)\n" else " (calculado desde shapefile)\n",
    "  · Locaciones completas: ", round(area_locaciones, 2), " m²",
    if (is.null(shp_celdas) || is.null(col_area_celdas)) " (estimación: 500 m² por locación)\n" else " (suma de todas sus celdas desde shapefile)\n",
    "  · TOTAL: ", round(area_total_remediar, 2), " m²\n",
    "- Completar [ESCRIBIR_NUMERO_TEXTUAL] con el número escrito en español (catorce, una, dos, etc.)\n",
    "- Los placeholders [PLACE HOLDER TABLA X1], [PLACE HOLDER TABLA X2], [PLACE HOLDER TABLA X3] deben ser reemplazados con las tablas de vértices reales\n",
    "- El placeholder [PLACEHOLDER DE PLANOS] debe ser reemplazado con las figuras/mapas\n",
    "\n",
    "Documento generado automáticamente el ", format(Sys.time(), "%d/%m/%Y %H:%M:%S"), "\n"
  )
  
  return(texto)
}
