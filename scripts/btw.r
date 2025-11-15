                      tabPanel("Resumen final y shapefiles", 
                               h3("Resumen Final de Resultados y Exportaciones", class = "fade-in"),
                              
                              fluidRow(
                                # ========== COLUMNA IZQUIERDA: RESÚMENES EJECUTIVOS ==========
                                column(width = 8,
                                       div(class = "card fade-in",
                                           tabsetPanel(
                                             id = "tabset_resumen_final",
                                             
                                             # ===== PESTAÑA 1: CON JERARQUÍA (PRIMERO) =====
                                             tabPanel("🎯 Con Análisis Jerárquico",
                                                      tags$br(),
                                                      div(class = "alert alert-success",
                                                          h5("ℹ️ Análisis con Exclusión Jerárquica", 
                                                             style = "margin-top: 0; font-weight: bold;"),
                                                          p(HTML("Prima <strong>Locación sobre Celdas</strong>, y <strong>Celdas sobre Grillas</strong> para la conclusión final."), 
                                                            style = "margin-bottom: 5px;"),
                                                          p("Evita duplicación: no acusa grillas de celdas completas ni celdas de locaciones completas impactadas.",
                                                            style = "font-size: 0.9em; color: #555; margin-bottom: 0;")
                                                      ),
                                                      
                                                      # Resumen Ejecutivo con Jerarquía
                                                      h5("📊 Resumen Ejecutivo", style = "font-weight: bold; margin-top: 15px;"),
                                                      uiOutput("resumen_unificado_conteos"),
                                                      
                                                      tags$br(),
                                                      
                                                      # Códigos de Elementos con Jerarquía
                                                      h5("📋 Códigos de Elementos impactados", style = "font-weight: bold;"),
                                                      fluidRow(
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("📍 Grillas", style = "color: #d9534f; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_grillas_unificado")
                                                               )),
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("🔲 Celdas", style = "color: #f0ad4e; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_celdas_unificado")
                                                               )),
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("🏢 Locaciones", style = "color: #5bc0de; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_locaciones_impactadas")
                                                               ))
                                                      )
                                             ),
                                             
                                             # ===== PESTAÑA 2: SIN JERARQUÍA =====
                                             tabPanel("📊 Sin Análisis Jerárquico",
                                                      tags$br(),
                                                      div(class = "alert alert-info",
                                                          h5("ℹ️ Análisis Sin Exclusión", 
                                                             style = "margin-top: 0; font-weight: bold;"),
                                                          p("Muestra todos los elementos impactados sin aplicar filtros jerárquicos.",
                                                            style = "margin-bottom: 5px;"),
                                                          p("Puede incluir grillas de celdas completas y celdas de locaciones completas.",
                                                            style = "font-size: 0.9em; color: #555; margin-bottom: 0;")
                                                      ),
                                                      
                                                      # Resumen Ejecutivo sin Jerarquía
                                                      h5("📊 Resumen Ejecutivo", style = "font-weight: bold; margin-top: 15px;"),
                                                      uiOutput("resumen_sin_jerarquia_conteos"),
                                                      
                                                      tags$br(),
                                                      
                                                      # Códigos de Elementos sin Jerarquía
                                                      h5("📋 Códigos de Elementos impactados", style = "font-weight: bold;"),
                                                      fluidRow(
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("📍 Grillas", style = "color: #d9534f; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_grillas_sin_jerarquia")
                                                               )),
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("🔲 Celdas", style = "color: #f0ad4e; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_celdas_sin_jerarquia")
                                                               )),
                                                        column(width = 4,
                                                               div(class = "well well-sm",
                                                                   h6("🏢 Locaciones", style = "color: #5bc0de; font-weight: bold; margin-top: 0;"),
                                                                   uiOutput("lista_locaciones_sin_jerarquia")
                                                               ))
                                                      )
                                             )
                                           )
                                       )
                                ),
                                
                                # ========== COLUMNA DERECHA: BOTONES DE DESCARGA ==========
                                column(width = 4,
                                       div(class = "card fade-in",
                                           h4("📥 Exportaciones", style = "margin-top: 0;"),
                                           
                                           # Botón 1: Reporte Completo
                                           div(style = "margin-bottom: 15px;",
                                               h6("Reporte Completo", style = "font-weight: bold; margin-bottom: 5px;"),
                                               p("Todas las grillas, celdas y locaciones", 
                                                 style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                               downloadButton("descargar_reporte_completo_btn", 
                                                             "Descargar (.xlsx)", 
                                                             class = "btn-success btn-sm btn-block")
                                           ),
                                           
                                           tags$hr(),
                                           
                                           # Botón 2: Solo impactadas (sin jerarquía)
                                           div(style = "margin-bottom: 15px;",
                                               h6("Solo impactadas", style = "font-weight: bold; margin-bottom: 5px;"),
                                               p("Elementos impactados sin filtro jerárquico", 
                                                 style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                               downloadButton("descargar_reporte_solo_impactadas_btn", 
                                                             "Descargar (.xlsx)", 
                                                             class = "btn-warning btn-sm btn-block")
                                           ),
                                           
                                           tags$hr(),
                                           
                                           # Botón 3: impactadas con Jerarquía
                                          div(style = "margin-bottom: 15px;",
                                              h6(
                                                "impactadas con Jerarquía",
                                                style = "font-weight: bold; margin-bottom: 5px;"
                                              ),
                                              p(
                                                "Locaciones > Celdas > Grillas (sin duplicación)",
                                                style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"
                                              ),
                                              downloadButton(
                                                "descargar_reporte_jerarquia_btn",
                                                "Descargar (.xlsx)",
                                                class = "btn-danger btn-sm btn-block"
                                              )
                                          ),
                                          
                                          tags$hr(),
                                          
                                          # Botón 4: Vértices con Jerarquía (NUEVO)
                                          div(style = "margin-bottom: 15px;",
                                              h6("Vértices con Jerarquía", 
                                                 style = "font-weight: bold; margin-bottom: 5px;"),
                                              p("Coordenadas de polígonos por hoja (Grillas, Celdas, Locaciones)", 
                                                style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                              downloadButton("descargar_vertices_jerarquia_btn", 
                                                            "Descargar (.xlsx)", 
                                                            class = "btn-success btn-sm btn-block")
                                          ),
                                          
                                          tags$hr(),
                                          
                                          # Botón 5: Shapefiles
                                           div(style = "margin-bottom: 0;",
                                               h6("Shapefiles (con Jerarquía)", 
                                                  style = "font-weight: bold; margin-bottom: 5px;"),
                                               p("ZIP con 2 shapefiles separados (grillas y celdas)", 
                                                 style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                               downloadButton("descargar_shapefiles_impactados_btn", 
                                                             "Descargar (.zip)", 
                                                             class = "btn-info btn-sm btn-block")
                                           )
                                       )
                                )
                              )
