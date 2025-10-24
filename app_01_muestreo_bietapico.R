# --- Cargar Paquetes --- #
# Cargar todos los paquetes requeridos para la aplicación
# ---------------------------------------------------------------------------- #
packages <- c(
  "shiny", "shinydashboard", "readxl", "DT", "dplyr", 
  "TeachingSampling", "dbscan", "purrr", "openxlsx", "sf",
  "colourpicker", "uuid"
)

# Cargar todos los paquetes requeridos
lapply(packages, library, character.only = TRUE)
# ---------------------------------------------------------------------------- #

# Cargar funciones y scripts
# ---------------------------------------------------------------------------- #
# NOTA: ESTE bloque carga todas las funciones y parámetros necesarios
# para la ejecución de la app. Se ejecuta una sola vez al inicio.
# ---------------------------------------------------------------------------- #
tryCatch({
  scripts_path <- "scripts"
  params_path <- "Parámetros generales"
  
  # Cargar scripts de funciones (estos no requieren lme4)
  r_scripts <- list.files(path = scripts_path, pattern = "\\.R$", full.names = TRUE, ignore.case = TRUE)
  # Excluir scripts que son para análisis interactivo y no para la app
  # También excluir server-fase5-handlers.R que debe cargarse dentro del servidor
  scripts_a_excluir <- c("Revisión de listado de locaciones.R", "server-fase5-handlers.R")
  r_scripts <- r_scripts[!grepl(paste(scripts_a_excluir, collapse="|"), r_scripts)]
  for (script in r_scripts) {
    print(paste("Cargando script:", script))
    source(script, local = TRUE, encoding = "UTF-8")
  }
  
  # Cargar directamente el archivo RData con los parámetros precalculados
  rdata_path <- file.path(params_path, "parametros.RData")
  print(paste("Cargando parámetros desde:", rdata_path))
  load(rdata_path, envir = environment())
  
  print("Todos los scripts y parámetros han sido cargados exitosamente.")
  
}, error = function(e) {
  # Manejo de errores en caso de que un script falle
  stop(paste("Error al cargar los scripts iniciales:", e$message))
})

# Definir la Interfaz de Usuario (UI)
ui <- navbarPage(
  title = tagList("Diseño Bietápico"),
  header = tagList(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles_v2.css"),
      # Agregar fuente Roboto desde Google Fonts
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap"),
      # Script para aplicar animaciones
      tags$script("
        $(document).on('shiny:connected', function() {
          $('.fade-in').addClass('fade-in');
        });
      "),
      # Script para prevenir scroll automático en fileInput
      tags$script("
        $(document).ready(function() {
          // Prevenir scroll automático cuando se abre el diálogo de archivos
          $('body').on('focus', 'input[type=\"file\"]', function(e) {
            var scrollPos = $(window).scrollTop();
            setTimeout(function() {
              $(window).scrollTop(scrollPos);
            }, 0);
          });
          
          // También prevenir en el cambio
          $('body').on('change', 'input[type=\"file\"]', function(e) {
            var scrollPos = $(window).scrollTop();
            setTimeout(function() {
              $(window).scrollTop(scrollPos);
            }, 0);
          });
        });
      ")
    ),
    # Indicador de simulación activa
    uiOutput("indicador_simulacion")
  ),
  
  # Pestaña 1 - Carga de datos y Análisis
  tabPanel("1. Carga inicial y Percentil", 
           fluidRow(
             column(width = 3, # Columna lateral (30%)
                    wellPanel(class = "fade-in",
                      h3("1A. Cargar Archivo Excel", class = "fade-in"),
                      div(class = "card",
                        fileInput("archivo_excel", "Carga el archivo Excel de celdas preliminares",
                                  accept = c(".xlsx", ".xls"),
                                  buttonLabel = "Examinar...",
                                  placeholder = "Ningún archivo seleccionado"),
                        p(strong("Columnas requeridas:"), "LOCACION, AREA, COD_CELDA"),
                        p(style = "font-size: 11px; color: #666;",
                          icon("info-circle"), " Los nombres de columnas se estandarizan automáticamente. Si no se detectan correctamente, puedes mapear manualmente abajo."),
                        uiOutput("mapeo_columnas_fase1_ui"),
                        tags$hr(),
                        actionButton("cargar_btn", "Cargar datos", 
                                    class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      div(class = "card",
                        textInput("locacion_simular", "Simular eliminación de locación", value = ""),
                        fluidRow(
                          column(width = 6,
                            actionButton("simular_btn", "Simular", class = "btn-warning btn-block")
                          ),
                          column(width = 6,
                            actionButton("revertir_btn", "Revertir", icon = icon("undo"), class = "btn-info btn-block")
                          )
                        )
                      ),
                      tags$hr(),
                      h3("1B. Análisis de Percentiles", class = "fade-in"),
                      div(class = "card",
                        textInput("area_rejilla_input", "Valores de área de rejilla a evaluar:",
                                 value = "1.4, 2.5, 2.88, 3, 3.5, 4, 4.25, 4.5, 5, 6, 7, 7.81, 8, 9"),
                        actionButton("calcular_btn", "Calcular Percentiles", 
                                    class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      uiOutput("opciones_analisis")
                    )
             ),
             column(width = 9, # Área principal (70%)
                    tabsetPanel(id = "tabset_principal",
                      tabPanel("Tabla de Celdas Cargadas", 
                               h3("Vista previa de datos", class = "fade-in"),
                               div(class = "card fade-in",
                                 DTOutput("preview_datos")
                               )),
                      tabPanel("Tabla de Percentiles", 
                               h3("Tabla de Percentiles", class = "fade-in"),
                               div(class = "card fade-in",
                                 DTOutput("tabla_percentiles")
                               )),
                       tabPanel("Revisión de Celdas", 
                               h3("Revisión de Celdas según Umbral", class = "fade-in"),
                               fluidRow(
                                 # Columna izquierda para datos y resumen
                                 column(width = 5,
                                        # Resultados seleccionados estilizados
                                        div(class = "card fade-in",
                                          uiOutput("resultados_estilizados")
                                        ),
                                        
                                        # Resumen de la revisión
                                        div(class = "card fade-in",
                                          uiOutput("resumen_revision")
                                        )
                                 ),
                                 
                                 # Columna derecha para la tabla
                                 column(width = 7,
                                        # Tabla de conteo de celdas por locación
                                        div(class = "card fade-in",
                                          h4("Conteo de Celdas por Locación"),
                                          DTOutput("tabla_conteo_locaciones")
                                        )
                                 )
                               )
                      )
                    )
             )
           )
  ),
  
  # Pestaña 2 - Carga y verificación de marcos
  tabPanel("2. Carga de Marcos",
           fluidRow(
             column(width = 3, # Columna lateral (30%)
                    wellPanel(class = "fade-in",
                      h3("2A. Cargar Archivos", class = "fade-in"),
                      div(class = "card",
                        p(strong("Columnas requeridas:")),
                        p(em("Marco de Celdas:"), " LOCACION, COD_CELDA, PROF"),
                        p(em("Marco de Grillas:"), " LOCACION, COD_CELDA, COD_GRILLA, P_SUPERPOS, ESTE, NORTE, PROF"),
                        p(style = "font-size: 11px; color: #666;",
                          icon("info-circle"), " Los nombres de columnas se estandarizan automáticamente. Si no se detectan correctamente, puedes mapear manualmente abajo.")
                      ),
                      tags$hr(),
                      div(class = "card",
                        div(style = "background-color: #e7f3ff; border-left: 4px solid #0066cc; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 13px; color: #0066cc; margin-bottom: 5px;",
                            icon("table"), " Excel de Marco de CELDAS")
                        ),
                        fileInput("archivo_marco_celdas", "Seleccionar archivo Excel:",
                                  accept = c(".xlsx", ".xls")),
                        uiOutput("mapeo_columnas_marco_celdas_ui"),
                        tags$hr(),
                        
                        div(style = "background-color: #fff9e6; border-left: 4px solid #ff9800; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 13px; color: #ff9800; margin-bottom: 5px;",
                            icon("th"), " Excel de Marco de GRILLAS")
                        ),
                        fileInput("archivo_marco_grillas", "Seleccionar archivo Excel:",
                                  accept = c(".xlsx", ".xls")),
                        uiOutput("mapeo_columnas_marco_grillas_ui"),
                        tags$hr(),
                        
                        actionButton("cargar_marcos_btn", "Cargar marcos", 
                                    class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      h3("2B. Verificación de Marcos", class = "fade-in"),
                      div(class = "card",
                        actionButton("verificar_marcos_btn", "Verificar integridad", 
                                    class = "btn-success btn-block")
                      ),
                      tags$hr(),
                      h3("2C. Adicional: Revisión de Marcos Shapefile", class = "fade-in"),
                      div(class = "card",
                        p(style = "font-size: 13px; color: #555;", 
                          tags$b("Propósito:"), " Validar coherencia espacial entre grillas y celdas usando shapefiles."),
                        p(style = "font-size: 13px; color: #555;", 
                          "Esta herramienta identifica:",
                          tags$ul(
                            tags$li(tags$b("Grillas fuera de celdas:"), " Grillas cuyos centroides caen fuera de cualquier celda"),
                            tags$li(tags$b("Asignación incorrecta:"), " Grillas con código de celda que no corresponde")
                          )
                        ),
                        tags$hr(),
                        
                        div(style = "background-color: #fff9e6; border-left: 4px solid #ff9800; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 13px; color: #ff9800; margin-bottom: 5px;",
                            icon("th"), " Shapefile de marco de GRILLAS")
                        ),
                        fileInput("archivo_shp_grillas_verif", 
                                 "Seleccionar archivo ZIP:", 
                                 accept = ".zip",
                                 placeholder = "Ninguno"),
                        uiOutput("mapeo_columnas_shp_grillas_verif_ui"),
                        tags$hr(),
                        
                        div(style = "background-color: #e7f3ff; border-left: 4px solid #0066cc; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 13px; color: #0066cc; margin-bottom: 5px;",
                            icon("table"), " Shapefile de marco de CELDAS")
                        ),
                        fileInput("archivo_shp_celdas_verif", 
                                 "Seleccionar archivo ZIP:", 
                                 accept = ".zip",
                                 placeholder = "Ninguno"),
                        uiOutput("mapeo_columnas_shp_celdas_verif_ui"),
                        tags$hr(),
                        
                        div(style = "background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 13px; color: #856404; margin-bottom: 5px;",
                            icon("flask"), " OPCIONAL: Excel de Vértices de Áreas Contaminadas (generado como exportable de la Fase 5. 'Análisis de Resultados')")
                        ),
                        fileInput("archivo_contaminadas_excel", 
                                 "Cargar Reporte_SOLO_CONTAMINADAS.xlsx:", 
                                 accept = c(".xlsx", ".xls"),
                                 placeholder = "Ninguno"),
                        div(id = "info_contaminadas",
                          p(style = "font-size: 11px; color: #666; margin-top: -10px;",
                            "Si carga este archivo, el sistema resaltará específicamente las grillas/celdas ",
                            tags$b("contaminadas"), " que tengan problemas espaciales."
                          )
                        ),
                        tags$hr(),
                        
                        actionButton("verificar_espacial_btn", 
                                    "🔍 Ejecutar Verificación Espacial", 
                                    class = "btn-warning btn-block")
                      )
                    )
             ),
             column(width = 9, # Área principal (70%)
                    tabsetPanel(id = "tabset_fase2",
                      tabPanel("Vista Previa", 
                               fluidRow(
                                 column(width = 6,
                                        h3("Marco de Celdas", class = "fade-in"),
                                        div(class = "card fade-in",
                                          DTOutput("preview_marco_celdas")
                                        )),
                                 column(width = 6,
                                        h3("Marco de Grillas", class = "fade-in"),
                                        div(class = "card fade-in",
                                          DTOutput("preview_marco_grillas")
                                        ))
                               )),
                      tabPanel("Verif. de Locaciones", 
                               h3("Verificación de Locaciones", class = "fade-in"),
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Conteo de Celdas por Locación"),
                                          DTOutput("conteo_celdas_locacion"),
                                          downloadButton("download_conteo_celdas", "Descargar XLSX", class = "btn-sm btn-info")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Locaciones sin Celdas"),
                                          verbatimTextOutput("locaciones_sin_celdas"),
                                          downloadButton("download_locaciones_sin_celdas", "Descargar XLSX", class = "btn-sm btn-info"),
                                          uiOutput("resumen_locaciones")
                                        ))
                               )),
                      tabPanel("Verif. de Grillas", 
                               h3("Verificación de Grillas", class = "fade-in"),
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Conteo de Grillas por Celda"),
                                          DTOutput("conteo_grillas_celda"),
                                          downloadButton("download_conteo_grillas", "Descargar XLSX", class = "btn-sm btn-info")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Celdas con menos de 3 Grillas"),
                                          verbatimTextOutput("celdas_pocas_grillas"),
                                          downloadButton("download_celdas_pocas_grillas", "Descargar XLSX", class = "btn-sm btn-info"),
                                          uiOutput("resumen_grillas")
                                        ))
                               )),
                      tabPanel("Verif. Cruzada", 
                               h3("Verificación Cruzada entre Marcos", class = "fade-in"),
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Celdas en marco_celdas pero no en marco_grillas"),
                                          DTOutput("celdas_no_en_grillas"),
                                          downloadButton("download_celdas_no_en_grillas", "Descargar XLSX", class = "btn-sm btn-info"),
                                          uiOutput("sugerencia_celdas_no_en_grillas")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Celdas en marco_grillas pero no en marco_celdas"),
                                          DTOutput("celdas_no_en_marco"),
                                          downloadButton("download_celdas_no_en_marco", "Descargar XLSX", class = "btn-sm btn-info"),
                                          uiOutput("sugerencia_celdas_no_en_marco"),
                                          uiOutput("resumen_verificacion_cruzada")
                                        ))
                               )),
                      tabPanel("Verif. de Profundidades", 
                               h3("Revisión de Profundidades", class = "fade-in"),
                               div(class = "alert alert-info", style = "background-color: #e7f3ff; border-left: 4px solid #0066cc;",
                                 h4(icon("info-circle"), " Reglas de Validación"),
                                 tags$ul(
                                   tags$li(strong("Regla 1 - Consistencia:"), " Todas las grillas de una celda deben tener la misma profundidad"),
                                   tags$li(strong("Regla 2 - Validez:"), " No puede haber profundidades en blanco (NA) o igual a 0")
                                 )
                               ),
                               fluidRow(
                                 column(width = 12,
                                        div(class = "card fade-in",
                                          h4(icon("exclamation-triangle"), " Problema 1: Celdas con Profundidades Inconsistentes"),
                                          p("Celdas cuyas grillas tienen profundidades distintas (violación de Regla 1):"),
                                          uiOutput("resumen_prof_inconsistentes"),
                                          DTOutput("tabla_prof_inconsistentes"),
                                          downloadButton("download_prof_inconsistentes", "Descargar XLSX", class = "btn-sm btn-warning")
                                        ))
                               ),
                               tags$hr(),
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4(icon("ban"), " Problema 2A: Grillas con Profundidad Inválida"),
                                          p("Grillas con profundidad en blanco (NA) o igual a 0 (violación de Regla 2):"),
                                          uiOutput("resumen_grillas_prof_invalida"),
                                          DTOutput("tabla_grillas_prof_invalida"),
                                          downloadButton("download_grillas_prof_invalida", "Descargar XLSX", class = "btn-sm btn-danger")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4(icon("ban"), " Problema 2B: Celdas con Profundidad Inválida"),
                                          p("Celdas con profundidad en blanco (NA) o igual a 0 (violación de Regla 2):"),
                                          uiOutput("resumen_celdas_prof_invalida"),
                                          DTOutput("tabla_celdas_prof_invalida"),
                                          downloadButton("download_celdas_prof_invalida", "Descargar XLSX", class = "btn-sm btn-danger")
                                        ))
                               )),
                      tabPanel("🚨 Grillas Fuera de Celdas", 
                               h3("Identificación de Grillas Fuera de Celdas", class = "fade-in"),
                               div(class = "alert alert-warning",
                                 h4("⚠️ Problema Detectado"),
                                 p("Las siguientes grillas tienen sus centroides FUERA de cualquier polígono de celda. 
                                   Esto indica un error geométrico que debe corregirse."),
                                 hr(),
                                 h5("📊 Resumen de Verificación"),
                                 uiOutput("resumen_grillas_fuera")
                               ),
                               fluidRow(
                                 column(width = 12,
                                        div(class = "card fade-in",
                                          h4("Listado de Grillas Problemáticas"),
                                          DTOutput("tabla_grillas_fuera"),
                                          hr(),
                                          downloadButton("descargar_marco_grillas_limpio_btn", 
                                                        "📥 Descargar Marco de Grillas Limpio (ZIP)", 
                                                        class = "btn-success btn-lg"),
                                          p(style = "margin-top: 10px; font-size: 12px; color: #666;",
                                            "Este archivo ZIP contendrá el shapefile de grillas sin las grillas problemáticas identificadas.")
                                        ))
                               )),
                      tabPanel("🚨 Códigos de Celda Incorrectos", 
                               h3("Verificación de Asignación de Códigos de Celda", class = "fade-in"),
                               div(class = "alert alert-info",
                                 h4("ℹ️ Sobre esta verificación"),
                                 p("Esta herramienta verifica si el código de celda asignado a cada grilla (columna CELDA o COD_CELDA) 
                                   coincide con la celda donde realmente cae el centroide de la grilla."),
                                 p(tags$b("Regla:"), " Una grilla pertenece a la celda donde su centroide cae dentro."),
                                 hr(),
                                 h5("📊 Resumen de Verificación"),
                                 uiOutput("resumen_celdas_mal_asignadas")
                               ),
                               fluidRow(
                                 column(width = 12,
                                        div(class = "card fade-in",
                                          h4("Grillas con Código de Celda Incorrecto"),
                                          DTOutput("tabla_celdas_mal_asignadas"),
                                          p(style = "margin-top: 10px; font-size: 12px; color: #666;",
                                            tags$b("CELDA_ASIGNADA:"), " Código que tiene actualmente en el shapefile", br(),
                                            tags$b("CELDA_REAL:"), " Código de la celda donde realmente cae el centroide", br(),
                                            tags$b("PROBLEMA:"), " Tipo de inconsistencia detectada")
                                        ))
                               )),
                      tabPanel("🔍 Chequeo Vértices Áreas Contaminadas", 
                               h3("Análisis de Grillas/Celdas Contaminadas de Fase 5. Análisis de Resultados", class = "fade-in"),
                               div(class = "alert alert-info",
                                 h4("ℹ️ Sobre este análisis"),
                                 p("Esta pestaña muestra específicamente los problemas espaciales detectados en las ",
                                   tags$b("Áreas Contaminadas"), " según el Excel de Fase 5."),
                                 p(tags$b("Requisito:"), " Debe cargar el archivo ", 
                                   tags$code("Reporte_SOLO_CONTAMINADAS.xlsx"), 
                                   " en la sección izquierda."),
                                 uiOutput("info_carga_contaminadas")
                               ),
                               
                               # Resumen ejecutivo de grillas contaminadas con problemas
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("🚨 Grillas Contaminadas FUERA de Celdas"),
                                          uiOutput("resumen_grillas_contaminadas_fuera"),
                                          hr(),
                                          DTOutput("tabla_grillas_contaminadas_fuera")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("⚠️ Grillas Contaminadas con Código INCORRECTO"),
                                          uiOutput("resumen_grillas_contaminadas_codigo"),
                                          hr(),
                                          DTOutput("tabla_grillas_contaminadas_codigo")
                                        ))
                               ))
                    )
             )
           )
  ),
  
  # Pestaña 3 - Cálculo del tamaño muestral
  tabPanel("3. Cálculo del n muestral",
           fluidRow(
             column(width = 3, # Columna lateral (30%)
                    wellPanel(class = "fade-in",
                      h3("3A. Parámetros de Muestreo", class = "fade-in"),
                      div(class = "card",
                        numericInput("nivel_confianza", "Nivel de confianza (%)", 95, min = 80, max = 99.9, step = 0.1),
                        numericInput("tasa_no_respuesta", "Tasa de no respuesta (%)", 5.75, min = 0, max = 50, step = 0.01),
                        numericInput("margen_error", "Margen de error (% de la media)", 15, min = 1, max = 50, step = 0.1),
                        tags$hr(),
                        actionButton("calcular_n_btn", "Calcular tamaño muestral", 
                                    class = "btn-primary btn-block")
                      )
                    )
             ),
             column(width = 9, # Área principal (70%)
                    tabsetPanel(id = "tabset_fase3",
                      tabPanel("Resultados", 
                               h3("Cálculo del tamaño muestral", class = "fade-in"),
                               fluidRow(
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Resultados del cálculo"),
                                          uiOutput("resultado_n_muestral")
                                        )),
                                 column(width = 6,
                                        div(class = "card fade-in",
                                          h4("Fórmula utilizada"),
                                          withMathJax(uiOutput("formula_n_muestral"))
                                        ))
                               ),
                               div(class = "card fade-in",
                                 h4("Parámetros utilizados en el cálculo"),
                                 verbatimTextOutput("parametros_n_muestral")
                               ))
                    )
             )
           )
  ),
  
  # Pestaña 4 - Muestreo Bietápico
  tabPanel("4. Muestreo Bietápico",
           fluidRow(
             column(width = 3, # Columna lateral (30%)
                    wellPanel(class = "fade-in",
                      h3("4A. Ejecutar Muestreo", class = "fade-in"),
                      div(class = "card",
                        p("Selecciona las celdas y rejillas finales usando los marcos y el tamaño de muestra definidos."),
                        numericInput("seed_muestreo", "Semilla para reproducibilidad:", value = 123, min = 1),
                        actionButton("ejecutar_muestreo_btn", "1. Ejecutar Muestreo Bietápico", 
                                     class = "btn-success btn-block")
                      ),
                      tags$hr(),
                      h3("4B. Generar Códigos", class = "fade-in"),
                      div(class = "card",
                        p("Añade los códigos de campo y colectora a la muestra, optimizando el orden de supervisión."),
                        actionButton("generar_codigos_btn", "2. Generar Códigos de Campo", 
                                     class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      h3("4C. Generar distancias a Pozos", class = "fade-in"),
                      div(class = "card",
                        p("Carga un archivo Excel con pozos de referencia para calcular distancias y añadir altitudes."),
                        p(strong("Columnas requeridas:")),
                        p(em("LOCACION, ESTE, NORTE, ALTITUD")),
                        div(style = "border-left: 4px solid #f0ad4e; background-color: #fff9e6; padding: 10px; margin-bottom: 10px;",
                          p(icon("map-marker-alt"), strong(" 📍 Archivo de Pozos de Referencia"), style = "color: #f0ad4e; margin-bottom: 5px;"),
                          fileInput("archivo_pozos_referencia", "Seleccionar archivo Excel de pozos",
                                    accept = c(".xlsx", ".xls")),
                          uiOutput("mapeo_columnas_pozos_ui"),
                          p(em("💡 El sistema detecta automáticamente las columnas. Revisa y ajusta si es necesario."), 
                            style = "font-size: 10px; color: #856404; margin-top: 5px;")
                        ),
                        actionButton("generar_distancias_btn", "3. Generar Distancias y Altitudes", 
                                     class = "btn-warning btn-block")
                      ),
                      tags$hr(),
                      h3("4D. Exportar Resultados", class = "fade-in"),
                      div(class = "card",
                        p("Descarga la muestra final con códigos en el formato que prefieras."),
                        downloadButton("descargar_shp_btn", "Descargar Shapefile (.zip)", class = "btn-success btn-block"),
                        tags$br(),
                        tags$br(),
                        downloadButton("descargar_muestra_btn", "Descargar Excel (.xlsx)", class = "btn-info btn-block")
                      )
                    )
             ),
             column(width = 9, # Área principal (70%)
                    tabsetPanel(id = "tabset_fase4",
                                tabPanel("Resumen del Muestreo", 
                                         h3("Verificación de la Muestra Final", class = "fade-in"),
                                         fluidRow(
                                           column(width = 6,
                                                  div(class = "card fade-in",
                                                      h4("Estadísticas Generales"),
                                                      DTOutput("tabla_estadisticas_generales")
                                                  )
                                           ),
                                           column(width = 6,
                                                  div(class = "card fade-in",
                                                      h4("Conteo de Rejillas por Locación"),
                                                      DTOutput("tabla_conteo_rejillas_locacion"),
                                                      tags$br(),
                                                      downloadButton("descargar_conteo_rejillas_btn", "Descargar Tabla (.xlsx)", 
                                                                    class = "btn-success btn-sm")
                                                  )
                                           )
                                         )
                                ),
                                tabPanel("Datos clave para el acta/informe",
                                         h3("📊 Información para Actas e Informes", class = "fade-in"),
                                         div(class = "alert alert-info",
                                           h4("ℹ️ Sobre esta sección"),
                                           p("Esta pestaña genera automáticamente el texto en formato Markdown con todos los datos clave del muestreo bietápico, listo para copiar y pegar en actas o informes técnicos."),
                                           p(tags$b("Requisito:"), " Debe ejecutar primero el ", tags$code("Muestreo Bietápico"), " en la columna izquierda.")
                                         ),
                                         div(class = "card fade-in",
                                           fluidRow(
                                             column(width = 12,
                                                    uiOutput("info_datos_clave_disponibles"),
                                                    conditionalPanel(
                                                      condition = "output.datos_clave_disponible",
                                                      tags$hr(),
                                                      div(style = "background-color: #f9f9f9; padding: 15px; border-radius: 5px; border: 1px solid #ddd; margin-bottom: 20px;",
                                                        div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
                                                          h4("📝 Texto generado (Markdown)", style = "margin: 0;"),
                                                          div(
                                                            actionButton("copiar_texto_btn", "📋 Copiar al Portapapeles", 
                                                                        class = "btn-primary btn-sm", 
                                                                        onclick = "copyToClipboard()"),
                                                            tags$style(HTML("
                                                              #copiar_texto_btn { margin-right: 5px; }
                                                            ")),
                                                            downloadButton("descargar_texto_acta_btn", "💾 Descargar .md", class = "btn-success btn-sm")
                                                          )
                                                        ),
                                                        div(style = "background-color: white; padding: 15px; border-radius: 4px; max-height: 600px; overflow-y: auto; font-family: 'Courier New', monospace; font-size: 13px; white-space: pre-wrap; border: 1px solid #ccc;",
                                                          uiOutput("texto_datos_clave_markdown")
                                                        )
                                                      ),
                                                      tags$script(HTML("
                                                        function copyToClipboard() {
                                                          var texto = document.querySelector('#texto_datos_clave_markdown pre');
                                                          if (texto) {
                                                            var range = document.createRange();
                                                            range.selectNode(texto);
                                                            window.getSelection().removeAllRanges();
                                                            window.getSelection().addRange(range);
                                                            document.execCommand('copy');
                                                            window.getSelection().removeAllRanges();
                                                            
                                                            // Mostrar feedback
                                                            var btn = document.getElementById('copiar_texto_btn');
                                                            var originalText = btn.innerHTML;
                                                            btn.innerHTML = '✅ Copiado!';
                                                            btn.classList.add('btn-success');
                                                            btn.classList.remove('btn-primary');
                                                            setTimeout(function() {
                                                              btn.innerHTML = originalText;
                                                              btn.classList.remove('btn-success');
                                                              btn.classList.add('btn-primary');
                                                            }, 2000);
                                                          }
                                                        }
                                                      "))
                                                    )
                                             )
                                           )
                                         )
                                ),
                                tabPanel("Muestra Final", 
                                         h3("Rejillas Seleccionadas", class = "fade-in"),
                                         div(class = "card fade-in",
                                           DTOutput("tabla_muestra_final")
                                         )
                                )
                    )
             )
           )
  ),
  
  # Pestaña 5 - Análisis de Resultados de Laboratorio
  tabPanel("5. Análisis de Resultados",
           fluidRow(
             column(width = 3, # Columna lateral (30%)
                    wellPanel(class = "fade-in",
                      h3("5A. Cargar Datos", class = "fade-in"),
                      div(class = "card",
                        h4("Seleccione el caso de carga:"),
                        radioButtons("caso_carga", NULL,
                          choiceNames = list(
                            tags$div(style = "line-height: 1.5;",
                              tags$div(style = "font-weight: bold; font-size: 15px; color: #0066cc; margin-bottom: 3px;",
                                "📍 MATCHING ESPACIAL"),
                              tags$div(style = "font-size: 13px; color: #555;",
                                "Caso 1: Expedientes antiguos (3 archivos)")
                            ),
                            tags$div(style = "line-height: 1.5;",
                              tags$div(style = "font-weight: bold; font-size: 15px; color: #28a745; margin-bottom: 3px;",
                                "🔗 MATCHING POR CÓDIGOS DE PUNTO"),
                              tags$div(style = "font-size: 13px; color: #555;",
                                "Caso 2: Expedientes recientes (2 archivos)")
                            )
                          ),
                          choiceValues = list("caso1", "caso2"),
                          selected = "caso2"
                        ),
                        tags$hr(),
                        
                        # ARCHIVO OBLIGATORIO - Resultados de Laboratorio
                        div(style = "background-color: #e7f3ff; border-left: 4px solid #0066cc; padding: 12px; margin-bottom: 15px; border-radius: 4px;",
                          tags$div(style = "font-weight: bold; font-size: 14px; color: #0066cc; margin-bottom: 5px;",
                            icon("flask"), " ARCHIVO OBLIGATORIO: Resultados de Laboratorio"),
                          tags$div(style = "font-size: 12px; color: #555;",
                            "📋 Base principal del análisis (REMA/RAR)")
                        ),
                        fileInput("archivo_resultados_lab", "Seleccionar archivo Excel:",
                                  accept = c(".xlsx", ".xls")),
                        uiOutput("mapeo_columnas_lab_ui"),
                        tags$hr(),
                        
                        # CASO 1: Expedientes antiguos
                        conditionalPanel(
                          condition = "input.caso_carga == 'caso1'",
                          h5("📂 Archivos adicionales para Caso 1:", style = "color: #0066cc; margin-top: 10px;"),
                          
                          # Archivo A: Coordenadas
                          div(style = "background-color: #fff9e6; border-left: 4px solid #ff9800; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                            tags$div(style = "font-weight: bold; font-size: 13px; color: #ff9800; margin-bottom: 3px;",
                              icon("map-marker"), " ARCHIVO A: Coordenadas de puntos (tabla de coordenadasdel REMA)"),
                            tags$div(style = "font-size: 11px; color: #666;",
                              "📍 Obligatorio para matching espacial")
                          ),
                          fileInput("archivo_coordenadas", "Seleccionar Excel de coordenadas:",
                                    accept = c(".xlsx", ".xls")),
                          uiOutput("mapeo_columnas_coords_ui"),
                          
                          tags$hr(style = "margin: 15px 0;"),
                          
                          # Archivo B: Shapefile
                          div(style = "background-color: #f0f8ff; border-left: 4px solid #2196f3; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                            tags$div(style = "font-weight: bold; font-size: 13px; color: #2196f3; margin-bottom: 3px;",
                              icon("globe"), " ARCHIVO B: Marco de grillas (Shapefile)"),
                            tags$div(style = "font-size: 11px; color: #666;",
                              "🗺️ Los puntos deben caer DENTRO de las grillas")
                          ),
                          fileInput("archivo_marco_grillas_shp", "Seleccionar ZIP shapefile:",
                                    accept = c(".zip")),
                          uiOutput("mapeo_columnas_marco_shp_ui")
                        ),
                        
                        # CASO 2: Expedientes recientes
                        conditionalPanel(
                          condition = "input.caso_carga == 'caso2'",
                          h5("📂 Archivo adicional para Caso 2:", style = "color: #28a745; margin-top: 10px;"),
                          
                          div(style = "background-color: #e8f5e9; border-left: 4px solid #28a745; padding: 10px; margin-bottom: 10px; border-radius: 4px;",
                            tags$div(style = "font-weight: bold; font-size: 13px; color: #28a745; margin-bottom: 3px;",
                              icon("table"), " Muestra Final (Fase 4)"),
                            tags$div(style = "font-size: 11px; color: #666;",
                              "✅ Ya contiene coordenadas, códigos de grilla, celda, etc.")
                          ),
                          fileInput("archivo_muestra_final", "Seleccionar Excel de muestra final:",
                                    accept = c(".xlsx", ".xls")),
                          uiOutput("mapeo_columnas_muestra_final_ui")
                        ),
                        
                        tags$hr(),
                        textInput("codigo_expediente", "Código de Expediente (opcional)", 
                                 placeholder = "Ej: 0006-5-2025"),
                        tags$hr(),
                        actionButton("cargar_datos_resultados_btn", "Cargar y Unificar Datos", 
                                    class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      h3("5B. Análisis Estadístico", class = "fade-in"),
                      div(class = "card",
                        numericInput("umbral_tph", "Umbral de contaminación TPH (mg/kg)", 
                                    value = 10000, min = 0, step = 100),
                        actionButton("ejecutar_analisis_btn", "Ejecutar Análisis Completo", 
                                    class = "btn-success btn-block")
                      ),
                      tags$hr(),
                      h3("5C. Cargar Shapefiles", class = "fade-in"),
                      div(class = "card",
                        p("Para generar vértices de polígonos contaminados"),
                        fileInput("shp_grillas_upload", "Shapefile de Grillas (.zip)",
                                  accept = c(".zip")),
                        uiOutput("mapeo_columnas_grillas_ui"),
                        tags$hr(),
                        fileInput("shp_celdas_upload", "Shapefile de Celdas (.zip)",
                                  accept = c(".zip")),
                        uiOutput("mapeo_columnas_celdas_ui"),
                        tags$hr(),
                        actionButton("generar_vertices_btn", "Generar Vértices", 
                                    class = "btn-warning btn-block")
                      )
                    )
             ),
             column(width = 9, # Área principal (70%)
                    tabsetPanel(id = "tabset_fase5",
                      tabPanel("Datos Cargados", 
                               h3("Vista Previa de Datos Unificados", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Resumen de carga de datos"),
                                 verbatimTextOutput("resumen_carga_resultados"),
                                 tags$br(),
                                 downloadButton("descargar_muestra_enriquecida_btn", 
                                               "Exportar Muestra Enriquecida (.xlsx)", 
                                               class = "btn-success")
                               ),
                               div(class = "card fade-in",
                                 h4("Muestra Enriquecida (primeras 50 filas)"),
                                 DTOutput("tabla_muestra_enriquecida")
                               )
                      ),
                      tabPanel("🔍 Diagnóstico de Match",
                               conditionalPanel(
                                 condition = "output.diagnostico_match_disponible",
                                 h3("Diagnóstico de Match entre Archivos", class = "fade-in"),
                                 div(class = "alert alert-info",
                                   icon("info-circle"),
                                   strong(" Esta sección muestra el diagnóstico del matching entre archivos."),
                                   p("• Caso 1: Match Lab-Coordenadas + Match Espacial (puntos dentro de grillas)", style = "margin: 5px 0 0 0; font-size: 0.9em;"),
                                   p("• Caso 2: Match Muestra-Laboratorio (identificación de puntos sin resultados)", style = "margin: 0; font-size: 0.9em;")
                                 ),
                                 div(class = "card fade-in",
                                   h4("Resumen del Match"),
                                   verbatimTextOutput("resumen_diagnostico_match"),
                                   tags$br(),
                                   downloadButton("descargar_diagnostico_match_btn", 
                                                 "Descargar Reporte Completo (.txt)", 
                                                 class = "btn-warning")
                                 ),
                                 tags$br(),
                                 div(class = "card fade-in",
                                   h4("⚠️ Puntos Perdidos (No aparecen en análisis)"),
                                   DTOutput("tabla_puntos_perdidos")
                                 ),
                                 tags$br(),
                                 fluidRow(
                                   column(width = 6,
                                     div(class = "card fade-in",
                                       h4("Puntos solo en Muestra Final"),
                                       p("Estos puntos están en tu archivo de Fase 4 pero NO en resultados de laboratorio:", 
                                         style = "color: #856404; background-color: #fff3cd; padding: 8px; border-radius: 4px;"),
                                       verbatimTextOutput("lista_puntos_solo_muestra")
                                     )
                                   ),
                                   column(width = 6,
                                     div(class = "card fade-in",
                                       h4("Puntos solo en Resultados Lab"),
                                       p("Estos puntos están en laboratorio pero NO en muestra final (puede ser normal):", 
                                         style = "color: #004085; background-color: #cce5ff; padding: 8px; border-radius: 4px;"),
                                       verbatimTextOutput("lista_puntos_solo_lab")
                                     )
                                   )
                                 )
                               ),
                               conditionalPanel(
                                 condition = "!output.diagnostico_match_disponible",
                                 div(class = "alert alert-secondary",
                                   icon("info-circle"),
                                   strong(" Diagnóstico no disponible"),
                                   p("El diagnóstico de match estará disponible después de cargar y unificar los datos.", style = "margin-top: 10px;"),
                                   p("Funciona tanto para Caso 1 (Matching Espacial) como para Caso 2 (Matching por Códigos).")
                                 )
                               )
                      ),
                      tabPanel("Análisis Nivel Grilla", 
                               h3("Puntos de Muestreo Contaminados", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Resumen de Análisis"),
                                 verbatimTextOutput("resumen_grillas_contaminadas")
                               ),
                               tags$br(),
                               tabsetPanel(id = "tabset_grillas",
                                 tabPanel("Grillas Contaminadas",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_grillas_contaminadas"),
                                            tags$br(),
                                            downloadButton("descargar_grillas_contaminadas_btn", 
                                                          "Descargar Grillas Contaminadas (.xlsx)", 
                                                          class = "btn-success btn-sm")
                                          )
                                 ),
                                 tabPanel("Todas las Grillas",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_todas_grillas"),
                                            tags$br(),
                                            downloadButton("descargar_todas_grillas_btn", 
                                                          "Descargar Todas las Grillas (.xlsx)", 
                                                          class = "btn-info btn-sm")
                                          )
                                 ),
                                 tabPanel("👻 Puntos Huérfanos",
                                          tags$br(),
                                          conditionalPanel(
                                            condition = "output.diagnostico_match_disponible",
                                            div(class = "alert alert-warning",
                                              icon("exclamation-triangle"),
                                              strong(" PUNTOS HUÉRFANOS: "),
                                              "Estos puntos están en tu Muestra Final (Fase 4) pero NO tienen resultados de laboratorio. ",
                                              strong("NO aparecen en las tablas anteriores.")
                                            ),
                                            div(class = "card fade-in",
                                              h4("Resumen de Puntos Huérfanos"),
                                              verbatimTextOutput("resumen_puntos_huerfanos"),
                                              tags$br(),
                                              p(strong("💡 Posibles causas:"), style = "margin-bottom: 5px;"),
                                              tags$ul(
                                                tags$li("Diferencias en formato de códigos (espacios, caracteres especiales)"),
                                                tags$li("Muestras no enviadas o no analizadas en laboratorio"),
                                                tags$li("Errores de transcripción en códigos de punto"),
                                                tags$li("Muestras aún en proceso de análisis")
                                              )
                                            ),
                                            tags$br(),
                                            div(class = "card fade-in",
                                              h4("Tabla Detallada de Puntos Huérfanos"),
                                              DTOutput("tabla_puntos_huerfanos"),
                                              tags$br(),
                                              fluidRow(
                                                column(width = 6,
                                                       downloadButton("descargar_puntos_huerfanos_excel_btn", 
                                                                     "📥 Descargar Excel (.xlsx)", 
                                                                     class = "btn-warning btn-sm")),
                                                column(width = 6,
                                                       downloadButton("descargar_puntos_huerfanos_txt_btn", 
                                                                     "📄 Descargar Reporte (.txt)", 
                                                                     class = "btn-secondary btn-sm"))
                                              )
                                            )
                                          ),
                                          conditionalPanel(
                                            condition = "!output.diagnostico_match_disponible",
                                            div(class = "alert alert-success",
                                              icon("check-circle"),
                                              strong(" ✅ Sin puntos huérfanos"),
                                              p("Todos los puntos de la muestra final tienen resultados de laboratorio.", 
                                                style = "margin-top: 10px; margin-bottom: 0;"),
                                              p("O bien, estás usando el Caso 1 donde este diagnóstico no aplica.", 
                                                style = "margin-top: 5px; margin-bottom: 0;")
                                            )
                                          )
                                 )
                               )
                      ),
                      tabPanel("Análisis Nivel Celdas", 
                               h3("Análisis Estadístico por Celdas", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Resumen de Análisis"),
                                 verbatimTextOutput("resumen_celdas_analisis")
                               ),
                               tags$br(),
                               tabsetPanel(id = "tabset_celdas",
                                 tabPanel("Celdas Contaminadas",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_celdas_contaminadas"),
                                            tags$br(),
                                            downloadButton("descargar_celdas_contaminadas_btn", 
                                                          "Descargar Celdas Contaminadas (.xlsx)", 
                                                          class = "btn-success btn-sm")
                                          )
                                 ),
                                 tabPanel("Todas las Celdas",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_promedios_celdas"),
                                            tags$br(),
                                            downloadButton("descargar_promedios_celdas_btn", 
                                                          "Descargar Todas las Celdas (.xlsx)", 
                                                          class = "btn-info btn-sm")
                                          )
                                 )
                               )
                      ),
                      tabPanel("Análisis Nivel Locaciones", 
                               h3("Análisis Estadístico por Locaciones", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Resumen de Análisis"),
                                 verbatimTextOutput("resumen_locaciones_analisis")
                               ),
                               tags$br(),
                               tabsetPanel(id = "tabset_locaciones",
                                 tabPanel("Locaciones Contaminadas",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_locaciones_contaminadas"),
                                            tags$br(),
                                            downloadButton("descargar_locaciones_contaminadas_btn", 
                                                          "Descargar Locaciones Contaminadas (.xlsx)", 
                                                          class = "btn-success btn-sm")
                                          )
                                 ),
                                 tabPanel("Todas las Locaciones",
                                          tags$br(),
                                          div(class = "card fade-in",
                                            DTOutput("tabla_promedios_locaciones"),
                                            tags$br(),
                                            downloadButton("descargar_promedios_locaciones_btn", 
                                                          "Descargar Todas las Locaciones (.xlsx)", 
                                                          class = "btn-info btn-sm")
                                          )
                                 )
                               )
                      ),
                      tabPanel("Vértices de Polígonos", 
                               h3("Vértices de Grillas y Celdas Contaminadas", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Estado de Generación de Vértices"),
                                 verbatimTextOutput("estado_vertices")
                               ),
                               tags$br(),
                               tabsetPanel(
                                 id = "tabset_vertices",
                                 
                                 # Sub-pestaña 1: Análisis por separado
                                 tabPanel("📊 Análisis por separado",
                                          tags$br(),
                                          p("Esta vista muestra todos los vértices de grillas y celdas contaminadas sin aplicar exclusiones jerárquicas."),
                                          fluidRow(
                                            column(width = 6,
                                                   div(class = "card fade-in",
                                                     h4("Vértices de Grillas Contaminadas"),
                                                     DTOutput("tabla_vertices_grillas"),
                                                     tags$br(),
                                                     downloadButton("descargar_vertices_grillas_btn", 
                                                                   "Descargar Vértices Grillas (.xlsx)", 
                                                                   class = "btn-primary btn-sm")
                                                   )),
                                            column(width = 6,
                                                   div(class = "card fade-in",
                                                     h4("Vértices de Celdas Contaminadas"),
                                                     DTOutput("tabla_vertices_celdas"),
                                                     tags$br(),
                                                     fluidRow(
                                                       column(width = 6,
                                                              downloadButton("descargar_vertices_celdas_tph_btn", 
                                                                            "Descargar Vértices TPH (.xlsx)", 
                                                                            class = "btn-primary btn-sm")),
                                                       column(width = 6,
                                                              downloadButton("descargar_vertices_celdas_prop_btn", 
                                                                            "Descargar Vértices Prop (.xlsx)", 
                                                                            class = "btn-primary btn-sm"))
                                                     )
                                                   ))
                                          )
                                 ),
                                 
                                 # Sub-pestaña 2: Análisis unificado
                                 tabPanel("🎯 Análisis unificado excluyendo sobreposición",
                                          tags$br(),
                                          div(class = "alert alert-info",
                                            h5("ℹ️ Lógica de Exclusión Jerárquica", style = "margin-top: 0;"),
                                            tags$ul(
                                              tags$li(HTML("<strong>Nivel 1 - Locaciones completas:</strong> Si una locación está contaminada, NO se muestran sus celdas ni grillas individuales.")),
                                              tags$li(HTML("<strong>Nivel 2 - Celdas completas:</strong> Si una celda está contaminada (y su locación NO lo está), NO se muestran sus grillas individuales.")),
                                              tags$li(HTML("<strong>Nivel 3 - Grillas individuales:</strong> Solo se muestran grillas que NO pertenecen a celdas ni locaciones contaminadas completas."))
                                            ),
                                            p(HTML("<strong>Resultado:</strong> Evita duplicación al remediar. No tiene sentido acusar grillas individuales de una celda que ya se va a remediar completa."))
                                          ),
                                          
                                          # Resumen ejecutivo de elementos a remediar
                                          div(class = "alert alert-success",
                                            h5("📊 Resumen de Elementos Sujetos a Remediación", style = "margin-top: 0; font-weight: bold;"),
                                            uiOutput("resumen_unificado_conteos"),
                                            tags$br(),
                                            fluidRow(
                                              column(width = 4,
                                                     div(class = "well well-sm",
                                                       h6("📍 Grillas Contaminadas", style = "color: #d9534f; font-weight: bold;"),
                                                       uiOutput("lista_grillas_unificado")
                                                     )),
                                              column(width = 4,
                                                     div(class = "well well-sm",
                                                       h6("🔲 Celdas Contaminadas", style = "color: #f0ad4e; font-weight: bold;"),
                                                       uiOutput("lista_celdas_unificado")
                                                     )),
                                              column(width = 4,
                                                     div(class = "well well-sm",
                                                       h6("🏢 Locaciones Contaminadas", style = "color: #5bc0de; font-weight: bold;"),
                                                       uiOutput("lista_locaciones_contaminadas")
                                                     ))
                                            )
                                          ),
                                          tags$br(),
                                          
                                          fluidRow(
                                            column(width = 6,
                                                   div(class = "card fade-in",
                                                     h4("Vértices de Grillas Contaminadas (Filtradas)"),
                                                     p("Solo grillas que NO pertenecen a celdas o locaciones contaminadas", 
                                                       style = "font-size: 0.9em; color: #666;"),
                                                     DTOutput("tabla_vertices_grillas_unificado"),
                                                     tags$br(),
                                                     downloadButton("descargar_vertices_grillas_unificado_btn", 
                                                                   "Descargar Vértices Grillas Unificado (.xlsx)", 
                                                                   class = "btn-success btn-sm")
                                                   )),
                                            column(width = 6,
                                                   div(class = "card fade-in",
                                                     h4("Vértices de Celdas Contaminadas (Filtradas)"),
                                                     p("Solo celdas que NO pertenecen a locaciones contaminadas", 
                                                       style = "font-size: 0.9em; color: #666;"),
                                                     DTOutput("tabla_vertices_celdas_unificado"),
                                                     tags$br(),
                                                     downloadButton("descargar_vertices_celdas_unificado_btn", 
                                                                   "Descargar Vértices Celdas Unificado (.xlsx)", 
                                                                   class = "btn-success btn-sm")
                                                   ))
                                          )
                                 )
                               )
                      ),
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
                                                          p("Evita duplicación: no acusa grillas de celdas completas ni celdas de locaciones completas contaminadas.",
                                                            style = "font-size: 0.9em; color: #555; margin-bottom: 0;")
                                                      ),
                                                      
                                                      # Resumen Ejecutivo con Jerarquía
                                                      h5("📊 Resumen Ejecutivo", style = "font-weight: bold; margin-top: 15px;"),
                                                      uiOutput("resumen_unificado_conteos"),
                                                      
                                                      tags$br(),
                                                      
                                                      # Códigos de Elementos con Jerarquía
                                                      h5("📋 Códigos de Elementos Contaminados", style = "font-weight: bold;"),
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
                                                                   uiOutput("lista_locaciones_contaminadas")
                                                               ))
                                                      )
                                             ),
                                             
                                             # ===== PESTAÑA 2: SIN JERARQUÍA =====
                                             tabPanel("📊 Sin Análisis Jerárquico",
                                                      tags$br(),
                                                      div(class = "alert alert-info",
                                                          h5("ℹ️ Análisis Sin Exclusión", 
                                                             style = "margin-top: 0; font-weight: bold;"),
                                                          p("Muestra todos los elementos contaminados sin aplicar filtros jerárquicos.",
                                                            style = "margin-bottom: 5px;"),
                                                          p("Puede incluir grillas de celdas completas y celdas de locaciones completas.",
                                                            style = "font-size: 0.9em; color: #555; margin-bottom: 0;")
                                                      ),
                                                      
                                                      # Resumen Ejecutivo sin Jerarquía
                                                      h5("📊 Resumen Ejecutivo", style = "font-weight: bold; margin-top: 15px;"),
                                                      uiOutput("resumen_sin_jerarquia_conteos"),
                                                      
                                                      tags$br(),
                                                      
                                                      # Códigos de Elementos sin Jerarquía
                                                      h5("📋 Códigos de Elementos Contaminados", style = "font-weight: bold;"),
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
                                           
                                           # Botón 2: Solo Contaminadas (sin jerarquía)
                                           div(style = "margin-bottom: 15px;",
                                               h6("Solo Contaminadas", style = "font-weight: bold; margin-bottom: 5px;"),
                                               p("Elementos contaminados sin filtro jerárquico", 
                                                 style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                               downloadButton("descargar_reporte_solo_contaminadas_btn", 
                                                             "Descargar (.xlsx)", 
                                                             class = "btn-warning btn-sm btn-block")
                                           ),
                                           
                                           tags$hr(),
                                           
                                           # Botón 3: Contaminadas con Jerarquía
                                          div(style = "margin-bottom: 15px;",
                                              h6("Contaminadas con Jerarquía", 
                                                 style = "font-weight: bold; margin-bottom: 5px;"),
                                              p("Locaciones > Celdas > Grillas (sin duplicación)", 
                                                style = "font-size: 0.85em; color: #666; margin-bottom: 8px;"),
                                              downloadButton("descargar_reporte_jerarquia_btn", 
                                                            "Descargar (.xlsx)", 
                                                            class = "btn-danger btn-sm btn-block")
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
                                               downloadButton("descargar_shapefiles_contaminados_btn", 
                                                             "Descargar (.zip)", 
                                                             class = "btn-info btn-sm btn-block")
                                           )
                                       )
                                )
                              )
                     ) 
                    )
             )
           )
  ),
  
  # Pestaña de Resumen de Texto (antes de Errores)
  tabPanel("📄 Texto para el Acta",
           fluidRow(
             column(width = 12,
                    div(class = "card fade-in",
                        h3("Generar texto para el Acta"),
                        p("Este texto utiliza un formato fijo y reemplaza automáticamente los valores dinámicos del área de rejilla, el total de rejillas del marco final y el número de locaciones evaluadas."),
                        actionButton("generar_resumen_btn", "Generar resumen", class = "btn-primary"),
                        tags$hr(),
                        h4("Texto generado:"),
                        div(style = "white-space: pre-wrap;",
                            verbatimTextOutput("resumen_texto")
                        ),
                        tags$br(),
                        downloadButton("descargar_resumen_btn", "Descargar (.txt)", class = "btn-success")
                    )
             )
           )
  ),
  
  # Pestaña de Errores - Para mostrar errores de la aplicación
  tabPanel("⚠️ Errores",
           fluidRow(
             column(width = 12,
                    div(class = "card fade-in",
                        h3("Registro de Errores de la Aplicación", class = "fade-in"),
                        p("Esta pestaña muestra todos los errores que han ocurrido durante la ejecución de la aplicación."),
                        tags$hr(),
                        h4("Errores Recientes:"),
                        div(id = "error-container", style = "max-height: 600px; overflow-y: auto;",
                            verbatimTextOutput("registro_errores")
                        ),
                        tags$hr(),
                        fluidRow(
                          column(width = 6,
                                 actionButton("limpiar_errores_btn", "Limpiar Registro", 
                                             class = "btn-warning", icon = icon("trash"))
                          ),
                          column(width = 6,
                                 downloadButton("descargar_errores_btn", "Descargar Log de Errores", 
                                               class = "btn-info")
                          )
                        )
                    )
             )
           )
  )
)

# Definir la lógica del servidor
server <- function(input, output, session) {
  # Variables reactivas - Fase 1
  marco_celdas_original <- reactiveVal(NULL)
  marco_celdas_backup <- reactiveVal(NULL)  # Para guardar una copia antes de simular
  locacion_simulada <- reactiveVal("")  # Para guardar la locación que se está simulando eliminar
  bd_percentiles_completa <- reactiveVal(NULL)
  umbral_elegido <- reactiveVal(NULL)
  a_rejilla <- reactiveVal(NULL)
  lado_rejilla <- reactiveVal(NULL)
  marco_celdas_filtrado <- reactiveVal(NULL)
  conteo_locaciones <- reactiveVal(NULL)
  columnas_fase1 <- reactiveVal(NULL)  # Para mapeo de columnas
  
  # Variables reactivas - Fase 2
  marco_celdas <- reactiveVal(NULL)
  marco_grillas <- reactiveVal(NULL)
  conteo_celdas_por_locacion <- reactiveVal(NULL)
  conteo_grillas_por_celda <- reactiveVal(NULL)
  locaciones_faltantes <- reactiveVal(NULL)
  celdas_con_pocas_grillas <- reactiveVal(NULL)
  celdas_solo_en_marco_celdas <- reactiveVal(NULL)
  celdas_solo_en_marco_grillas <- reactiveVal(NULL)
  # Variables para revisión de profundidades - Fase 2
  celdas_profundidades_inconsistentes <- reactiveVal(NULL)
  grillas_prof_invalida <- reactiveVal(NULL)
  celdas_prof_invalida <- reactiveVal(NULL)
  # Variables para mapeo de columnas - Fase 2A
  columnas_marco_celdas <- reactiveVal(NULL)
  columnas_marco_grillas <- reactiveVal(NULL)
  # Variables para mapeo de columnas - Fase 2C
  columnas_shp_grillas_verif <- reactiveVal(NULL)
  columnas_shp_celdas_verif <- reactiveVal(NULL)
  
  # Variables reactivas - Fase 2C (Verificación Espacial de Marcos Shapefile)
  shp_grillas_verif <- reactiveVal(NULL)
  shp_celdas_verif <- reactiveVal(NULL)
  centroides_grillas_verif <- reactiveVal(NULL)
  resultado_grillas_fuera <- reactiveVal(NULL)
  resultado_celdas_mal_asignadas <- reactiveVal(NULL)
  # Variables reactivas - Fase 2C (Excel de Contaminadas de Fase 5)
  grillas_contaminadas_f5 <- reactiveVal(NULL)
  celdas_contaminadas_f5 <- reactiveVal(NULL)
  locaciones_contaminadas_f5 <- reactiveVal(NULL)
  
  # Variables reactivas - Fase 4 (Pozos de referencia)
  pozos_referencia <- reactiveVal(NULL)
  datos_finales_con_distancias <- reactiveVal(NULL)

  # Variable reactiva - Resumen de Texto
  texto_resumen <- reactiveVal("")
  
  # Sistema de manejo de errores
  registro_errores_lista <- reactiveVal(list())
  
  # Función para registrar errores
  registrar_error <- function(error_obj, contexto = "") {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    
    # Extraer información detallada del error
    mensaje_error <- ""
    if (is.character(error_obj)) {
      mensaje_error <- error_obj
    } else if (inherits(error_obj, "error")) {
      mensaje_error <- conditionMessage(error_obj)
      if (nchar(mensaje_error) == 0) {
        mensaje_error <- paste("Error de tipo:", class(error_obj)[1])
      }
    } else {
      mensaje_error <- as.character(error_obj)
    }
    
    # Si el mensaje sigue vacío, proporcionar información básica
    if (nchar(mensaje_error) == 0 || mensaje_error == "") {
      mensaje_error <- "Error desconocido - sin mensaje específico"
    }
    
    # Añadir información adicional si está disponible
    if (inherits(error_obj, "error") && !is.null(error_obj$call)) {
      call_info <- deparse(error_obj$call)[1]
      if (nchar(call_info) > 0) {
        mensaje_error <- paste(mensaje_error, "\nLlamada:", call_info)
      }
    }
    
    nuevo_error <- list(
      timestamp = timestamp,
      contexto = contexto,
      mensaje = mensaje_error
    )
    
    errores_actuales <- registro_errores_lista()
    errores_actuales <- append(errores_actuales, list(nuevo_error))
    
    # Mantener solo los últimos 50 errores para evitar problemas de memoria
    if (length(errores_actuales) > 50) {
      errores_actuales <- errores_actuales[(length(errores_actuales) - 49):length(errores_actuales)]
    }
    
    registro_errores_lista(errores_actuales)
  }
  
  # ============================================================================ #
  # OBSERVERS PARA DETECTAR COLUMNAS AL CARGAR ARCHIVOS EXCEL - FASE 1 Y 2     #
  # ============================================================================ #
  
  # Observer para detectar columnas del archivo Excel de celdas preliminares (Fase 1)
  observeEvent(input$archivo_excel, {
    req(input$archivo_excel)
    tryCatch({
      # Leer solo la primera fila para obtener nombres de columnas
      datos <- read_excel(input$archivo_excel$datapath, n_max = 1)
      columnas_fase1(names(datos))
    }, error = function(e) {
      columnas_fase1(NULL)
    })
  })
  
  # Observer para detectar columnas del marco de celdas (Fase 2A)
  observeEvent(input$archivo_marco_celdas, {
    req(input$archivo_marco_celdas)
    tryCatch({
      datos <- read_excel(input$archivo_marco_celdas$datapath, n_max = 1)
      columnas_marco_celdas(names(datos))
    }, error = function(e) {
      columnas_marco_celdas(NULL)
    })
  })
  
  # Observer para detectar columnas del marco de grillas (Fase 2A)
  observeEvent(input$archivo_marco_grillas, {
    req(input$archivo_marco_grillas)
    tryCatch({
      datos <- read_excel(input$archivo_marco_grillas$datapath, n_max = 1)
      columnas_marco_grillas(names(datos))
    }, error = function(e) {
      columnas_marco_grillas(NULL)
    })
  })
  
  # Observer para detectar columnas del shapefile de grillas (Fase 2C)
  observeEvent(input$archivo_shp_grillas_verif, {
    req(input$archivo_shp_grillas_verif)
    tryCatch({
      temp_dir <- file.path(tempdir(), "preview_shp_grillas_verif", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(input$archivo_shp_grillas_verif$datapath, exdir = temp_dir)
      shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
      
      if (length(shp_files) > 0) {
        shp <- st_read(shp_files[1], quiet = TRUE)
        columnas_shp_grillas_verif(names(shp))
      }
    }, error = function(e) {
      columnas_shp_grillas_verif(NULL)
    })
  })
  
  # Observer para detectar columnas del shapefile de celdas (Fase 2C)
  observeEvent(input$archivo_shp_celdas_verif, {
    req(input$archivo_shp_celdas_verif)
    tryCatch({
      temp_dir <- file.path(tempdir(), "preview_shp_celdas_verif", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(input$archivo_shp_celdas_verif$datapath, exdir = temp_dir)
      shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
      
      if (length(shp_files) > 0) {
        shp <- st_read(shp_files[1], quiet = TRUE)
        columnas_shp_celdas_verif(names(shp))
      }
    }, error = function(e) {
      columnas_shp_celdas_verif(NULL)
    })
  })
  
  # Observer para cargar Excel de contaminadas de Fase 5
  observeEvent(input$archivo_contaminadas_excel, {
    req(input$archivo_contaminadas_excel)
    
    tryCatch({
      # Leer las tres hojas del Excel
      grillas_cont <- openxlsx::read.xlsx(input$archivo_contaminadas_excel$datapath, sheet = "Grillas_Contaminadas")
      celdas_cont <- openxlsx::read.xlsx(input$archivo_contaminadas_excel$datapath, sheet = "Celdas_Contaminadas")
      locaciones_cont <- openxlsx::read.xlsx(input$archivo_contaminadas_excel$datapath, sheet = "Locaciones_Contaminadas")
      
      # Estandarizar columnas
      grillas_cont <- estandarizar_columnas(grillas_cont)
      celdas_cont <- estandarizar_columnas(celdas_cont)
      locaciones_cont <- estandarizar_columnas(locaciones_cont)
      
      # Guardar en reactivos
      grillas_contaminadas_f5(grillas_cont)
      celdas_contaminadas_f5(celdas_cont)
      locaciones_contaminadas_f5(locaciones_cont)
      
      # Notificación de éxito
      n_grillas <- nrow(grillas_cont)
      n_celdas <- nrow(celdas_cont)
      n_locaciones <- nrow(locaciones_cont)
      
      showNotification(
        paste0("✅ Excel de contaminadas cargado exitosamente:\n",
               "📍 ", n_grillas, " grillas contaminadas\n",
               "🔲 ", n_celdas, " celdas contaminadas\n",
               "🏢 ", n_locaciones, " locaciones contaminadas"),
        type = "message",
        duration = 6
      )
      
      cat("\n✅ Excel de contaminadas de Fase 5 cargado:\n")
      cat("  - Grillas:", n_grillas, "\n")
      cat("  - Celdas:", n_celdas, "\n")
      cat("  - Locaciones:", n_locaciones, "\n")
      
    }, error = function(e) {
      grillas_contaminadas_f5(NULL)
      celdas_contaminadas_f5(NULL)
      locaciones_contaminadas_f5(NULL)
      
      showNotification(
        paste("❌ Error al cargar Excel de contaminadas:", e$message),
        type = "error",
        duration = 8
      )
      
      registrar_error(e$message, "Carga Excel contaminadas Fase 5")
    })
  })
  
  # Función para cargar los datos cuando se presione el botón
  observeEvent(input$cargar_btn, {
    req(input$archivo_excel)
    
    # Leer el archivo Excel
    tryCatch({
      datos <- read_excel(input$archivo_excel$datapath)
      
      # Si el usuario ha mapeado columnas manualmente, aplicar el mapeo
      if (!is.null(columnas_fase1()) && !is.null(input$col_locacion_fase1)) {
        # Crear un dataframe con las columnas mapeadas
        datos_mapeados <- data.frame(
          LOCACION = datos[[input$col_locacion_fase1]],
          AREA = datos[[input$col_area_fase1]],
          COD_CELDA = datos[[input$col_cod_celda_fase1]]
        )
        
        # Informar al usuario sobre el mapeo aplicado
        showNotification(
          paste0("Mapeo aplicado: ",
                 input$col_locacion_fase1, " → LOCACION, ",
                 input$col_area_fase1, " → AREA, ",
                 input$col_cod_celda_fase1, " → COD_CELDA"),
          type = "message",
          duration = 5
        )
        
        datos <- datos_mapeados
      } else {
        # Si no hay mapeo manual, usar estandarización automática
        datos <- estandarizar_columnas(datos)
      }
      
      # Verificar que existan las columnas requeridas para celdas preliminares
      verificar_columnas_requeridas(datos, c("LOCACION", "AREA", "COD_CELDA"), "archivo de celdas preliminares")
      
      marco_celdas_original(datos) # Guardar en la variable reactiva
      showNotification("Archivo cargado exitosamente", type = "message")
      }, error = function(e) {
        registrar_error(e, "Carga de Archivo Excel")
        showNotification(paste("Error al cargar el archivo:", conditionMessage(e)), type = "error")
      })
  })
  
  # Función para simular la eliminación de una locación
  observeEvent(input$simular_btn, {
    req(marco_celdas_original(), input$locacion_simular)
{{ ... }}
    
    # Verificar que la locación exista
    locacion_a_eliminar <- input$locacion_simular
    datos_actuales <- marco_celdas_original()
    
    if (!locacion_a_eliminar %in% unique(datos_actuales$LOCACION)) {
      showNotification(paste("La locación", locacion_a_eliminar, "no existe en los datos"), type = "error")
      return()
    }
    
    # Guardar una copia de los datos originales antes de simular
    if (locacion_simulada() == "") { # Solo guardar backup si no hay una simulación activa
      marco_celdas_backup(datos_actuales)
    }
    
    # Filtrar los datos para eliminar la locación seleccionada
    datos_filtrados <- datos_actuales %>%
      filter(LOCACION != locacion_a_eliminar)
    
    # Actualizar los datos y guardar la locación simulada
    marco_celdas_original(datos_filtrados)
    locacion_simulada(locacion_a_eliminar)
    
    # Notificar al usuario
    showNotification(
      paste("Simulando sin la locación:", locacion_a_eliminar, 
            "(Eliminadas", nrow(datos_actuales) - nrow(datos_filtrados), "filas)"),
      type = "warning",
      duration = 5
    )
    
    # Limpiar los resultados de percentiles para que se recalculen
    bd_percentiles_completa(NULL)
    umbral_elegido(NULL)
    a_rejilla(NULL)
    lado_rejilla(NULL)
    marco_celdas_filtrado(NULL)
    conteo_locaciones(NULL)
  })
  
  # Función para revertir la simulación
  observeEvent(input$revertir_btn, {
    req(marco_celdas_backup())
    
    # Restaurar los datos originales
    marco_celdas_original(marco_celdas_backup())
    
    # Notificar al usuario
    if (locacion_simulada() != "") {
      showNotification(
        paste("Se ha restaurado la locación:", locacion_simulada()),
        type = "message",
        duration = 5
      )
    } else {
      showNotification("No hay cambios que revertir", type = "warning")
    }
    
    # Limpiar la variable de locación simulada
    locacion_simulada("")
    
    # Limpiar los resultados de percentiles para que se recalculen
    bd_percentiles_completa(NULL)
    umbral_elegido(NULL)
    a_rejilla(NULL)
    lado_rejilla(NULL)
    marco_celdas_filtrado(NULL)
    conteo_locaciones(NULL)
  })
  
  # Indicador de simulación activa
  output$indicador_simulacion <- renderUI({
    if (locacion_simulada() != "") {
      div(class = "card fade-in", style = "background-color: #FFC107; color: #000; padding: 10px; margin-bottom: 10px; text-align: center;",
          icon("exclamation-triangle"), strong("MODO SIMULACIÓN: "), 
          paste("Se ha eliminado temporalmente la locación", locacion_simulada()))
    } else {
      return(NULL)
    }
  })
  
  # ============================================================================ #
  # OUTPUTS PARA MAPEO DE COLUMNAS - FASE 1 Y FASE 2                           #
  # ============================================================================ #
  
  # FASE 1: Mapeo de columnas para celdas preliminares
  output$mapeo_columnas_fase1_ui <- renderUI({
    req(columnas_fase1())
    
    cols <- columnas_fase1()
    cols_upper <- toupper(cols)
    
    # Detectar columnas sugeridas usando patrones
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_area <- c("AREA", "SUPERFICIE", "HECTARES", "Shape_Area")
    patrones_cod_celda <- c("COD_CELDA", "CELDA", "CELL", "COD_UNIC")
    
    # Función auxiliar para detectar columna candidata (usar la que ya existe en el código)
    detectar_col <- function(cols, patrones) {
      cols_upper <- toupper(cols)
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(cols_upper == patron_upper)
        if (length(match_idx) > 0) {
          return(cols[match_idx[1]])
        }
      }
      # Si no hay match exacto, buscar que contenga el patrón
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(grepl(patron_upper, cols_upper))
        if (length(match_idx) > 0) {
          return(cols[match_idx[1]])
        }
      }
      return(cols[1])  # Default: primera columna
    }
    
    col_locacion_sugerida <- detectar_col(cols, patrones_locacion)
    col_area_sugerida <- detectar_col(cols, patrones_area)
    col_cod_celda_sugerida <- detectar_col(cols, patrones_cod_celda)
    
    # Verificar columnas críticas
    tiene_locacion <- any(grepl("LOCACION|LOCATION|LOC", cols_upper))
    tiene_area <- any(grepl("AREA|SUPERFICIE", cols_upper))
    tiene_cod_celda <- any(grepl("CELDA|CELL|COD_CELDA", cols_upper))
    
    mensaje_advertencia <- if (!tiene_locacion || !tiene_area || !tiene_cod_celda) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        if (!tiene_locacion) "No se detectó columna 'LOCACION'. " else "",
        if (!tiene_area) "No se detectó columna 'AREA'. " else "",
        if (!tiene_cod_celda) "No se detectó columna 'COD_CELDA'. " else "",
        tags$br(),
        "Columnas disponibles: ", paste(head(cols, 5), collapse = ", "),
        if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas correctamente"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #0066cc; margin-bottom: 5px;"),
      selectInput("col_locacion_fase1", "Columna LOCACION:", choices = cols, selected = col_locacion_sugerida),
      selectInput("col_area_fase1", "Columna AREA:", choices = cols, selected = col_area_sugerida),
      selectInput("col_cod_celda_fase1", "Columna COD_CELDA:", choices = cols, selected = col_cod_celda_sugerida)
    )
  })
  
  # FASE 2A: Mapeo de columnas para marco de celdas
  output$mapeo_columnas_marco_celdas_ui <- renderUI({
    req(columnas_marco_celdas())
    
    cols <- columnas_marco_celdas()
    cols_upper <- toupper(cols)
    
    # Función auxiliar para detectar columna
    detectar_col <- function(cols, patrones) {
      cols_upper <- toupper(cols)
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(cols_upper == patron_upper)
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(grepl(patron_upper, cols_upper))
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      return(cols[1])
    }
    
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_cod_celda <- c("COD_CELDA", "CELDA", "CELL", "COD_UNIC")
    patrones_prof <- c("PROF", "PROFUNDIDAD", "DEPTH", "PROF_MIN")
    
    col_locacion_sug <- detectar_col(cols, patrones_locacion)
    col_cod_celda_sug <- detectar_col(cols, patrones_cod_celda)
    col_prof_sug <- detectar_col(cols, patrones_prof)
    
    tiene_locacion <- any(grepl("LOCACION|LOCATION|LOC", cols_upper))
    tiene_cod_celda <- any(grepl("CELDA|CELL|COD_CELDA", cols_upper))
    
    mensaje <- if (!tiene_locacion || !tiene_cod_celda) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"), strong(" ADVERTENCIA: "),
        if (!tiene_locacion) "No se detectó 'LOCACION'. " else "",
        if (!tiene_cod_celda) "No se detectó 'COD_CELDA'. " else "",
        tags$br(), "Columnas: ", paste(head(cols, 5), collapse = ", "), if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas correctamente")
    }
    
    tagList(
      mensaje,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #0066cc; margin-bottom: 5px;"),
      selectInput("col_locacion_marco_celdas", "Columna LOCACION:", choices = cols, selected = col_locacion_sug),
      selectInput("col_cod_celda_marco_celdas", "Columna COD_CELDA:", choices = cols, selected = col_cod_celda_sug),
      selectInput("col_prof_marco_celdas", "Columna PROF (opcional):", choices = c("(ninguna)", cols), selected = col_prof_sug)
    )
  })
  
  # FASE 2A: Mapeo de columnas para marco de grillas
  output$mapeo_columnas_marco_grillas_ui <- renderUI({
    req(columnas_marco_grillas())
    
    cols <- columnas_marco_grillas()
    cols_upper <- toupper(cols)
    
    detectar_col <- function(cols, patrones) {
      cols_upper <- toupper(cols)
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(cols_upper == patron_upper)
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(grepl(patron_upper, cols_upper))
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      return(cols[1])
    }
    
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_cod_celda <- c("COD_CELDA", "CELDA", "CELL", "COD_UNIC")
    patrones_cod_grilla <- c("COD_GRILLA", "GRILLA", "GRID", "COD_GRILL")
    patrones_este <- c("ESTE", "EAST", "X", "COORD_X", "EASTING")
    patrones_norte <- c("NORTE", "NORTH", "Y", "COORD_Y", "NORTHING")
    patrones_prof <- c("PROF", "PROFUNDIDAD", "DEPTH", "PROF_MIN")
    patrones_p_superpos <- c("P_SUPERPOS", "SUPERPOS", "SUPERPOSICION", "P_SUPERPOSICION", "OVERLAP")
    
    col_locacion_sug <- detectar_col(cols, patrones_locacion)
    col_cod_celda_sug <- detectar_col(cols, patrones_cod_celda)
    col_cod_grilla_sug <- detectar_col(cols, patrones_cod_grilla)
    col_este_sug <- detectar_col(cols, patrones_este)
    col_norte_sug <- detectar_col(cols, patrones_norte)
    col_prof_sug <- detectar_col(cols, patrones_prof)
    col_p_superpos_sug <- detectar_col(cols, patrones_p_superpos)
    
    tiene_coords <- any(grepl("ESTE|EAST|X", cols_upper)) && any(grepl("NORTE|NORTH|Y", cols_upper))
    tiene_grilla <- any(grepl("GRILL|GRID", cols_upper))
    
    mensaje <- if (!tiene_coords || !tiene_grilla) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"), strong(" ADVERTENCIA: "),
        if (!tiene_coords) "No se detectaron coordenadas ESTE/NORTE. " else "",
        if (!tiene_grilla) "No se detectó 'COD_GRILLA'. " else "",
        tags$br(), "Columnas: ", paste(head(cols, 5), collapse = ", "), if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas correctamente")
    }
    
    tagList(
      mensaje,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #0066cc; margin-bottom: 5px;"),
      selectInput("col_locacion_marco_grillas", "Columna LOCACION:", choices = cols, selected = col_locacion_sug),
      selectInput("col_cod_celda_marco_grillas", "Columna COD_CELDA:", choices = cols, selected = col_cod_celda_sug),
      selectInput("col_cod_grilla_marco_grillas", "Columna COD_GRILLA:", choices = cols, selected = col_cod_grilla_sug),
      selectInput("col_p_superpos_marco_grillas", "Columna P_SUPERPOS:", choices = cols, selected = col_p_superpos_sug),
      selectInput("col_este_marco_grillas", "Columna ESTE:", choices = cols, selected = col_este_sug),
      selectInput("col_norte_marco_grillas", "Columna NORTE:", choices = cols, selected = col_norte_sug),
      selectInput("col_prof_marco_grillas", "Columna PROF:", choices = cols, selected = col_prof_sug)
    )
  })
  
  # FASE 2C: Mapeo de columnas para shapefile de grillas (verificación)
  output$mapeo_columnas_shp_grillas_verif_ui <- renderUI({
    req(columnas_shp_grillas_verif())
    
    cols <- columnas_shp_grillas_verif()
    cols_upper <- toupper(cols)
    
    detectar_col <- function(cols, patrones) {
      cols_upper <- toupper(cols)
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(cols_upper == patron_upper)
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(grepl(patron_upper, cols_upper))
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      return(cols[1])
    }
    
    patrones_grilla <- c("COD_GRILLA", "GRILLA", "GRID", "COD_GRILL")
    patrones_celda <- c("COD_CELDA", "CELDA", "CELL", "COD_UNIC")
    
    col_grilla_sug <- detectar_col(cols, patrones_grilla)
    col_celda_sug <- detectar_col(cols, patrones_celda)
    
    tiene_grilla <- any(grepl("GRILL|GRID", cols_upper))
    
    mensaje <- if (!tiene_grilla) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"), strong(" ADVERTENCIA: "),
        "No se detectó columna de GRILLA. ",
        tags$br(), "Columnas: ", paste(head(cols, 5), collapse = ", "), if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas")
    }
    
    tagList(
      mensaje,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #ff9800; margin-bottom: 5px;"),
      selectInput("col_grilla_shp_verif", "Columna GRILLA/COD_GRILLA:", choices = cols, selected = col_grilla_sug),
      selectInput("col_celda_shp_grillas_verif", "Columna CELDA (opcional):", choices = c("(ninguna)", cols), selected = col_celda_sug)
    )
  })
  
  # FASE 2C: Mapeo de columnas para shapefile de celdas (verificación)
  output$mapeo_columnas_shp_celdas_verif_ui <- renderUI({
    req(columnas_shp_celdas_verif())
    
    cols <- columnas_shp_celdas_verif()
    cols_upper <- toupper(cols)
    
    detectar_col <- function(cols, patrones) {
      cols_upper <- toupper(cols)
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(cols_upper == patron_upper)
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      for (patron in patrones) {
        patron_upper <- toupper(patron)
        match_idx <- which(grepl(patron_upper, cols_upper))
        if (length(match_idx) > 0) return(cols[match_idx[1]])
      }
      return(cols[1])
    }
    
    patrones_celda <- c("COD_CELDA", "CELDA", "CELL", "COD_UNIC")
    
    col_celda_sug <- detectar_col(cols, patrones_celda)
    
    tiene_celda <- any(grepl("CELDA|CELL", cols_upper))
    
    mensaje <- if (!tiene_celda) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"), strong(" ADVERTENCIA: "),
        "No se detectó columna de CELDA. ",
        tags$br(), "Columnas: ", paste(head(cols, 5), collapse = ", "), if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas")
    }
    
    tagList(
      mensaje,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #ff9800; margin-bottom: 5px;"),
      selectInput("col_celda_shp_verif", "Columna CELDA/COD_CELDA:", choices = cols, selected = col_celda_sug)
    )
  })
  
  # Mostrar la vista previa de los datos
  output$preview_datos <- renderDT({
    req(marco_celdas_original())
    datatable(marco_celdas_original(), 
              options = list(pageLength = 12, 
                            scrollX = TRUE,
                            autoWidth = TRUE))
  })
  
  # Función para calcular la tabla de percentiles
  observeEvent(input$calcular_btn, {
    req(marco_celdas_original())
    
    tryCatch({
      # Verificar si existen las variables necesarias
      if (!exists("base_tph_umbral_fil")) {
        # Si no existe, crear datos simulados para demostración
        base_tph_umbral_fil <<- data.frame(
          TPH = rnorm(100, mean = 500, sd = 100),
          locacion = sample(LETTERS[1:10], 100, replace = TRUE)
        )
        showNotification("Usando datos simulados para TPH", type = "warning")
      }
      
      if (!exists("DEFF_extended")) {
        DEFF_extended <<- 1.5  # Valor simulado
        showNotification("Usando valor simulado para DEFF_extended", type = "warning")
      }
      
      # Obtener los valores de area_rejilla del input
      area_rejilla_valores <- as.numeric(unlist(strsplit(input$area_rejilla_input, "[,\\s]+")))
      
      # Crear la función empírica de distribución acumulada
      F_empirica <- ecdf(marco_celdas_original()$AREA)
      
      # Crear la tabla desde area_rejilla
      bd_percentiles <- data.frame(opcion = 1:length(area_rejilla_valores),
                                  area_rejilla = area_rejilla_valores) %>% 
        dplyr::mutate(area_celda = area_rejilla * 3,
               percentil = F_empirica(area_celda) * 100)
      
      # Función de calculo de n basado en rejillas y celdas
      calculo_n <- function(celda, rejilla) {
        Z <- 1.96 
        TNR <- 0.0575 
        med <- mean(base_tph_umbral_fil$TPH, na.rm = TRUE)
        e <- 0.15 * med 
        σ <- sd(base_tph_umbral_fil$TPH, na.rm = TRUE) 
        N <- marco_celdas_original() %>% 
          filter(AREA >= celda) %>% 
          mutate(rejillas_que_contiene = floor(AREA/rejilla)) %>% 
          pull(rejillas_que_contiene) %>% 
          sum()
        muestra <- round(((N * Z ^ 2 * σ ^ 2) / (e ^ 2 * (N - 1) + Z ^ 2 * σ ^ 2)) * (1 / (1 - TNR)) * DEFF_extended)
        return(muestra)
      }
      
      # Función de celdas que se van
      celdas_sevan <- function(marco, umbral_elegido) {
        conteo <- marco %>% 
          filter(AREA >= umbral_elegido) %>% 
          pull(LOCACION) %>% 
          unique() %>% 
          length()
        return(conteo)
      }
      
      # Calcular n_estimado y Locaciones_remanentes
      bd_percentiles <- bd_percentiles %>% 
        dplyr::rowwise() %>% 
        dplyr::mutate(n_estimado = tryCatch({
          calculo_n(area_celda, area_rejilla)
        }, error = function(e) {
          NA_integer_
        })) %>% 
        as.data.frame() %>% 
        dplyr::ungroup()
      
      bd_percentiles <- bd_percentiles %>% 
        dplyr::rowwise() %>% 
        dplyr::mutate(Locaciones_remanentes = tryCatch({
          celdas_sevan(marco_celdas_original(), area_celda)
        }, error = function(e) {
          NA_integer_
        })) %>% 
        dplyr::ungroup()
        
      # Redondear valores con 2 decimales, excepto columnas de números enteros
      bd_percentiles <- bd_percentiles %>% 
        dplyr::mutate(
          percentil = round(percentil, 2),
          area_celda = round(area_celda, 2),
          area_rejilla = round(area_rejilla, 2)
        ) %>% 
        # Reordenar las columnas en el orden solicitado
        dplyr::select(opcion, area_rejilla, area_celda, percentil, n_estimado, Locaciones_remanentes)
      
      # Guardar la tabla en la variable reactiva
      bd_percentiles_completa(bd_percentiles)
      
      # Mostrar notificación
      showNotification("Tabla de percentiles calculada exitosamente", type = "message")
      
      # Cambiar a la pestaña de Tabla de Percentiles
      updateTabsetPanel(session, "tabset_principal", selected = "Tabla de Percentiles")
      
    }, error = function(e) {
      showNotification(paste("Error al calcular percentiles:", e$message), type = "error")
    })
  })
  
  # Mostrar la tabla de percentiles
  output$tabla_percentiles <- renderDT({
    req(bd_percentiles_completa())
    datatable(bd_percentiles_completa(), 
              options = list(
                pageLength = 20, 
                scrollX = TRUE,
                autoWidth = FALSE, # Cambiar a FALSE para evitar ajuste automático
                fixedHeader = TRUE, # Fijar encabezados
                columnDefs = list(
                  list(targets = c(1, 2, 3), # Columnas percentil, area_celda, area_rejilla (0-indexado)
                       render = JS("function(data, type, row, meta) { return type === 'display' ? parseFloat(data).toFixed(2) : data; }")
                  ),
                  # Definir anchos fijos para cada columna
                  list(targets = 0, width = '60px'), # opcion
                  list(targets = 1, width = '100px'), # area_rejilla
                  list(targets = 2, width = '100px'), # area_celda
                  list(targets = 3, width = '100px'), # percentil
                  list(targets = 4, width = '100px'), # n_estimado
                  list(targets = 5, width = '150px')  # Locaciones_remanentes
                ),
                # Alinear correctamente los encabezados de columnas
                headerCallback = JS(
                  "function(thead, data, start, end, display) {",
                  "  $(thead).find('th').css('text-align', 'center');",
                  "  $(thead).find('th').css('vertical-align', 'middle');",
                  "}"
                ),
                # Comprimir la altura de las filas
                rowCallback = JS(
                  "function(row, data) {",
                  "  $(row).css('line-height', '80%');",
                  "  $(row).css('padding-top', '2px');",
                  "  $(row).css('padding-bottom', '2px');",
                  "  $(row).find('td').css('text-align', 'center');", # Centrar contenido de celdas
                  "}"
                )
              ),
              selection = 'single')
  })
  
  # Generar las opciones de selección
  output$opciones_analisis <- renderUI({
    req(bd_percentiles_completa())
    
    # Crear el título dinámico con el rango entre paréntesis
    titulo_input <- paste0("Seleccionar opción (entre 1 y ", nrow(bd_percentiles_completa()), "):")
    
    tagList(
      textInput("fila_seleccionada", titulo_input, 
                value = "10"), # Por defecto seleccionamos la fila 10
      actionButton("confirmar_seleccion", "Confirmar selección", 
                   class = "btn-success btn-block")
    )
  })
  
  # Actualizar valores cuando se confirma la selección
  observeEvent(input$confirmar_seleccion, {
    req(bd_percentiles_completa(), input$fila_seleccionada, marco_celdas_original())
    
    # Obtener la fila seleccionada y validar
    fila_texto <- input$fila_seleccionada
    
    # Verificar si es un número válido
    if(!grepl("^\\d+$", fila_texto)) {
      showNotification("Por favor, ingrese un número entero válido", type = "error")
      return()
    }
    
    # Convertir a número
    fila <- as.numeric(fila_texto)
    
    # Verificar que esté dentro del rango válido
    if(fila < 1 || fila > nrow(bd_percentiles_completa())) {
      showNotification(paste("Por favor, ingrese un número entre 1 y", nrow(bd_percentiles_completa())), type = "error")
      return()
    }
    
    # Extraer los valores como escalares
    area_celda_valor <- as.numeric(bd_percentiles_completa()[fila, "area_celda"])
    
    # Guardar el umbral elegido
    umbral_elegido(area_celda_valor)
    
    # Calcular a_rejilla
    a_rejilla_valor <- area_celda_valor / 3
    a_rejilla(a_rejilla_valor)
    
    # Calcular el lado de la rejilla
    lado_rejilla(sqrt(a_rejilla_valor))
    
    # Mostrar notificación
    showNotification("Selección confirmada. Valores actualizados.", type = "message")
    
    # Ejecutar automáticamente la revisión de celdas
    tryCatch({
      # Identificar celdas que se van (por debajo del umbral)
      celdas_que_se_van <- marco_celdas_original() %>% 
        filter(AREA < area_celda_valor) %>% 
        pull(COD_CELDA) %>% 
        unique()
      
      # Filtrar el marco de celdas
      pre_marco_celdas <- marco_celdas_original() %>%
        filter(!COD_CELDA %in% celdas_que_se_van)
      
      # Guardar el marco filtrado
      marco_celdas_filtrado(pre_marco_celdas)
      
      # Contar celdas por locación y calcular estadísticas de área
      conteo_por_locacion <- pre_marco_celdas %>% 
        group_by(LOCACION) %>%
        summarise(
          n = n(),
          Min_Area = round(min(AREA, na.rm = TRUE),2),
          Max_Area = round(max(AREA, na.rm = TRUE), 2),
          Promed_Area = round(mean(AREA, na.rm = TRUE), 2)
        ) %>%
        arrange(n)
      
      # Guardar el conteo
      conteo_locaciones(conteo_por_locacion)
      
      # Cambiar a la pestaña de Revisión de Celdas
      updateTabsetPanel(session, "tabset_principal", selected = "Revisión de Celdas")
      
    }, error = function(e) {
      showNotification(paste("Error al revisar celdas:", e$message), type = "error")
    })
  })
  
  # Mostrar los resultados seleccionados con estilo mejorado
  output$resultados_estilizados <- renderUI({
    req(umbral_elegido(), a_rejilla(), lado_rejilla())
    
    # Convertir a valores escalares
    umbral <- as.numeric(umbral_elegido())
    area <- as.numeric(a_rejilla())
    lado <- as.numeric(lado_rejilla())
    
    tagList(
      h4("Valores Seleccionados"),
      tags$div(
        tags$p(
          "", 
          tags$span(style = "color: green; font-weight: bold; font-size: 100%;", "Área de celda elegida (m2): "), 
          tags$strong(format(umbral, digits = 6))
        ),
        tags$p(
          "Área de rejilla (m2): ", 
          tags$strong(format(area, digits = 6))
        ),
        tags$p(
          "Lado (raíz cudrada del área de rejilla, m): ", 
          tags$strong(format(lado, digits = 6))
        )
      )
    )
  })
  
  # Mantener la versión anterior para compatibilidad
  output$resultados_seleccionados <- renderPrint({
    req(umbral_elegido(), a_rejilla(), lado_rejilla())
    
    # Convertir a valores escalares para evitar problemas con cat()
    umbral <- as.numeric(umbral_elegido())
    area <- as.numeric(a_rejilla())
    lado <- as.numeric(lado_rejilla())
    
    cat("Área de la celda:", format(umbral, digits = 6), "\n")
    cat("Área de rejilla:", format(area, digits = 6), "\n")
    cat("Lado de la rejilla:", format(lado, digits = 6), "\n")
  })
  
  # Mantener ESTE bloque vacío para referencia futura
  # La funcionalidad de revisión de celdas ahora está integrada en el evento confirmar_seleccion
  # observeEvent(input$revisar_celdas_btn, { ... })
  
  # Mostrar resumen de la revisión
  output$resumen_revision <- renderUI({
    req(marco_celdas_original(), marco_celdas_filtrado(), conteo_locaciones())
    
    # Calcular estadísticas
    total_locaciones_original <- length(unique(marco_celdas_original()$LOCACION))
    total_locaciones_filtrado <- length(unique(marco_celdas_filtrado()$LOCACION))
    total_celdas_original <- nrow(marco_celdas_original())
    total_celdas_filtrado <- nrow(marco_celdas_filtrado())    
    
    # Identificar locaciones sin celdas después del filtrado
    locaciones_originales <- unique(marco_celdas_original()$LOCACION)
    locaciones_filtradas <- unique(marco_celdas_filtrado()$LOCACION)
    locaciones_sin_celdas <- setdiff(locaciones_originales, locaciones_filtradas)
    
    # Verificar si hay locaciones con exactamente una celda
    locaciones_con_una_celda <- conteo_locaciones() %>% 
      filter(n == 1) %>% 
      nrow() > 0
    
    # Crear el resumen
    tagList(
      h4("Resumen de la Revisión"),
      p(paste("Total de locaciones en el marco original:", total_locaciones_original)),
      p(paste("Total de locaciones en el marco filtrado:", total_locaciones_filtrado)),
      p(paste("Total de celdas en el marco original:", total_celdas_original)),
      p(paste("Total de celdas en el marco filtrado:", total_celdas_filtrado)),
      p(paste("Celdas eliminadas:", total_celdas_original - total_celdas_filtrado)),
      
      if(length(locaciones_sin_celdas) > 0) {
        tagList(
          tags$div(style = "color: red; font-weight: bold;",
                   "ADVERTENCIA: Las siguientes locaciones se quedaron sin celdas:"),
          tags$ul(
            lapply(locaciones_sin_celdas, function(loc) {
              tags$li(loc)
            })
          )
        )
      } else {
        tagList(
          tags$div(style = "color: green; font-weight: bold;",
                 "Todas las locaciones tienen al menos una celda."),
          
          # Solo mostrar la sugerencia si hay locaciones con exactamente una celda
          if(locaciones_con_una_celda) {
            tags$div(style = "margin-top: 10px; padding: 10px; background-color: #ffcdda; border-left: 5px solid #ff0730; color: #800412;",
              tags$i(class = "fa fa-exclamation-triangle", style = "margin-right: 5px;"),
              "LOCACIÓN CON UNA CELDA: Solo le queda una (01) celda a una locación [tienen muchas celdas pequeñas]. Vuelve a SIG y considera las celdas pequeñas como rejillas. Copia el polígono de las celda pequeñas hacia el shapefile de rejillas. Dales  códigos de rejilla, un único código de celda, y exporta nuevamente los marcos.")
          }
        )
      }
    )
  })
  
  # Mostrar tabla de conteo de celdas por locación
  output$tabla_conteo_locaciones <- renderDT({
    req(conteo_locaciones())
    datatable(conteo_locaciones(), 
              options = list(
                pageLength = 12, 
                scrollX = TRUE,
                autoWidth = FALSE,  # Cambiar a FALSE para evitar el reajuste automático
                fixedHeader = TRUE, # Mantener los encabezados fijos
                columnDefs = list(  # Definir anchos fijos para las columnas
                  list(targets = 0, width = '150px'),  # LOCACION
                  list(targets = 1, width = '50px'),   # n
                  list(targets = 2, width = '80px'),   # Min_Area
                  list(targets = 3, width = '80px'),   # Max_Area
                  list(targets = 4, width = '80px')    # Promed_Area
                ),
                rowCallback = JS(
                  "function(row, data) {",
                  "  $(row).css('line-height', '80%');",
                  "  $(row).css('padding-top', '2px');",
                  "  $(row).css('padding-bottom', '2px');",
                  "}"
                )
              )
            )
  })
  
  # ============================================================================ #
  # FASE 2: CARGA Y VERIFICACIÓN DE MARCOS                                       #
  # ============================================================================ #
  
  # Función para cargar los marcos cuando se presione el botón
  observeEvent(input$cargar_marcos_btn, {
    # Verificar que ambos archivos estén cargados
    if (is.null(input$archivo_marco_celdas) || is.null(input$archivo_marco_grillas)) {
      showNotification("Debe seleccionar ambos archivos Excel", type = "error")
      return()
    }
    
    # Leer los archivos Excel
    tryCatch({
      # ==================================================================
      # CARGAR MARCO DE CELDAS
      # ==================================================================
      datos_celdas <- read_excel(input$archivo_marco_celdas$datapath)
      
      # Si el usuario ha mapeado columnas manualmente, aplicar el mapeo
      if (!is.null(columnas_marco_celdas()) && !is.null(input$col_locacion_marco_celdas)) {
        # Construir dataframe con columnas mapeadas
        datos_celdas_mapeados <- data.frame(
          LOCACION = datos_celdas[[input$col_locacion_marco_celdas]],
          COD_CELDA = datos_celdas[[input$col_cod_celda_marco_celdas]]
        )
        
        # Añadir PROF si fue mapeada
        if (!is.null(input$col_prof_marco_celdas) && input$col_prof_marco_celdas != "(ninguna)") {
          datos_celdas_mapeados$PROF <- datos_celdas[[input$col_prof_marco_celdas]]
        }
        
        # Copiar otras columnas que puedan existir
        otras_cols <- setdiff(names(datos_celdas), 
                             c(input$col_locacion_marco_celdas, 
                               input$col_cod_celda_marco_celdas, 
                               input$col_prof_marco_celdas))
        if (length(otras_cols) > 0) {
          for (col in otras_cols) {
            if (!col %in% names(datos_celdas_mapeados)) {
              datos_celdas_mapeados[[col]] <- datos_celdas[[col]]
            }
          }
        }
        
        datos_celdas <- datos_celdas_mapeados
        
        showNotification(
          paste0("Mapeo aplicado (celdas): ",
                 input$col_locacion_marco_celdas, " → LOCACION, ",
                 input$col_cod_celda_marco_celdas, " → COD_CELDA"),
          type = "message",
          duration = 4
        )
      } else {
        # Usar estandarización automática
        datos_celdas <- estandarizar_columnas(datos_celdas)
      }
      
      # Verificar columnas requeridas
      verificar_columnas_requeridas(datos_celdas, c("COD_CELDA", "LOCACION"), "marco de celdas")
      marco_celdas(datos_celdas)
      
      # ==================================================================
      # CARGAR MARCO DE GRILLAS
      # ==================================================================
      datos_grillas <- read_excel(input$archivo_marco_grillas$datapath)
      
      # Si el usuario ha mapeado columnas manualmente, aplicar el mapeo
      if (!is.null(columnas_marco_grillas()) && !is.null(input$col_locacion_marco_grillas)) {
        # Construir dataframe con columnas mapeadas
        datos_grillas_mapeados <- data.frame(
          LOCACION = datos_grillas[[input$col_locacion_marco_grillas]],
          COD_CELDA = datos_grillas[[input$col_cod_celda_marco_grillas]],
          COD_GRILLA = datos_grillas[[input$col_cod_grilla_marco_grillas]],
          P_SUPERPOS = datos_grillas[[input$col_p_superpos_marco_grillas]],
          ESTE = datos_grillas[[input$col_este_marco_grillas]],
          NORTE = datos_grillas[[input$col_norte_marco_grillas]],
          PROF = datos_grillas[[input$col_prof_marco_grillas]]
        )
        
        # Copiar otras columnas que puedan existir
        otras_cols <- setdiff(names(datos_grillas), 
                             c(input$col_locacion_marco_grillas, 
                               input$col_cod_celda_marco_grillas,
                               input$col_cod_grilla_marco_grillas,
                               input$col_p_superpos_marco_grillas,
                               input$col_este_marco_grillas,
                               input$col_norte_marco_grillas,
                               input$col_prof_marco_grillas))
        if (length(otras_cols) > 0) {
          for (col in otras_cols) {
            if (!col %in% names(datos_grillas_mapeados)) {
              datos_grillas_mapeados[[col]] <- datos_grillas[[col]]
            }
          }
        }
        
        datos_grillas <- datos_grillas_mapeados
        
        showNotification(
          paste0("Mapeo aplicado (grillas): ",
                 input$col_p_superpos_marco_grillas, " → P_SUPERPOS, ",
                 input$col_este_marco_grillas, " → ESTE, ",
                 input$col_norte_marco_grillas, " → NORTE"),
          type = "message",
          duration = 4
        )
      } else {
        # Usar estandarización automática
        datos_grillas <- estandarizar_columnas(datos_grillas)
      }
      
      # Verificar columnas requeridas
      verificar_columnas_requeridas(datos_grillas, c("COD_CELDA", "COD_GRILLA", "P_SUPERPOS", "ESTE", "NORTE", "PROF"), "marco de grillas")
      marco_grillas(datos_grillas)
      
      # Mostrar notificación de éxito
      showNotification("Marcos cargados exitosamente", type = "message")
      
      # Cambiar a la pestaña de Vista Previa
      updateTabsetPanel(session, "tabset_fase2", selected = "Vista Previa")
      
    }, error = function(e) {
      registrar_error(e, "Carga de Marcos")
      showNotification(paste("Error al cargar los archivos:", conditionMessage(e)), type = "error")
    })
  })
  
  # Mostrar la vista previa de los marcos
  output$preview_marco_celdas <- renderDT({
    req(marco_celdas())
    datatable(marco_celdas(), 
              options = list(pageLength = 10, 
                            scrollX = TRUE,
                            autoWidth = TRUE))
  })
  
  output$preview_marco_grillas <- renderDT({
    req(marco_grillas())
    datatable(marco_grillas(), 
              options = list(pageLength = 10, 
                            scrollX = TRUE,
                            autoWidth = TRUE))
  })
  
  # Función para verificar la integridad de los marcos
  observeEvent(input$verificar_marcos_btn, {
    req(marco_celdas(), marco_grillas())
    
    tryCatch({
      # 1. Verificar locaciones sin celdas
      conteo_por_locacion <- marco_celdas() %>% 
        count(LOCACION) %>% 
        arrange(n)
      
      conteo_celdas_por_locacion(conteo_por_locacion)
      
      # Identificar locaciones sin celdas (si las hubiera)
      # Aquí asumimos que existe una lista completa de locaciones en algún lugar
      # Como no tenemos esa lista, solo mostramos el conteo
      
      # 2. Verificar celdas con menos de 3 grillas
      # Contar grillas ÚNICAS por celda
      conteo_por_celda <- marco_grillas() %>% 
        group_by(COD_CELDA) %>%
        summarise(n = n_distinct(COD_GRILLA), .groups = "drop") %>%
        arrange(n)
      
      conteo_grillas_por_celda(conteo_por_celda)
      
      # Identificar celdas con menos de 3 grillas
      celdas_pocas <- conteo_por_celda %>%
        filter(n < 3)
      
      # Guardar el dataframe completo con COD_CELDA y conteo
      celdas_con_pocas_grillas(celdas_pocas)
      
      # 3. Verificación cruzada entre marcos
      # Celdas en marco_celdas pero no en marco_grillas
      celdas_marco <- unique(marco_celdas()$COD_CELDA)
      celdas_grillas <- unique(marco_grillas()$COD_CELDA)
      
      celdas_solo_marco <- setdiff(celdas_marco, celdas_grillas)
      celdas_solo_en_marco_celdas(celdas_solo_marco)
      
      # Celdas en marco_grillas pero no en marco_celdas
      celdas_solo_grillas <- setdiff(celdas_grillas, celdas_marco)
      celdas_solo_en_marco_grillas(celdas_solo_grillas)
      
      # ==================================================================
      # 4. REVISIÓN DE PROFUNDIDADES
      # ==================================================================
      
      # 4.1 Verificar celdas con profundidades inconsistentes (Regla 1)
      # Cada celda debe tener UNA ÚNICA profundidad en todas sus grillas
      prof_por_celda <- marco_grillas() %>%
        group_by(COD_CELDA) %>%
        summarise(
          profundidades_unicas = n_distinct(PROF, na.rm = FALSE),
          prof_min = min(PROF, na.rm = TRUE),
          prof_max = max(PROF, na.rm = TRUE),
          lista_profundidades = paste(unique(PROF), collapse = ", "),
          n_grillas = n(),
          .groups = "drop"
        ) %>%
        filter(profundidades_unicas > 1)  # Celdas con más de una profundidad
      
      celdas_profundidades_inconsistentes(prof_por_celda)
      
      # 4.2 Verificar grillas con profundidad inválida (Regla 2)
      # No puede haber profundidad en blanco (NA) o igual a 0
      grillas_invalidas <- marco_grillas() %>%
        filter(is.na(PROF) | PROF == 0) %>%
        select(COD_GRILLA, COD_CELDA, LOCACION, PROF, everything())
      
      grillas_prof_invalida(grillas_invalidas)
      
      # 4.3 Verificar celdas con profundidad inválida (Regla 2)
      # Si el marco de celdas tiene columna PROF
      if ("PROF" %in% names(marco_celdas())) {
        celdas_invalidas <- marco_celdas() %>%
          filter(is.na(PROF) | PROF == 0) %>%
          select(COD_CELDA, LOCACION, PROF, everything())
        
        celdas_prof_invalida(celdas_invalidas)
      } else {
        # Si no hay columna PROF en marco_celdas, guardar dataframe vacío
        celdas_prof_invalida(data.frame())
      }
      
      # Mostrar notificación de éxito
      showNotification("Verificación completada", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error en la verificación:", e$message), type = "error")
    })
  })
  
  # Mostrar conteo de celdas por locación
  output$conteo_celdas_locacion <- renderDT({
    req(conteo_celdas_por_locacion())
    datatable(conteo_celdas_por_locacion(), 
              options = list(pageLength = 15, 
                            scrollX = TRUE,
                            autoWidth = TRUE))
  })
  
  # Mostrar locaciones sin celdas
  output$locaciones_sin_celdas <- renderPrint({
    req(conteo_celdas_por_locacion())
    
    # Identificar locaciones con 0 celdas (si las hubiera)
    locaciones_cero <- conteo_celdas_por_locacion() %>%
      filter(n == 0)
    
    if (nrow(locaciones_cero) > 0) {
      cat("Locaciones sin celdas:\n")
      print(locaciones_cero)
    } else {
      cat("Todas las locaciones tienen al menos una celda.")
    }
  })
  
  # Resumen de locaciones
  output$resumen_locaciones <- renderUI({
    req(conteo_celdas_por_locacion())
    
    # Estadísticas de locaciones
    total_locaciones <- nrow(conteo_celdas_por_locacion())
    min_celdas <- min(conteo_celdas_por_locacion()$n)
    max_celdas <- max(conteo_celdas_por_locacion()$n)
    promedio_celdas <- mean(conteo_celdas_por_locacion()$n)
    
    tagList(
      h4("Resumen"),
      p(paste("Total de locaciones:", total_locaciones)),
      p(paste("Mínimo de celdas por locación:", min_celdas)),
      p(paste("Máximo de celdas por locación:", max_celdas)),
      p(paste("Promedio de celdas por locación:", round(promedio_celdas, 2)))
    )
  })
  
  # Mostrar conteo de grillas por celda
  output$conteo_grillas_celda <- renderDT({
    req(conteo_grillas_por_celda())
    datatable(conteo_grillas_por_celda(), 
              options = list(pageLength = 15, 
                            scrollX = TRUE,
                            autoWidth = TRUE))
  })
  
  # Mostrar celdas con pocas grillas
  output$celdas_pocas_grillas <- renderPrint({
    req(conteo_grillas_por_celda())
    
    # Filtrar directamente las celdas con menos de 3 grillas
    celdas_pocas <- conteo_grillas_por_celda() %>%
      filter(n < 3)
    
    if (nrow(celdas_pocas) > 0) {
      cat("Celdas con menos de 3 grillas:\n")
      print(celdas_pocas)
    } else {
      cat("Todas las celdas tienen al menos 3 grillas.")
    }
  })
  
  # Resumen de grillas
  output$resumen_grillas <- renderUI({
    req(conteo_grillas_por_celda(), celdas_con_pocas_grillas())
    
    # Estadísticas de grillas
    total_celdas <- nrow(conteo_grillas_por_celda())
    celdas_problema <- nrow(celdas_con_pocas_grillas())
    min_grillas <- min(conteo_grillas_por_celda()$n)
    max_grillas <- max(conteo_grillas_por_celda()$n)
    promedio_grillas <- mean(conteo_grillas_por_celda()$n)
    
    tagList(
      h4("Resumen"),
      p(paste("Total de celdas en marco_grillas:", total_celdas)),
      p(paste("Celdas con menos de 3 grillas:", celdas_problema)),
      p(paste("Mínimo de grillas por celda:", min_grillas)),
      p(paste("Máximo de grillas por celda:", max_grillas)),
      p(paste("Promedio de grillas por celda:", round(promedio_grillas, 2))),
      
      if(celdas_problema > 0) {
        tags$div(style = "color: red; font-weight: bold;",
                 paste("ADVERTENCIA: Se encontraron", celdas_problema, "celdas con menos de 3 grillas."))
      } else {
        tags$div(style = "color: green; font-weight: bold;",
                 "Todas las celdas tienen al menos 3 grillas.")
      }
    )
  })
  
  # Mostrar celdas que están en marco_celdas pero no en marco_grillas
  output$celdas_no_en_grillas <- renderDT({
    req(marco_celdas(), celdas_solo_en_marco_celdas())
    
    if (length(celdas_solo_en_marco_celdas()) > 0) {
      celdas_filtradas <- marco_celdas() %>%
        filter(COD_CELDA %in% celdas_solo_en_marco_celdas())
      
      datatable(celdas_filtradas, 
                options = list(pageLength = 10, 
                              scrollX = TRUE,
                              autoWidth = TRUE))
    } else {
      datatable(data.frame(mensaje = "No hay celdas que estén solo en marco_celdas"), 
                options = list(dom = 't'))
    }
  })
  
  # Mostrar sugerencia para celdas en marco_celdas pero no en marco_grillas
  output$sugerencia_celdas_no_en_grillas <- renderUI({
    req(celdas_solo_en_marco_celdas())
    
    if (length(celdas_solo_en_marco_celdas()) > 0) {
      tags$div(style = "margin-top: 10px; padding: 10px; background-color: #fff3cd; border-left: 5px solid #ffc107; color: #856404;",
               tags$i(class = "fa fa-exclamation-triangle", style = "margin-right: 5px;"),
               "SUGERENCIA: Revisa el SHAPEFILE DE CELDAS, hay algunas celdas que se quedaron sin rejillas y olvidaron borrarlas en ese shapefile")
    }
  })
  
  # Mostrar celdas que están en marco_grillas pero no en marco_celdas
  output$celdas_no_en_marco <- renderDT({
    req(marco_grillas(), celdas_solo_en_marco_grillas())
    
    if (length(celdas_solo_en_marco_grillas()) > 0) {
      grillas_filtradas <- marco_grillas() %>%
        filter(COD_CELDA %in% celdas_solo_en_marco_grillas()) %>%
        distinct(COD_CELDA, .keep_all = TRUE)
      
      datatable(grillas_filtradas, 
                options = list(pageLength = 10, 
                              scrollX = TRUE,
                              autoWidth = TRUE))
    } else {
      datatable(data.frame(mensaje = "No hay celdas que estén solo en marco_grillas"), 
                options = list(dom = 't'))
    }
  })
  
  # Mostrar sugerencia para celdas en marco_grillas pero no en marco_celdas
  output$sugerencia_celdas_no_en_marco <- renderUI({
    req(celdas_solo_en_marco_grillas())
    
    if (length(celdas_solo_en_marco_grillas()) > 0) {
      tags$div(style = "margin-top: 10px; padding: 10px; background-color: #f8d7da; border-left: 5px solid #dc3545; color: #721c24;",
               tags$i(class = "fa fa-exclamation-circle", style = "margin-right: 5px;"),
               "SUGERENCIA: Revisa el SHAPEFILE DE CELDAS, hay algunas celdas que han sido borradas pero cuyas rejillas se han mantenido en el SHAPEFILE DE REJILLAS. Revisa si (1) debes recuperar la celda o (2) debes eliminar las rejillas")
    }
  })
  
  # ============================================================================ #
  # OUTPUTS PARA REVISIÓN DE PROFUNDIDADES - FASE 2                           #
  # ============================================================================ #
  
  # Resumen: Problema 1 - Celdas con profundidades inconsistentes
  output$resumen_prof_inconsistentes <- renderUI({
    req(celdas_profundidades_inconsistentes())
    
    n_problema <- nrow(celdas_profundidades_inconsistentes())
    
    if (n_problema > 0) {
      div(style = "background-color: #fff3cd; border: 2px solid #ffc107; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        h5(style = "color: #856404; margin-top: 0;",
          icon("exclamation-triangle"), 
          strong(paste(" Se encontraron", n_problema, "celdas con profundidades inconsistentes"))
        ),
        p(style = "margin-bottom: 0; color: #856404;",
          "Las grillas de estas celdas tienen profundidades distintas. Cada celda debe tener una única profundidad.")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        p(style = "margin-bottom: 0; color: #155724;",
          icon("check-circle"), " Todas las celdas tienen profundidad consistente (Regla 1 cumplida)")
      )
    }
  })
  
  # Tabla: Problema 1 - Celdas con profundidades inconsistentes
  output$tabla_prof_inconsistentes <- renderDT({
    req(celdas_profundidades_inconsistentes())
    
    if (nrow(celdas_profundidades_inconsistentes()) > 0) {
      datatable(celdas_profundidades_inconsistentes(),
                options = list(
                  pageLength = 10,
                  scrollX = TRUE,
                  autoWidth = TRUE
                ),
                rownames = FALSE) %>%
        formatStyle('profundidades_unicas',
                   backgroundColor = '#fff3cd',
                   fontWeight = 'bold')
    } else {
      datatable(data.frame(Mensaje = "✅ No hay problemas de profundidad inconsistente"),
                options = list(dom = 't'),
                rownames = FALSE)
    }
  })
  
  # Resumen: Problema 2A - Grillas con profundidad inválida
  output$resumen_grillas_prof_invalida <- renderUI({
    req(grillas_prof_invalida())
    
    n_problema <- nrow(grillas_prof_invalida())
    
    if (n_problema > 0) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        h5(style = "color: #721c24; margin-top: 0;",
          icon("ban"), 
          strong(paste(" Se encontraron", n_problema, "grillas con profundidad inválida"))
        ),
        p(style = "margin-bottom: 0; color: #721c24;",
          "Estas grillas tienen profundidad en blanco (NA) o igual a 0. Deben corregirse.")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        p(style = "margin-bottom: 0; color: #155724;",
          icon("check-circle"), " Todas las grillas tienen profundidad válida (Regla 2 cumplida)")
      )
    }
  })
  
  # Tabla: Problema 2A - Grillas con profundidad inválida
  output$tabla_grillas_prof_invalida <- renderDT({
    req(grillas_prof_invalida())
    
    if (nrow(grillas_prof_invalida()) > 0) {
      datatable(grillas_prof_invalida(),
                options = list(
                  pageLength = 10,
                  scrollX = TRUE,
                  autoWidth = TRUE
                ),
                rownames = FALSE) %>%
        formatStyle('PROF',
                   backgroundColor = '#f8d7da',
                   fontWeight = 'bold')
    } else {
      datatable(data.frame(Mensaje = "✅ Todas las grillas tienen profundidad válida"),
                options = list(dom = 't'),
                rownames = FALSE)
    }
  })
  
  # Resumen: Problema 2B - Celdas con profundidad inválida
  output$resumen_celdas_prof_invalida <- renderUI({
    req(celdas_prof_invalida())
    
    n_problema <- nrow(celdas_prof_invalida())
    
    if (n_problema > 0) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        h5(style = "color: #721c24; margin-top: 0;",
          icon("ban"), 
          strong(paste(" Se encontraron", n_problema, "celdas con profundidad inválida"))
        ),
        p(style = "margin-bottom: 0; color: #721c24;",
          "Estas celdas tienen profundidad en blanco (NA) o igual a 0. Deben corregirse.")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
        p(style = "margin-bottom: 0; color: #155724;",
          icon("check-circle"), " Todas las celdas tienen profundidad válida (Regla 2 cumplida)")
      )
    }
  })
  
  # Tabla: Problema 2B - Celdas con profundidad inválida
  output$tabla_celdas_prof_invalida <- renderDT({
    req(celdas_prof_invalida())
    
    if (nrow(celdas_prof_invalida()) > 0) {
      datatable(celdas_prof_invalida(),
                options = list(
                  pageLength = 10,
                  scrollX = TRUE,
                  autoWidth = TRUE
                ),
                rownames = FALSE) %>%
        formatStyle('PROF',
                   backgroundColor = '#f8d7da',
                   fontWeight = 'bold')
    } else {
      datatable(data.frame(Mensaje = "✅ Todas las celdas tienen profundidad válida"),
                options = list(dom = 't'),
                rownames = FALSE)
    }
  })
  
  # Resumen de verificación cruzada
  output$resumen_verificacion_cruzada <- renderUI({
    req(celdas_solo_en_marco_celdas(), celdas_solo_en_marco_grillas())
    
    tagList(
      h4("Resumen de Verificación Cruzada"),
      p(paste("Celdas solo en marco_celdas:", length(celdas_solo_en_marco_celdas()))),
      p(paste("Celdas solo en marco_grillas:", length(celdas_solo_en_marco_grillas()))),
      
      if (length(celdas_solo_en_marco_celdas()) > 0 || length(celdas_solo_en_marco_grillas()) > 0) {
        tags$div(style = "color: red; font-weight: bold;",
                 "ADVERTENCIA: Se encontraron inconsistencias entre los marcos de celdas y grillas.")
      } else {
        tags$div(style = "color: green; font-weight: bold;",
                 "Los marcos de celdas y grillas son consistentes.")
      }
    )
  })
  
  # ============================================================================ #
  # FASE 2C: VERIFICACIÓN ESPACIAL DE MARCOS SHAPEFILE                         #
  # ============================================================================ #
  
  # Handler para ejecutar verificación espacial
  observeEvent(input$verificar_espacial_btn, {
    tryCatch({
      # Validar que ambos archivos estén cargados
      if (is.null(input$archivo_shp_grillas_verif)) {
        showNotification("⚠️ Debe cargar el shapefile de GRILLAS", type = "error", duration = 5)
        return(NULL)
      }
      
      if (is.null(input$archivo_shp_celdas_verif)) {
        showNotification("⚠️ Debe cargar el shapefile de CELDAS", type = "error", duration = 5)
        return(NULL)
      }
      
      showNotification("🔄 Cargando y procesando shapefiles...", type = "message", duration = 3)
      
      # ==== CARGAR SHAPEFILE DE GRILLAS ====
      cat("\n=== Cargando Shapefile de Grillas ===\n")
      
      # Crear subdirectorio único para descompresión
      temp_base <- tempdir()
      temp_dir_grillas <- file.path(temp_base, paste0("grillas_verif_", format(Sys.time(), "%Y%m%d_%H%M%S")))
      dir.create(temp_dir_grillas, showWarnings = FALSE, recursive = TRUE)
      
      zip_path_grillas <- input$archivo_shp_grillas_verif$datapath
      
      cat("→ Ruta del ZIP:", zip_path_grillas, "\n")
      cat("→ Directorio de extracción:", temp_dir_grillas, "\n")
      
      # Validar que el archivo existe y es legible
      if (!file.exists(zip_path_grillas)) {
        showNotification("❌ El archivo ZIP de grillas no existe", type = "error", duration = 5)
        return(NULL)
      }
      
      # Descomprimir con manejo de errores
      unzip_result <- tryCatch({
        unzip(zip_path_grillas, exdir = temp_dir_grillas)
      }, error = function(e) {
        cat("❌ Error al descomprimir:", conditionMessage(e), "\n")
        return(NULL)
      }, warning = function(w) {
        cat("⚠️ Advertencia al descomprimir:", conditionMessage(w), "\n")
        return(NULL)
      })
      
      if (is.null(unzip_result) || length(unzip_result) == 0) {
        showNotification("❌ No se pudo descomprimir el ZIP de grillas. Verifique que sea un archivo ZIP válido.", 
                        type = "error", duration = 8)
        return(NULL)
      }
      
      cat("→ Archivos extraídos:", length(unzip_result), "\n")
      
      # Buscar archivo .shp recursivamente
      shp_files_grillas <- list.files(temp_dir_grillas, pattern = "\\.shp$", 
                                       full.names = TRUE, recursive = TRUE, 
                                       ignore.case = TRUE)
      
      cat("→ Archivos .shp encontrados:", length(shp_files_grillas), "\n")
      if (length(shp_files_grillas) > 0) {
        cat("→ Primer shapefile:", shp_files_grillas[1], "\n")
      }
      
      if (length(shp_files_grillas) == 0) {
        # Listar todos los archivos para diagnóstico
        todos_archivos <- list.files(temp_dir_grillas, full.names = TRUE, recursive = TRUE)
        cat("⚠️ Archivos encontrados en el ZIP:\n")
        print(todos_archivos)
        
        showNotification("❌ No se encontró archivo .shp en el ZIP de grillas. Verifique la estructura del ZIP.", 
                        type = "error", duration = 8)
        return(NULL)
      }
      
      # Leer shapefile de grillas
      shp_grillas_raw <- st_read(shp_files_grillas[1], quiet = FALSE)
      
      # ==== MAPEO DE COLUMNAS DE GRILLAS ====
      # Si el usuario mapeó columnas manualmente, usar ese mapeo
      # Si no, usar detección automática
      
      if (!is.null(columnas_shp_grillas_verif()) && !is.null(input$col_grilla_shp_verif)) {
        # MAPEO MANUAL
        col_grilla <- input$col_grilla_shp_verif
        col_celda_grillas <- if (!is.null(input$col_celda_shp_grillas_verif) && 
                                 input$col_celda_shp_grillas_verif != "(ninguna)") {
          input$col_celda_shp_grillas_verif
        } else {
          NULL
        }
        
        cat("✓ Usando mapeo manual de columnas (grillas):\n")
        cat("  - GRILLA:", col_grilla, "\n")
        if (!is.null(col_celda_grillas)) {
          cat("  - CELDA:", col_celda_grillas, "\n")
        }
        
        showNotification(
          paste0("📍 Mapeo aplicado (grillas): ", col_grilla, " → GRILLA"),
          type = "message",
          duration = 3
        )
      } else {
        # DETECCIÓN AUTOMÁTICA
        # Estandarizar nombres de columnas a MAYÚSCULAS (EXCEPTO la geometría)
        geom_col_grillas <- attr(shp_grillas_raw, "sf_column")
        col_names_grillas <- names(shp_grillas_raw)
        col_names_grillas_upper <- toupper(col_names_grillas)
        # Restaurar el nombre original de la columna de geometría
        col_names_grillas_upper[col_names_grillas == geom_col_grillas] <- geom_col_grillas
        names(shp_grillas_raw) <- col_names_grillas_upper
        
        # Detectar columna de grilla
        col_grilla <- NULL
        if ("GRILLA" %in% names(shp_grillas_raw)) {
          col_grilla <- "GRILLA"
        } else if ("COD_GRILLA" %in% names(shp_grillas_raw)) {
          col_grilla <- "COD_GRILLA"
        } else {
          showNotification("❌ No se encontró columna GRILLA o COD_GRILLA en el shapefile", 
                          type = "error", duration = 5)
          return(NULL)
        }
        
        cat("✓ Columna de grilla detectada automáticamente:", col_grilla, "\n")
        
        # Detectar columna de celda (opcional)
        col_celda_grillas <- NULL
        if ("CELDA" %in% names(shp_grillas_raw)) {
          col_celda_grillas <- "CELDA"
        } else if ("COD_CELDA" %in% names(shp_grillas_raw)) {
          col_celda_grillas <- "COD_CELDA"
        }
        
        if (!is.null(col_celda_grillas)) {
          cat("✓ Columna de celda detectada en grillas:", col_celda_grillas, "\n")
        } else {
          cat("ℹ️ No se encontró columna de celda en grillas (CELDA o COD_CELDA)\n")
        }
      }
      
      shp_grillas_verif(shp_grillas_raw)
      
      # ==== CARGAR SHAPEFILE DE CELDAS ====
      cat("\n=== Cargando Shapefile de Celdas ===\n")
      
      # Crear subdirectorio único para descompresión
      temp_dir_celdas <- file.path(temp_base, paste0("celdas_verif_", format(Sys.time(), "%Y%m%d_%H%M%S")))
      dir.create(temp_dir_celdas, showWarnings = FALSE, recursive = TRUE)
      
      zip_path_celdas <- input$archivo_shp_celdas_verif$datapath
      
      cat("→ Ruta del ZIP:", zip_path_celdas, "\n")
      cat("→ Directorio de extracción:", temp_dir_celdas, "\n")
      
      # Validar que el archivo existe y es legible
      if (!file.exists(zip_path_celdas)) {
        showNotification("❌ El archivo ZIP de celdas no existe", type = "error", duration = 5)
        return(NULL)
      }
      
      # Descomprimir con manejo de errores
      unzip_result_celdas <- tryCatch({
        unzip(zip_path_celdas, exdir = temp_dir_celdas)
      }, error = function(e) {
        cat("❌ Error al descomprimir:", conditionMessage(e), "\n")
        return(NULL)
      }, warning = function(w) {
        cat("⚠️ Advertencia al descomprimir:", conditionMessage(w), "\n")
        return(NULL)
      })
      
      if (is.null(unzip_result_celdas) || length(unzip_result_celdas) == 0) {
        showNotification("❌ No se pudo descomprimir el ZIP de celdas. Verifique que sea un archivo ZIP válido.", 
                        type = "error", duration = 8)
        return(NULL)
      }
      
      cat("→ Archivos extraídos:", length(unzip_result_celdas), "\n")
      
      # Buscar archivo .shp recursivamente
      shp_files_celdas <- list.files(temp_dir_celdas, pattern = "\\.shp$", 
                                       full.names = TRUE, recursive = TRUE, 
                                       ignore.case = TRUE)
      
      cat("→ Archivos .shp encontrados:", length(shp_files_celdas), "\n")
      if (length(shp_files_celdas) > 0) {
        cat("→ Primer shapefile:", shp_files_celdas[1], "\n")
      }
      
      if (length(shp_files_celdas) == 0) {
        # Listar todos los archivos para diagnóstico
        todos_archivos_celdas <- list.files(temp_dir_celdas, full.names = TRUE, recursive = TRUE)
        cat("⚠️ Archivos encontrados en el ZIP:\n")
        print(todos_archivos_celdas)
        
        showNotification("❌ No se encontró archivo .shp en el ZIP de celdas. Verifique la estructura del ZIP.", 
                        type = "error", duration = 8)
        return(NULL)
      }
      
      # Leer shapefile de celdas
      shp_celdas_raw <- st_read(shp_files_celdas[1], quiet = FALSE)
      
      # ==== MAPEO DE COLUMNAS DE CELDAS ====
      # Si el usuario mapeó columnas manualmente, usar ese mapeo
      # Si no, usar detección automática
      
      if (!is.null(columnas_shp_celdas_verif()) && !is.null(input$col_celda_shp_verif)) {
        # MAPEO MANUAL
        col_celda_celdas <- input$col_celda_shp_verif
        
        cat("✓ Usando mapeo manual de columnas (celdas):\n")
        cat("  - CELDA:", col_celda_celdas, "\n")
        
        showNotification(
          paste0("📍 Mapeo aplicado (celdas): ", col_celda_celdas, " → CELDA"),
          type = "message",
          duration = 3
        )
      } else {
        # DETECCIÓN AUTOMÁTICA
        # Estandarizar nombres de columnas a MAYÚSCULAS (EXCEPTO la geometría)
        geom_col_celdas <- attr(shp_celdas_raw, "sf_column")
        col_names_celdas <- names(shp_celdas_raw)
        col_names_celdas_upper <- toupper(col_names_celdas)
        # Restaurar el nombre original de la columna de geometría
        col_names_celdas_upper[col_names_celdas == geom_col_celdas] <- geom_col_celdas
        names(shp_celdas_raw) <- col_names_celdas_upper
        
        # Detectar columna de celda
        col_celda_celdas <- NULL
        if ("CELDA" %in% names(shp_celdas_raw)) {
          col_celda_celdas <- "CELDA"
        } else if ("COD_CELDA" %in% names(shp_celdas_raw)) {
          col_celda_celdas <- "COD_CELDA"
        } else {
          showNotification("❌ No se encontró columna CELDA o COD_CELDA en el shapefile de celdas", 
                          type = "error", duration = 5)
          return(NULL)
        }
        
        cat("✓ Columna de celda detectada automáticamente:", col_celda_celdas, "\n")
      }
      
      shp_celdas_verif(shp_celdas_raw)
      
      showNotification("✓ Shapefiles cargados correctamente", type = "message", duration = 3)
      
      # ==== ANÁLISIS 1: GENERAR CENTROIDES ====
      showNotification("🔄 Generando centroides de grillas...", type = "message", duration = 3)
      
      centroides <- generar_centroides_grillas(shp_grillas_raw, col_grilla = col_grilla)
      centroides_grillas_verif(centroides)
      
      # ==== ANÁLISIS 2: IDENTIFICAR GRILLAS FUERA DE CELDAS ====
      showNotification("🔄 Identificando grillas fuera de celdas...", type = "message", duration = 3)
      
      resultado_fuera <- identificar_grillas_fuera_celdas(
        centroides, 
        shp_celdas_raw, 
        col_celda = col_celda_celdas
      )
      
      resultado_grillas_fuera(resultado_fuera)
      
      # ==== ANÁLISIS 3: VERIFICAR CÓDIGOS DE CELDA ====
      if (!is.null(col_celda_grillas)) {
        showNotification("🔄 Verificando asignación de códigos de celda...", type = "message", duration = 3)
        
        resultado_mal_asignadas <- identificar_celdas_mal_asignadas(
          shp_grillas_raw,
          shp_celdas_raw,
          col_grilla = col_grilla,
          col_celda_grillas = col_celda_grillas,
          col_celda_celdas = col_celda_celdas
        )
        
        resultado_celdas_mal_asignadas(resultado_mal_asignadas)
        
        # Notificar si hay celdas duplicadas detectadas
        if (!is.null(resultado_mal_asignadas$tiene_duplicados) && resultado_mal_asignadas$tiene_duplicados) {
          n_dup <- resultado_mal_asignadas$info_duplicados$n_duplicados
          showNotification(
            paste0("⚠️ CELDAS DUPLICADAS DETECTADAS: ", n_dup, " celda(s) apilada(s). Revise la consola para detalles."),
            type = "warning",
            duration = 10
          )
        }
      } else {
        # No se puede hacer verificación
        resultado_celdas_mal_asignadas(list(
          mal_asignadas = NULL,
          verificacion_posible = FALSE
        ))
      }
      
      # Notificación final
      msg_final <- "✅ Verificación espacial completada"
      if (resultado_fuera$n_fuera > 0) {
        msg_final <- paste0(msg_final, "\n⚠️ Se encontraron ", resultado_fuera$n_fuera, 
                           " grillas fuera de celdas")
      }
      
      showNotification(msg_final, type = "message", duration = 5)
      
    }, error = function(e) {
      cat("\n❌ ERROR en verificación espacial:\n")
      print(e)
      showNotification(
        paste0("❌ Error en verificación espacial: ", conditionMessage(e)),
        type = "error",
        duration = 10
      )
      registrar_error(e, "Verificación espacial de marcos shapefile")
    })
  })
  
  # Outputs de visualización - Grillas fuera de celdas (ORIGINAL - sin análisis de contaminadas)
  output$resumen_grillas_fuera <- renderUI({
    resultado <- resultado_grillas_fuera()
    req(resultado)
    
    if (resultado$n_fuera == 0) {
      tags$div(
        style = "padding: 15px; background-color: #d4edda; border-left: 5px solid #28a745;",
        h5(style = "color: #155724; margin: 0;", "✅ Verificación Exitosa"),
        p(style = "color: #155724; margin-top: 10px; margin-bottom: 0;",
          sprintf("Todas las %d grillas tienen sus centroides DENTRO de celdas.", resultado$n_total))
      )
    } else {
      tags$div(
        style = "padding: 15px; background-color: #fff3cd; border-left: 5px solid #ffc107;",
        tags$table(style = "width: 100%; border-collapse: collapse;",
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold;", "Total de grillas:"),
            tags$td(style = "padding: 5px; text-align: right;", resultado$n_total)
          ),
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold; color: #856404;", "Grillas FUERA de celdas:"),
            tags$td(style = "padding: 5px; text-align: right; color: #856404; font-weight: bold; font-size: 18px;",
                   sprintf("%d (%.1f%%)", resultado$n_fuera, resultado$pct_fuera))
          ),
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold; color: #28a745;", "Grillas DENTRO de celdas:"),
            tags$td(style = "padding: 5px; text-align: right; color: #28a745;",
                   sprintf("%d (%.1f%%)", resultado$n_total - resultado$n_fuera, 100 - resultado$pct_fuera))
          )
        )
      )
    }
  })
  
  output$tabla_grillas_fuera <- renderDT({
    resultado <- resultado_grillas_fuera()
    req(resultado)
    
    if (resultado$n_fuera == 0) {
      data.frame(
        Mensaje = "✅ No hay grillas con problemas. Todas están dentro de celdas."
      )
    } else {
      grillas_fuera <- resultado$grillas_fuera
      datatable(
        grillas_fuera,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        class = 'cell-border stripe'
      ) %>%
        formatStyle(
          'COD_GRILLA',
          backgroundColor = '#fff3cd',
          fontWeight = 'bold'
        )
    }
  })
  
  # Outputs de visualización - Celdas mal asignadas (ORIGINAL)
  output$resumen_celdas_mal_asignadas <- renderUI({
    resultado <- resultado_celdas_mal_asignadas()
    req(resultado)
    
    if (!resultado$verificacion_posible) {
      return(tags$div(
        style = "padding: 15px; background-color: #e7f3ff; border-left: 5px solid #2196f3;",
        h5(style = "color: #004085; margin: 0;", "ℹ️ Verificación No Disponible"),
        p(style = "color: #004085; margin-top: 10px; margin-bottom: 0;",
          "El shapefile de grillas no contiene columna CELDA o COD_CELDA. 
          No es posible verificar la asignación de códigos.")
      ))
    }
    
    if (resultado$n_mal_asignadas == 0) {
      tags$div(
        style = "padding: 15px; background-color: #d4edda; border-left: 5px solid #28a745;",
        h5(style = "color: #155724; margin: 0;", "✅ Verificación Exitosa"),
        p(style = "color: #155724; margin-top: 10px; margin-bottom: 0;",
          sprintf("Las %d grillas verificadas tienen códigos de celda CORRECTOS.", resultado$n_total))
      )
    } else {
      tags$div(
        style = "padding: 15px; background-color: #f8d7da; border-left: 5px solid #dc3545;",
        tags$table(style = "width: 100%; border-collapse: collapse;",
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold;", "Total de grillas verificadas:"),
            tags$td(style = "padding: 5px; text-align: right;", resultado$n_total)
          ),
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold; color: #721c24;", "Grillas con código INCORRECTO:"),
            tags$td(style = "padding: 5px; text-align: right; color: #721c24; font-weight: bold; font-size: 18px;",
                   sprintf("%d (%.1f%%)", resultado$n_mal_asignadas, resultado$pct_mal))
          ),
          tags$tr(
            tags$td(style = "padding: 5px; font-weight: bold; color: #28a745;", "Grillas con código CORRECTO:"),
            tags$td(style = "padding: 5px; text-align: right; color: #28a745;",
                   sprintf("%d (%.1f%%)", resultado$n_total - resultado$n_mal_asignadas, 100 - resultado$pct_mal))
          )
        )
      )
    }
  })
  
  output$tabla_celdas_mal_asignadas <- renderDT({
    resultado <- resultado_celdas_mal_asignadas()
    req(resultado)
    
    if (!resultado$verificacion_posible) {
      return(datatable(
        data.frame(
          Mensaje = "El shapefile no contiene columna de celda. Verificación no disponible."
        ),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    if (resultado$n_mal_asignadas == 0) {
      return(datatable(
        data.frame(
          Mensaje = "✅ Todas las grillas tienen códigos de celda correctos."
        ),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    mal_asignadas <- resultado$mal_asignadas
    datatable(
      mal_asignadas,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    ) %>%
      formatStyle(
        'PROBLEMA',
        backgroundColor = styleEqual(
          c('Centroide fuera de celdas', 'Código de celda incorrecto'),
          c('#fff3cd', '#f8d7da')
        ),
        fontWeight = 'bold'
      ) %>%
      formatStyle(
        'CELDA_ASIGNADA',
        backgroundColor = '#ffe6e6'
      ) %>%
      formatStyle(
        'CELDA_REAL',
        backgroundColor = '#e6ffe6'
      )
  })
  
  # ============================================================================ #
  # OUTPUTS PARA PESTAÑA "CHEQUEO VÉRTICES (CONTAMINADAS F5)"
  # ============================================================================ #
  
  # Info de carga de Excel de contaminadas
  output$info_carga_contaminadas <- renderUI({
    if (is.null(grillas_contaminadas_f5())) {
      tags$div(style = "background-color: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 10px;",
        p(style = "margin: 0; color: #856404;",
          icon("exclamation-triangle"),
          " No se ha cargado el Excel de contaminadas. ",
          tags$b("Cargue el archivo en la sección izquierda para ver el análisis.")
        )
      )
    } else {
      n_grillas <- nrow(grillas_contaminadas_f5())
      n_celdas <- if (!is.null(celdas_contaminadas_f5())) nrow(celdas_contaminadas_f5()) else 0
      
      tags$div(style = "background-color: #d4edda; padding: 10px; border-radius: 4px; margin-top: 10px;",
        p(style = "margin: 0; color: #155724;",
          icon("check-circle"),
          sprintf(" Excel cargado: %d grillas y %d celdas contaminadas de Fase 5.", n_grillas, n_celdas)
        )
      )
    }
  })
  
  # Resumen de grillas contaminadas FUERA de celdas
  output$resumen_grillas_contaminadas_fuera <- renderUI({
    resultado <- resultado_grillas_fuera()
    
    if (is.null(grillas_contaminadas_f5())) {
      return(tags$p(style = "color: #999; font-style: italic;", "⏳ Cargue el Excel de contaminadas primero"))
    }
    
    if (is.null(resultado)) {
      return(tags$p(style = "color: #999; font-style: italic;", "⏳ Ejecute la verificación espacial primero"))
    }
    
    if (resultado$n_fuera == 0) {
      return(tags$div(style = "padding: 10px; background-color: #d4edda; border-radius: 4px;",
        p(style = "color: #155724; margin: 0; font-weight: bold;", 
          "✅ Ninguna grilla contaminada está fuera de celdas")
      ))
    }
    
    # Calcular cuántas contaminadas están fuera
    grillas_cont_codigos <- unique(grillas_contaminadas_f5()$GRILLA)
    grillas_fuera_codigos <- resultado$grillas_fuera$COD_GRILLA
    contaminadas_fuera <- grillas_fuera_codigos[grillas_fuera_codigos %in% grillas_cont_codigos]
    n_contaminadas_fuera <- length(contaminadas_fuera)
    n_total_contaminadas <- length(grillas_cont_codigos)
    pct <- if (n_total_contaminadas > 0) (n_contaminadas_fuera / n_total_contaminadas * 100) else 0
    
    if (n_contaminadas_fuera == 0) {
      tags$div(style = "padding: 10px; background-color: #d4edda; border-radius: 4px;",
        p(style = "color: #155724; margin: 0; font-weight: bold;", 
          sprintf("✅ Las %d grillas contaminadas están todas dentro de celdas", n_total_contaminadas))
      )
    } else {
      tags$div(style = "padding: 10px; background-color: #f8d7da; border-radius: 4px;",
        tags$table(style = "width: 100%;",
          tags$tr(
            tags$td("Total contaminadas:"),
            tags$td(style = "text-align: right; font-weight: bold;", n_total_contaminadas)
          ),
          tags$tr(
            tags$td(style = "color: #721c24; font-weight: bold;", "🚨 Contaminadas FUERA:"),
            tags$td(style = "text-align: right; color: #721c24; font-weight: bold; font-size: 16px;",
                   sprintf("%d (%.1f%%)", n_contaminadas_fuera, pct))
          )
        )
      )
    }
  })
  
  # Tabla de grillas contaminadas FUERA
  output$tabla_grillas_contaminadas_fuera <- renderDT({
    resultado <- resultado_grillas_fuera()
    
    if (is.null(grillas_contaminadas_f5()) || is.null(resultado)) {
      return(datatable(
        data.frame(Mensaje = "Cargue el Excel de contaminadas y ejecute la verificación espacial"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    if (resultado$n_fuera == 0) {
      return(datatable(
        data.frame(Mensaje = "✅ No hay grillas contaminadas fuera de celdas"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    # Filtrar solo las contaminadas
    grillas_cont_codigos <- unique(grillas_contaminadas_f5()$GRILLA)
    grillas_fuera <- resultado$grillas_fuera %>%
      filter(COD_GRILLA %in% grillas_cont_codigos)
    
    if (nrow(grillas_fuera) == 0) {
      return(datatable(
        data.frame(Mensaje = "✅ No hay grillas contaminadas fuera de celdas"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(
      grillas_fuera,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    ) %>%
      formatStyle(
        columns = 1:ncol(grillas_fuera),
        target = 'row',
        backgroundColor = '#ffe6e6',
        fontWeight = 'bold'
      ) %>%
      formatStyle(
        'COD_GRILLA',
        backgroundColor = '#dc3545',
        color = 'white',
        fontWeight = 'bold'
      )
  })
  
  # Resumen de grillas contaminadas con código INCORRECTO
  output$resumen_grillas_contaminadas_codigo <- renderUI({
    resultado <- resultado_celdas_mal_asignadas()
    
    if (is.null(grillas_contaminadas_f5())) {
      return(tags$p(style = "color: #999; font-style: italic;", "⏳ Cargue el Excel de contaminadas primero"))
    }
    
    if (is.null(resultado)) {
      return(tags$p(style = "color: #999; font-style: italic;", "⏳ Ejecute la verificación espacial primero"))
    }
    
    if (!resultado$verificacion_posible) {
      return(tags$div(style = "padding: 10px; background-color: #e7f3ff; border-radius: 4px;",
        p(style = "color: #004085; margin: 0;", "ℹ️ El shapefile no contiene columna de celda. Verificación no disponible.")
      ))
    }
    
    if (resultado$n_mal_asignadas == 0) {
      return(tags$div(style = "padding: 10px; background-color: #d4edda; border-radius: 4px;",
        p(style = "color: #155724; margin: 0; font-weight: bold;", 
          "✅ Todas las grillas contaminadas tienen códigos correctos")
      ))
    }
    
    # Calcular cuántas contaminadas tienen código incorrecto
    grillas_cont_codigos <- unique(grillas_contaminadas_f5()$GRILLA)
    grillas_mal_codigos <- resultado$mal_asignadas$COD_GRILLA
    contaminadas_mal <- grillas_mal_codigos[grillas_mal_codigos %in% grillas_cont_codigos]
    n_contaminadas_mal <- length(contaminadas_mal)
    n_total_contaminadas <- length(grillas_cont_codigos)
    pct <- if (n_total_contaminadas > 0) (n_contaminadas_mal / n_total_contaminadas * 100) else 0
    
    if (n_contaminadas_mal == 0) {
      tags$div(style = "padding: 10px; background-color: #d4edda; border-radius: 4px;",
        p(style = "color: #155724; margin: 0; font-weight: bold;", 
          sprintf("✅ Las %d grillas contaminadas tienen códigos correctos", n_total_contaminadas))
      )
    } else {
      tags$div(style = "padding: 10px; background-color: #f8d7da; border-radius: 4px;",
        tags$table(style = "width: 100%;",
          tags$tr(
            tags$td("Total contaminadas:"),
            tags$td(style = "text-align: right; font-weight: bold;", n_total_contaminadas)
          ),
          tags$tr(
            tags$td(style = "color: #721c24; font-weight: bold;", "🚨 Con código INCORRECTO:"),
            tags$td(style = "text-align: right; color: #721c24; font-weight: bold; font-size: 16px;",
                   sprintf("%d (%.1f%%)", n_contaminadas_mal, pct))
          )
        )
      )
    }
  })
  
  # Tabla de grillas contaminadas con código INCORRECTO
  output$tabla_grillas_contaminadas_codigo <- renderDT({
    resultado <- resultado_celdas_mal_asignadas()
    
    if (is.null(grillas_contaminadas_f5()) || is.null(resultado)) {
      return(datatable(
        data.frame(Mensaje = "Cargue el Excel de contaminadas y ejecute la verificación espacial"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    if (!resultado$verificacion_posible) {
      return(datatable(
        data.frame(Mensaje = "El shapefile no contiene columna de celda. Verificación no disponible."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    if (resultado$n_mal_asignadas == 0) {
      return(datatable(
        data.frame(Mensaje = "✅ Todas las grillas contaminadas tienen códigos correctos"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    # Filtrar solo las contaminadas
    grillas_cont_codigos <- unique(grillas_contaminadas_f5()$GRILLA)
    mal_asignadas <- resultado$mal_asignadas %>%
      filter(COD_GRILLA %in% grillas_cont_codigos)
    
    if (nrow(mal_asignadas) == 0) {
      return(datatable(
        data.frame(Mensaje = "✅ Todas las grillas contaminadas tienen códigos correctos"),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(
      mal_asignadas,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    ) %>%
      formatStyle(
        columns = 1:ncol(mal_asignadas),
        target = 'row',
        backgroundColor = '#ffe6e6',
        fontWeight = 'bold'
      ) %>%
      formatStyle(
        'COD_GRILLA',
        backgroundColor = '#dc3545',
        color = 'white',
        fontWeight = 'bold'
      ) %>%
      formatStyle(
        'PROBLEMA',
        backgroundColor = styleEqual(
          c('Centroide fuera de celdas', 'Código de celda incorrecto'),
          c('#fff3cd', '#f8d7da')
        ),
        fontWeight = 'bold'
      )
  })
  
  # Handler de descarga - Marco de grillas limpio
  output$descargar_marco_grillas_limpio_btn <- downloadHandler(
    filename = function() {
      paste0("Marco_Grillas_LIMPIO_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
    },
    content = function(file) {
      tryCatch({
        resultado_fuera <- resultado_grillas_fuera()
        req(resultado_fuera)
        
        if (resultado_fuera$n_fuera == 0) {
          showNotification(
            "✅ No hay grillas para eliminar. El marco está limpio.",
            type = "message",
            duration = 5
          )
          # Exportar el shapefile original sin cambios
          shp_original <- shp_grillas_verif()
        } else {
          # Detectar columna de grilla
          shp_original <- shp_grillas_verif()
          col_grilla <- NULL
          if ("GRILLA" %in% names(shp_original)) {
            col_grilla <- "GRILLA"
          } else if ("COD_GRILLA" %in% names(shp_original)) {
            col_grilla <- "COD_GRILLA"
          }
          
          # Limpiar shapefile
          codigos_eliminar <- resultado_fuera$grillas_fuera$COD_GRILLA
          shp_limpio <- limpiar_shapefile_grillas(shp_original, codigos_eliminar, col_grilla = col_grilla)
          shp_original <- shp_limpio
        }
        
        # Convertir a 2D si es necesario
        if (any(st_is(shp_original, "3D"))) {
          shp_original <- st_zm(shp_original, drop = TRUE, what = "ZM")
        }
        
        # Validar geometrías
        if (any(!st_is_valid(shp_original))) {
          shp_original <- st_make_valid(shp_original)
        }
        
        # Crear directorio temporal
        temp_dir <- tempdir()
        temp_subdir <- file.path(temp_dir, paste0("grillas_limpio_", format(Sys.time(), "%Y%m%d_%H%M%S")))
        dir.create(temp_subdir, showWarnings = FALSE, recursive = TRUE)
        
        # Nombre base para archivos
        base_name <- "Marco_Grillas_LIMPIO"
        shp_path <- file.path(temp_subdir, paste0(base_name, ".shp"))
        
        # Escribir shapefile
        st_write(shp_original, shp_path, delete_dsn = TRUE, quiet = TRUE)
        
        # Crear ZIP
        shp_files <- list.files(temp_subdir, pattern = base_name, full.names = TRUE)
        zip::zip(file, files = basename(shp_files), root = temp_subdir)
        
        # Limpiar
        unlink(temp_subdir, recursive = TRUE)
        
        msg <- sprintf("✅ Marco limpio descargado (%d grillas eliminadas, %d grillas restantes)",
                      resultado_fuera$n_fuera,
                      resultado_fuera$n_total - resultado_fuera$n_fuera)
        showNotification(msg, type = "message", duration = 5)
        
      }, error = function(e) {
        cat("\n❌ ERROR al generar shapefile limpio:\n")
        print(e)
        showNotification(
          paste0("❌ Error al generar shapefile: ", conditionMessage(e)),
          type = "error",
          duration = 10
        )
      })
    }
  )
  
  # ============================================================================ #
  # FASE 3: CÁLCULO DEL TAMAÑO MUESTRAL                                        #
  # ============================================================================ #
  
  # Variables reactivas - Fase 3
  n_muestral <- reactiveVal(NULL)
  parametros_calculo <- reactiveVal(NULL)
  
  # Función para calcular el tamaño muestral
  observeEvent(input$calcular_n_btn, {
    req(marco_grillas())
    
    tryCatch({
      # Verificar si existen las variables necesarias
      if (!exists("base_tph_umbral_fil")) {
        # Si no existe, crear datos simulados para demostración
        base_tph_umbral_fil <<- data.frame(
          TPH = rnorm(100, mean = 500, sd = 100),
          locacion = sample(LETTERS[1:10], 100, replace = TRUE)
        )
        showNotification("Usando datos simulados para TPH", type = "warning")
      }
      
      if (!exists("DEFF_extended")) {
        DEFF_extended <<- 1.5  # Valor simulado
        showNotification("Usando valor simulado para DEFF_extended", type = "warning")
      }
      
      # Obtener valores de los inputs
      nivel_confianza <- input$nivel_confianza / 100  # Convertir a proporción
      Z <- qnorm(1 - (1 - nivel_confianza) / 2)  # Valor crítico de la distribución normal estándar
      TNR <- input$tasa_no_respuesta / 100  # Convertir a proporción
      
      # Calcular estadísticas de la variable TPH
      med <- mean(base_tph_umbral_fil$TPH, na.rm = TRUE)
      e <- (input$margen_error / 100) * med  # Margen de error como porcentaje de la media
      σ <- sd(base_tph_umbral_fil$TPH, na.rm = TRUE)  # Desviación estándar
      
      # Tamaño total de la población (número total de rejillas)
      N <- nrow(marco_grillas())
      
      # Cálculo del tamaño de muestra para poblaciones finitas
      n <- round(((N * Z ^ 2 * σ ^ 2) / (e ^ 2 * (N - 1) + Z ^ 2 * σ ^ 2)) * (1 / (1 - TNR)) * DEFF_extended)
      
      # Guardar el resultado y los parámetros
      n_muestral(n)
      
      parametros <- list(
        nivel_confianza = nivel_confianza * 100,
        Z = Z,
        TNR = TNR * 100,
        media = med,
        margen_error = input$margen_error,
        error_absoluto = e,
        desviacion_estandar = σ,
        N = N,
        DEFF = DEFF_extended,
        n = n
      )
      
      parametros_calculo(parametros)
      
      # Mostrar notificación de éxito
      showNotification("Tamaño muestral calculado exitosamente", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error al calcular el tamaño muestral:", e$message), type = "error")
    })
  })
  
  # Mostrar el resultado del cálculo del tamaño muestral
  output$resultado_n_muestral <- renderUI({
    req(n_muestral(), parametros_calculo())
    
    params <- parametros_calculo()
    
    # Calcular la cantidad de rejillas que representa la TNR
    rejillas_tnr <- floor(n_muestral() * (params$TNR / 100))
    
    tagList(
      tags$div(style = "font-size: 24px; margin-bottom: 20px;",
               "Tamaño muestral (n): ", tags$span(style = "font-weight: bold; color: #007bff;", n_muestral())),
      tags$div(style = "font-size: 18px; margin-bottom: 10px;",
               "Total de rejillas en el marco: ", tags$span(style = "font-weight: bold;", params$N)),
      tags$div(style = "font-size: 18px; margin-bottom: 10px;",
               "Rejillas que representan la TNR (", params$TNR, "%): ", 
               tags$span(style = "font-weight: bold; color: #dc3545;", rejillas_tnr))
    )
  })
  
  # Mostrar la fórmula utilizada con LaTeX
  output$formula_n_muestral <- renderUI({
    withMathJax(
      tags$div(
        "$$n = \\left( \\frac{N \\cdot Z^2 \\cdot \\sigma^2}{e^2 \\cdot (N-1) + Z^2 \\cdot \\sigma^2} \\right) \\cdot \\frac{1}{1-TNR} \\cdot DEFF$$",
        tags$br(),
        tags$br(),
        "Donde:",
        tags$ul(
          tags$li("\\(n\\) = Tamaño de la muestra"),
          tags$li("\\(N\\) = Tamaño de la población (total de rejillas)"),
          tags$li("\\(Z\\) = Valor crítico de la distribución normal estándar (nivel de confianza)"),
          tags$li("\\(\\sigma\\) = Desviación estándar de la población"),
          tags$li("\\(e\\) = Margen de error"),
          tags$li("\\(TNR\\) = Tasa de no respuesta"),
          tags$li("\\(DEFF\\) = Efecto de diseño")
        )
      )
    )
  })
  
  # Mostrar los parámetros utilizados en el cálculo
  output$parametros_n_muestral <- renderPrint({
    req(parametros_calculo())
    
    params <- parametros_calculo()
    
    cat("PARÁMETROS UTILIZADOS EN EL CÁLCULO:\n\n")
    cat("Nivel de confianza: ", params$nivel_confianza, "%\n")
    cat("Valor Z: ", round(params$Z, 4), "\n")
    cat("Tasa de no respuesta (TNR): ", params$TNR, "%\n")
    cat("Media de TPH: ", round(params$media, 2), "\n")
    cat("Margen de error: ", params$margen_error, "% de la media\n")
    cat("Error absoluto: ", round(params$error_absoluto, 2), "\n")
    cat("Desviación estándar: ", round(params$desviacion_estandar, 2), "\n")
    cat("Tamaño de la población (N): ", params$N, " rejillas\n")
    cat("Efecto de diseño (DEFF): ", round(params$DEFF, 4), "\n")
    cat("\n")
    cat("RESULTADO:\n")
    cat("Tamaño muestral (n): ", params$n, " rejillas\n")
  })
  
  # ============================================================================ #
  # GENERACIÓN DE RESUMEN DE TEXTO                                              #
  # ============================================================================ #
  observeEvent(input$generar_resumen_btn, {
    tryCatch({
      req(a_rejilla(), marco_grillas())
      
      # Datos base
      area_rej <- a_rejilla()
      mg <- marco_grillas()
      mc_fil <- marco_celdas_filtrado()
      
      # Locaciones evaluadas (preferir conteo_locaciones si existe)
      n_loc <- NA_integer_
      if (!is.null(conteo_locaciones())) {
        n_loc <- nrow(conteo_locaciones())
      } else if (!is.null(mc_fil)) {
        n_loc <- length(unique(mc_fil$LOCACION))
      } else {
        n_loc <- NA_integer_
      }
      
      # Marco final de grillas: restringir a celdas filtradas si existen
      total_rejillas_final <- NA_integer_
      if (!is.null(mc_fil)) {
        # Alinear tipos y limpiar espacios/mayúsculas para evitar conteos incorrectos
        ids_celdas_final <- unique(toupper(trimws(as.character(mc_fil$COD_CELDA))))
        mg_ids <- toupper(trimws(as.character(mg$COD_CELDA)))
        total_rejillas_final <- sum(mg_ids %in% ids_celdas_final, na.rm = TRUE)
        # Fallback si por alguna razón el conteo sale 0
        if (total_rejillas_final == 0 && !is.null(parametros_calculo())) {
          total_rejillas_final <- parametros_calculo()$N
        }
      } else {
        total_rejillas_final <- nrow(mg)
      }
      
      # Formateo de valores
      fmt_num <- function(x) format(x, big.mark = ",", decimal.mark = ".", scientific = FALSE)
      fmt_area <- function(x) paste0(gsub("\\.00$", "", format(round(x, 2), nsmall = 2, trim = TRUE)), " m²")
      
      area_txt <- fmt_area(area_rej)
      rejillas_txt <- fmt_num(total_rejillas_final)
      locaciones_txt <- fmt_num(n_loc)
      
      # Plantilla de texto del usuario con placeholders
      template <- paste0(
        "Para este expediente, la grilla base utilizada fue de {{AREA}}. ",
        "Sin embargo, debido a los recortes generados durante el procesamiento en el SIG, se obtuvieron áreas de dicho tamaño junto con zonas irregulares de menor superficie. ",
        "Cabe señalar que las grillas con un área inferior a 2 m² no son operativamente susceptibles de ser muestreadas, por lo que fueron descartadas durante la elaboración del marco muestral. ",
        "El total restante conformó un marco muestral de {{TOTAL_REJILLAS}}.\n",
        "La distribución de los puntos de muestreo se realizó mediante un diseño estadístico bietápico por conglomerados. ",
        "En la primera etapa, se seleccionaron aleatoriamente las celdas dentro de cada locación, asegurando al menos una celda por locación y una distribución proporcional. ",
        "En la segunda etapa, se eligieron aleatoriamente las rejillas dentro de las celdas seleccionadas, asignando inicialmente tres rejillas por celda y ajustando dicha asignación de forma proporcional según la disponibilidad de rejillas. ",
        "Este enfoque permitió capturar la complejidad espacial del fenómeno y asegurar la eficiencia estadística del estudio. ",
        "Los puntos de muestreo seleccionados se distribuyeron en las {{N_LOCACIONES}} locaciones del Lote X, según el siguiente detalle:"
      )
      
      # Reemplazos de placeholders
      texto <- template
      texto <- gsub("{{AREA}}", area_txt, texto, fixed = TRUE)
      texto <- gsub("{{TOTAL_REJILLAS}}", paste0(rejillas_txt, " rejillas"), texto, fixed = TRUE)
      texto <- gsub("{{N_LOCACIONES}}", locaciones_txt, texto, fixed = TRUE)
      
      texto_resumen(texto)
      showNotification("Texto generado para el Acta.", type = "message")
    }, error = function(e) {
      registrar_error(e, "Generación de Resumen de Texto")
      showNotification(paste("No fue posible generar el resumen:", conditionMessage(e)), type = "error")
    })
  })
  
  output$resumen_texto <- renderText({
    req(texto_resumen())
    texto_resumen()
  })
  
  output$descargar_resumen_btn <- downloadHandler(
    filename = function() {
      paste("Resumen_Muestreo-", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      txt <- texto_resumen()
      if (is.null(txt) || identical(txt, "")) {
        txt <- "No se ha generado ningún resumen aún."
      }
      writeLines(txt, file)
    }
  )
  
  # ============================================================================ #
  # FASE 4: MUESTREO BIETÁPICO                                                #
  # ============================================================================ #
  
  # Valores reactivos para almacenar los resultados del muestreo
  datos_finales_df <- reactiveVal(NULL)
  resumen_muestreo <- reactiveVal(NULL)
  
  # Variable reactiva para almacenar datos clave del muestreo
  datos_clave_muestreo <- reactiveVal(NULL)
  
  observeEvent(input$ejecutar_muestreo_btn, {
    req(marco_celdas(), marco_grillas(), n_muestral())
    
    showNotification("Iniciando Muestreo Bietápico...", type = "message")
    
    tryCatch({
      
      # Establecer la semilla para la reproducibilidad
      set.seed(input$seed_muestreo)
      
      # Cargar datos reactivos a variables locales
      mc <- marco_celdas()
      mg <- marco_grillas()
      n <- n_muestral()
      
      # 2. MUESTREO DE CELDAS
      # 2.1. Determinación de la cantidad de celdas a muestrear
      minimo_rejillas <- 3
      l_max <- floor(n / minimo_rejillas)
      l_min <- length(unique(mc$LOCACION))
      l <- floor(mean(c(l_min, l_max)))
      
      # 2.2. Repartición proporcional
      celdas_por_locacion <- mc %>%
        group_by(LOCACION) %>%
        summarise(total_celdas = n(), .groups = 'drop')
      
      celdas_asignadas <- celdas_por_locacion %>%
        mutate(celdas_a_muestrear = 1)
      
      celdas_restantes <- l - sum(celdas_asignadas$celdas_a_muestrear)
      
      celdas_asignadas <- celdas_asignadas %>%
        mutate(proporcion = total_celdas / sum(total_celdas),
               celdas_adicionales = floor(proporcion * celdas_restantes))
      
      diferencia <- celdas_restantes - sum(celdas_asignadas$celdas_adicionales)
      
      if (diferencia > 0) {
        celdas_asignadas <- celdas_asignadas %>%
          arrange(desc((proporcion * celdas_restantes) - floor(proporcion * celdas_restantes))) %>%
          mutate(celdas_adicionales = celdas_adicionales + ifelse(row_number() <= diferencia, 1, 0))
      }
      
      celdas_asignadas <- celdas_asignadas %>% 
        mutate(muestra_celdas = celdas_adicionales + celdas_a_muestrear) %>%
        dplyr::select(LOCACION, total_celdas, muestra_celdas)
      
      # 3.3. Primera etapa: muestreo aleatorio de celdas
      celdas_asignadas_df <- as.data.frame(celdas_asignadas)
      celdas_muestreadas_por_LOC <- list()
      
      for(i in 1:nrow(celdas_asignadas_df)){
        celdas_a_muestrear <- celdas_asignadas_df[i, "muestra_celdas"]
        id_LOC <- celdas_asignadas_df[i, "LOCACION"]
        
        if(celdas_a_muestrear > 0) {
          unidades_loc <- mc %>% filter(LOCACION == id_LOC)
          # Para Muestreo Aleatorio Simple (SRS), los tamaños deben ser iguales.
          # Se pasa un vector de 1s con la longitud del número de celdas.
          posicion_celda_selec <- S.piPS(celdas_a_muestrear, rep(1, nrow(unidades_loc)))[,1]
          filtrado_de_celdas <- unidades_loc %>% slice(posicion_celda_selec) %>% pull(COD_CELDA)
          celdas_muestreadas_por_LOC[[i]] <- filtrado_de_celdas
          names(celdas_muestreadas_por_LOC)[i] <- id_LOC
        }
      }
      
      celdas_muestreadas_por_LOC <- Filter(Negate(is.null), celdas_muestreadas_por_LOC)
      nombres_celdas_seleccionadas <- unlist(celdas_muestreadas_por_LOC)
      
      # 3. MUESTREO DE REJILLAS
      # 3.1. Repartición proporcional
      rejillas_por_celda <- mg %>%
        group_by(COD_CELDA) %>% summarise(total_rejillas = n(), .groups = 'drop') %>%
        filter(COD_CELDA %in% nombres_celdas_seleccionadas)

      rejillas_asignadas <- rejillas_por_celda %>% mutate(rejillas_a_muestrear = 3)
      rejillas_restantes <- n - sum(rejillas_asignadas$rejillas_a_muestrear)
      rejillas_asignadas <- rejillas_asignadas %>% mutate(proporcion = total_rejillas / sum(total_rejillas),
                                                          rejillas_adicionales = floor(proporcion * rejillas_restantes))
      diferencia_rejillas <- rejillas_restantes - sum(rejillas_asignadas$rejillas_adicionales)
      if (diferencia_rejillas > 0) {
        rejillas_asignadas <- rejillas_asignadas %>% arrange(desc((proporcion * rejillas_restantes) - floor(proporcion * rejillas_restantes))) %>% 
        mutate(rejillas_adicionales = rejillas_adicionales + ifelse(row_number() <= diferencia_rejillas, 1, 0))
      }
      rejillas_asignadas <- rejillas_asignadas %>% mutate(muestra_rejillas = rejillas_adicionales + rejillas_a_muestrear) %>% 
        dplyr::select(COD_CELDA, total_rejillas, muestra_rejillas)

      # Corrección de excesos
      rejillas_asignadas <- rejillas_asignadas %>% mutate(exceso = pmax(0, muestra_rejillas - total_rejillas),
                                                          muestra_rejillas = if_else(muestra_rejillas > total_rejillas, total_rejillas, muestra_rejillas))
      exceso_total <- sum(rejillas_asignadas$exceso)
      rejillas_asignadas <- rejillas_asignadas %>% dplyr::select(-exceso) %>% mutate(capacidad_restante = total_rejillas - muestra_rejillas)
      
      if (exceso_total > 0) {
        capacidad_total <- sum(rejillas_asignadas$capacidad_restante)
        if (capacidad_total > 0) {
          rejillas_asignadas <- rejillas_asignadas %>% mutate(prop_capacidad = if_else(capacidad_restante > 0, capacidad_restante / capacidad_total, 0),
                                                              asignar_exceso = floor(prop_capacidad * exceso_total))
          sobrante_exceso <- exceso_total - sum(rejillas_asignadas$asignar_exceso)
          if (sobrante_exceso > 0) {
            rejillas_asignadas <- rejillas_asignadas %>% arrange(desc((prop_capacidad * exceso_total) - floor(prop_capacidad * exceso_total))) %>% 
            mutate(asignar_exceso = asignar_exceso + ifelse(row_number() <= sobrante_exceso, 1, 0)) %>% arrange(COD_CELDA)
          }
          rejillas_asignadas <- rejillas_asignadas %>% mutate(muestra_rejillas = muestra_rejillas + asignar_exceso) %>% 
            dplyr::select(-prop_capacidad, -asignar_exceso)
        }
      }

      # 3.2. Segunda etapa: muestreo PPS de rejillas
      rejillas_asignadas_df <- as.data.frame(rejillas_asignadas)
      rejillas_muestreadas_por_celda <- list()
      
      for(i in 1:nrow(rejillas_asignadas_df)){
        rejillas_a_muestrear <- rejillas_asignadas_df[i, "muestra_rejillas"]
        ID_CELDA_m  <- rejillas_asignadas_df[i, "COD_CELDA"]
        
        if(rejillas_a_muestrear > 0) {
          unidades_celda <- mg %>% filter(COD_CELDA == ID_CELDA_m)
          # ATENCIÓN: Se implementa SRS porque la columna 'Puntaje' no está disponible.
          # Para un muestreo PPS, la columna con los tamaños debe existir en 'unidades_celda'.
          posicion_rejilla_selec <- S.piPS(rejillas_a_muestrear, rep(1, nrow(unidades_celda)))[,1]
          filtrado_de_rejillas <- unidades_celda %>% slice(posicion_rejilla_selec) %>% pull(COD_GRILLA)
          rejillas_muestreadas_por_celda[[i]] <- filtrado_de_rejillas
          names(rejillas_muestreadas_por_celda)[i] <- ID_CELDA_m
        }
      }
      
      rejillas_muestreadas_por_celda <- Filter(Negate(is.null), rejillas_muestreadas_por_celda)
      nombres_rejillas_seleccionadas <- unlist(rejillas_muestreadas_por_celda)
      
      # 5. VERIFICACIÓN DE MUESTRA
      datos_final <- mg %>% 
        filter(COD_GRILLA %in% nombres_rejillas_seleccionadas) %>%
        dplyr::select(LOCACION, COD_CELDA, COD_GRILLA, ESTE, NORTE, PROF, P_SUPERPOS)
      
      datos_finales_df(datos_final)
      
      # Generar resumen
      resumen_final <- capture.output({
        cat("Revisión final de n de rejillas y celdas en el excel\n")
        cat("-----------------------------------------------------\n")
        cat("Nº de locaciones únicas:", length(unique(datos_final$LOCACION)), "\n")
        cat("Nº de celdas únicas:", length(unique(datos_final$COD_CELDA)), "\n")
        cat("Nº de rejillas únicas (n final):", length(unique(datos_final$COD_GRILLA)), "\n\n")
        cat("Conteo de rejillas por locación:\n")
        print(datos_final %>% count(LOCACION) %>% arrange(n))
      })
      
      resumen_muestreo(paste(resumen_final, collapse = "\n"))
      
      # ========================================================================== #
      # CAPTURAR DATOS CLAVE PARA ACTA/INFORME
      # ========================================================================== #
      
      # Calcular rejillas uniformes y proporcionales
      n_celdas_seleccionadas <- length(unique(datos_final$COD_CELDA))
      rejillas_uniformes <- minimo_rejillas * n_celdas_seleccionadas
      rejillas_proporcionales <- n - rejillas_uniformes
      
      # Total de rejillas en marco original
      N_rejillas_poblacion <- nrow(mg)
      
      # Conteo de locaciones totales y las usadas
      n_locaciones_marco <- length(unique(mc$LOCACION))
      n_locaciones_en_muestra <- length(unique(datos_final$LOCACION))
      
      # Almacenar todos los datos clave
      datos_clave <- list(
        # Primera etapa - Selección de celdas
        n_rejillas = n,
        minimo_rejillas = minimo_rejillas,
        l_max = l_max,
        l_min = l_min,
        l = l,
        n_locaciones_marco = n_locaciones_marco,
        n_locaciones_muestra = n_locaciones_en_muestra,
        celdas_asignadas = celdas_asignadas,
        celdas_restantes = celdas_restantes,
        
        # Segunda etapa - Selección de rejillas
        n_celdas_seleccionadas = n_celdas_seleccionadas,
        rejillas_uniformes = rejillas_uniformes,
        rejillas_proporcionales = rejillas_proporcionales,
        rejillas_asignadas = rejillas_asignadas,
        N_rejillas_poblacion = N_rejillas_poblacion,
        
        # Resumen final
        n_locaciones_final = length(unique(datos_final$LOCACION)),
        n_celdas_final = length(unique(datos_final$COD_CELDA)),
        n_rejillas_final = length(unique(datos_final$COD_GRILLA)),
        
        # Fecha de ejecución
        fecha_muestreo = format(Sys.Date(), "%d/%m/%Y")
      )
      
      datos_clave_muestreo(datos_clave)
      
      showNotification("Muestreo Bietápico completado exitosamente.", type = "message")
      
    }, error = function(e) {
      registrar_error(e, "Muestreo Bietápico")
      showNotification(paste("Error en el muestreo bietápico:", conditionMessage(e)), type = "error")
      resumen_muestreo(paste("Error:", conditionMessage(e)))
    })
  })
  
  # Lógica para generar distancias a pozos
  observeEvent(input$generar_distancias_btn, {
    req(input$archivo_pozos_referencia, datos_finales_df())
    
    showNotification("Cargando pozos de referencia y calculando distancias...", type = "message")
    
    tryCatch({
      # Leer el archivo Excel de pozos de referencia
      pozos_data <- read_excel(input$archivo_pozos_referencia$datapath)
      
      # ==== APLICAR MAPEO DE COLUMNAS DEL USUARIO (Pozos de Referencia) ====
      if (!is.null(columnas_pozos_ref()) && !is.null(input$col_locacion_pozos)) {
        # Modo mapeo manual
        cat("✓ Usando mapeo manual de columnas (pozos de referencia)\n")
        
        col_locacion_usuario <- input$col_locacion_pozos
        col_este_usuario <- input$col_este_pozos
        col_norte_usuario <- input$col_norte_pozos
        col_altitud_usuario <- input$col_altitud_pozos
        
        # Validar que las columnas seleccionadas existen
        if (!col_locacion_usuario %in% names(pozos_data)) {
          stop(paste("La columna seleccionada para LOCACION no existe:", col_locacion_usuario))
        }
        if (!col_este_usuario %in% names(pozos_data)) {
          stop(paste("La columna seleccionada para ESTE no existe:", col_este_usuario))
        }
        if (!col_norte_usuario %in% names(pozos_data)) {
          stop(paste("La columna seleccionada para NORTE no existe:", col_norte_usuario))
        }
        if (!col_altitud_usuario %in% names(pozos_data)) {
          stop(paste("La columna seleccionada para ALTITUD no existe:", col_altitud_usuario))
        }
        
        # Crear dataframe con mapeo
        pozos_data_mapeado <- data.frame(
          LOCACION = pozos_data[[col_locacion_usuario]],
          ESTE = pozos_data[[col_este_usuario]],
          NORTE = pozos_data[[col_norte_usuario]],
          ALTITUD = pozos_data[[col_altitud_usuario]],
          stringsAsFactors = FALSE
        )
        
        # Copiar otras columnas que puedan existir
        otras_cols <- setdiff(names(pozos_data), c(col_locacion_usuario, col_este_usuario, col_norte_usuario, col_altitud_usuario))
        for (col in otras_cols) {
          if (!col %in% names(pozos_data_mapeado)) {
            pozos_data_mapeado[[col]] <- pozos_data[[col]]
          }
        }
        
        pozos_data <- pozos_data_mapeado
        
        # Notificación de mapeo aplicado
        showNotification(
          paste0("📍 Mapeo aplicado: ", col_locacion_usuario, " → LOCACION, ",
                 col_este_usuario, " → ESTE, ", col_norte_usuario, " → NORTE, ",
                 col_altitud_usuario, " → ALTITUD"),
          type = "message",
          duration = 4
        )
      } else {
        # Modo estandarización automática
        cat("✓ Usando estandarización automática de columnas (pozos de referencia)\n")
        pozos_data <- estandarizar_columnas(pozos_data)
        
        # Verificar que existan las columnas requeridas
        verificar_columnas_requeridas(pozos_data, c("LOCACION", "ESTE", "NORTE", "ALTITUD"), "archivo de pozos de referencia")
      }
      
      # Almacenar pozos de referencia
      pozos_referencia(pozos_data)
      
      # Obtener datos finales actuales
      datos_actuales <- datos_finales_df()
      
      # Calcular distancias y añadir altitudes
      datos_con_distancias <- añadir_distancias_pozos(datos_actuales, pozos_data)
      
      # Actualizar los datos finales con las nuevas columnas
      datos_finales_df(datos_con_distancias)
      datos_finales_con_distancias(datos_con_distancias)
      
      showNotification("Distancias y altitudes añadidas exitosamente a la muestra final.", type = "message")
      
    }, error = function(e) {
      registrar_error(e, "Generar distancias a pozos")
      showNotification(paste("Error al generar distancias:", conditionMessage(e)), type = "error")
    })
  })
  
  # Variables reactivas para las nuevas tablas
  estadisticas_generales <- reactive({
    req(datos_finales_df())
    datos_final <- datos_finales_df()
    
    data.frame(
      Estadística = c("Nº de locaciones únicas", "Nº de celdas únicas", "Nº de rejillas únicas (n final)"),
      Valor = c(
        length(unique(datos_final$LOCACION)),
        length(unique(datos_final$COD_CELDA)),
        length(unique(datos_final$COD_GRILLA))
      ),
      stringsAsFactors = FALSE
    )
  })
  
  conteo_rejillas_por_locacion <- reactive({
    req(datos_finales_df())
    datos_final <- datos_finales_df()
    
    datos_final %>% 
      count(LOCACION, name = "Número_de_Rejillas") %>% 
      arrange(Número_de_Rejillas)
  })
  
  # Mostrar tabla de estadísticas generales
  output$tabla_estadisticas_generales <- renderDT({
    req(estadisticas_generales())
    
    datatable(
      estadisticas_generales(),
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 't',  # Solo mostrar la tabla, sin controles
        ordering = FALSE
      ),
      rownames = FALSE
    ) %>%
    formatStyle(
      "Valor",
      fontWeight = "bold",
      color = "#007bff"
    )
  })
  
  # Mostrar tabla de conteo de rejillas por locación
  output$tabla_conteo_rejillas_locacion <- renderDT({
    req(conteo_rejillas_por_locacion())
    
    datatable(
      conteo_rejillas_por_locacion(),
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE
      ),
      rownames = FALSE
    ) %>%
    formatStyle(
      "Número_de_Rejillas",
      fontWeight = "bold"
    )
  })
  
  # Descargar tabla de conteo de rejillas por locación
  output$descargar_conteo_rejillas_btn <- downloadHandler(
    filename = function() {
      paste("Conteo_Rejillas_por_Locacion-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(conteo_rejillas_por_locacion())
      openxlsx::write.xlsx(conteo_rejillas_por_locacion(), file)
    }
  )
  
  # ========================================================================== #
  # OUTPUTS PARA DATOS CLAVE DEL ACTA/INFORME
  # ========================================================================== #
  
  # Indicador de disponibilidad de datos clave
  output$datos_clave_disponible <- reactive({
    !is.null(datos_clave_muestreo())
  })
  outputOptions(output, "datos_clave_disponible", suspendWhenHidden = FALSE)
  
  # Mensaje informativo sobre disponibilidad
  output$info_datos_clave_disponibles <- renderUI({
    if (is.null(datos_clave_muestreo())) {
      div(class = "alert alert-warning",
        h4("⚠️ Datos no disponibles"),
        p("Debe ejecutar primero el ", tags$b("Muestreo Bietápico"), " en la columna izquierda para generar los datos clave.")
      )
    } else {
      div(class = "alert alert-success",
        h4("✅ Datos clave generados exitosamente"),
        p("El texto markdown ha sido generado con los datos del muestreo ejecutado el ", 
          tags$b(datos_clave_muestreo()$fecha_muestreo), ".")
      )
    }
  })
  
  # Generar texto markdown con datos clave
  output$texto_datos_clave_markdown <- renderUI({
    req(datos_clave_muestreo())
    
    dk <- datos_clave_muestreo()
    
    # Generar texto markdown siguiendo exactamente la plantilla del usuario
    texto <- paste0(
      "Primera etapa del muestreo: Selección de celdas\n\n",
      
      "1. Se realizó la repartición proporcional de la cantidad de celdas a muestrear por locación se hizo asegurando el mínimo de una celda seleccionada por locación. Luego de ello, se aplicó un algoritmo simple para identificar el n muestral de celdas óptimo, con redondeo hacia abajo: se calculó el valor máximo de celdas que se pueden muestrear considerando el criterio de que cada celda tenga tres rejillas:\n\n",
      
      "   celdas_max = n / 3 = ", dk$n_rejillas, " / 3 = ", round(dk$l_max, 2), " = ", dk$l_max, " celdas\n\n",
      
      "2. Luego, el mínimo de celdas a muestrear, considerando el criterio de que se muestre al menos una celda por locación, siendo ", dk$n_locaciones_marco, " locaciones",
      if (dk$n_locaciones_marco != dk$n_locaciones_muestra) {
        paste0(". No obstante, algunas locaciones fueron descartadas por motivos operativos. En consecuencia, para efectos prácticos en los cálculos, se consideraron ", dk$n_locaciones_muestra, " locaciones")
      } else {
        ""
      },
      ":\n\n",
      
      "   celdas_min = ", dk$l_min, " celdas\n\n",
      
      "3. Finalmente, se obtuvo la mediana, que para este caso es igual que el promedio, de esos dos valores:\n\n",
      
      "   l = mediana(", dk$l_min, ", ", dk$l_max, ") = ", dk$l, " celdas\n\n",
      
      "4. A cada una de las ", dk$n_locaciones_muestra, " locaciones se le asignó inicialmente una celda. Luego, las ", dk$celdas_restantes, " celdas restantes se distribuyeron proporcionalmente según la cantidad total de celdas que tiene cada locación. Es decir, las locaciones con más celdas recibieron una mayor parte de la muestra adicional. El cálculo se realizó de la siguiente manera: primero, se determinó qué proporción del total de celdas representa cada locación (un valor entre 0 y 1). Luego, esa proporción se aplicó a las ", dk$celdas_restantes, " celdas restantes para calcular cuántas celdas adicionales le correspondían a cada una.\n\n",
      
      "5. Teniendo el número exacto de celdas a muestrear que cada locación debe tener, se empleó el algoritmo S.piPS del paquete TeachingSampling en R (Rojas, 2020), garantizando una selección probabilística. Esta función seleccionó aleatoriamente, con probabilidad igual para todos los elementos a ser muestreados, los códigos de las celdas del marco muestral que formarán parte de la muestra.\n\n",
      
      "Segunda etapa del muestreo: Selección de rejillas dentro de las celdas seleccionadas\n\n",
      
      "6. La cantidad de rejillas a muestrear dentro de las celdas seleccionadas fue calculada anteriormente como \"n\" muestral: ", dk$n_rejillas, " rejillas a seleccionar. Para la repartición, se aplicó el criterio de asignar ", dk$minimo_rejillas, " rejillas. Considerando que son ", dk$n_celdas_seleccionadas, " celdas, el total de celdas a repartir uniformemente fue de ", dk$rejillas_uniformes, ". Las restantes ", dk$rejillas_proporcionales, " se asignaron con repartición proporcional a la cantidad de rejillas de cada celda. Celdas con mayor cantidad de rejillas recibieron mayor parte de la muestra de rejillas.\n\n",
      
      "7. Tras conocer el número de rejillas exacto que cada celda muestreada debe tener, se aplicó el mismo principio de muestreo: muestreo aleatorio de las rejillas con el algoritmo S.piPS del paquete TeachingSampling en R (Rojas, 2020). Nuevamente, la función seleccionó aleatoriamente, con probabilidad igual para todos los elementos a ser muestreados, los códigos de las rejillas del marco muestral que formarán parte de la muestra.\n\n",
      
      "8. La muestra, consistente de los códigos de las ", dk$n_rejillas_final, " rejillas, y sus respectivos códigos de celdas y locación a las que pertenecen, fue exportada en formato Excel para su procesamiento posterior.\n\n",
      
      "9. En adición se añadieron treinta y siete (37) rejillas en diecisiete (17) locaciones a juicio de experto a fin de tener una muestra representativa de las celdas evaluadas. Por lo que finalmente el número total de puntos de muestreo establecidos fue de quinientos sesenta y dos (562) rejillas.\n\n",
      
      "---\n\n",
      "RESUMEN EJECUTIVO\n\n",
      "- Población total (N): ", format(dk$N_rejillas_poblacion, big.mark = ","), " rejillas\n",
      "- Muestra calculada (n): ", dk$n_rejillas, " rejillas\n",
      "- Locaciones en el marco: ", dk$n_locaciones_marco, "\n",
      "- Locaciones consideradas para el muestreo: ", dk$n_locaciones_muestra, "\n",
      "- Celdas seleccionadas (l): ", dk$n_celdas_final, "\n",
      "- Tasa de muestreo: ", round(dk$n_rejillas / dk$N_rejillas_poblacion * 100, 2), "%\n\n",
      
      "---\n",
      "*Documento generado automáticamente el ", format(Sys.time(), "%d/%m/%Y %H:%M:%S"), "*"
    )
    
    # Retornar como HTML con formato pre
    tags$pre(
      style = "margin: 0; padding: 0; font-family: 'Courier New', monospace; font-size: 13px; white-space: pre-wrap; word-wrap: break-word;",
      texto
    )
  })
  
  # Handler de descarga del texto markdown
  output$descargar_texto_acta_btn <- downloadHandler(
    filename = function() {
      paste0("Datos_Clave_Muestreo_Bietapico-", format(Sys.Date(), "%Y%m%d"), ".txt")
    },
    content = function(file) {
      req(datos_clave_muestreo())
      
      dk <- datos_clave_muestreo()
      
      # Generar texto siguiendo exactamente la plantilla del usuario
      texto <- paste0(
        "Primera etapa del muestreo: Selección de celdas\n\n",
        
        "1. Se realizó la repartición proporcional de la cantidad de celdas a muestrear por locación se hizo asegurando el mínimo de una celda seleccionada por locación. Luego de ello, se aplicó un algoritmo simple para identificar el n muestral de celdas óptimo, con redondeo hacia abajo: se calculó el valor máximo de celdas que se pueden muestrear considerando el criterio de que cada celda tenga tres rejillas:\n\n",
        
        "   celdas_max = n / 3 = ", dk$n_rejillas, " / 3 = ", round(dk$l_max, 2), " = ", dk$l_max, " celdas\n\n",
        
        "2. Luego, el mínimo de celdas a muestrear, considerando el criterio de que se muestre al menos una celda por locación, siendo ", dk$n_locaciones_marco, " locaciones",
        if (dk$n_locaciones_marco != dk$n_locaciones_muestra) {
          paste0(". No obstante, algunas locaciones fueron descartadas por motivos operativos. En consecuencia, para efectos prácticos en los cálculos, se consideraron ", dk$n_locaciones_muestra, " locaciones")
        } else {
          ""
        },
        ":\n\n",
        
        "   celdas_min = ", dk$l_min, " celdas\n\n",
        
        "3. Finalmente, se obtuvo la mediana, que para este caso es igual que el promedio, de esos dos valores:\n\n",
        
        "   l = mediana(", dk$l_min, ", ", dk$l_max, ") = ", dk$l, " celdas\n\n",
        
        "4. A cada una de las ", dk$n_locaciones_muestra, " locaciones se le asignó inicialmente una celda. Luego, las ", dk$celdas_restantes, " celdas restantes se distribuyeron proporcionalmente según la cantidad total de celdas que tiene cada locación. Es decir, las locaciones con más celdas recibieron una mayor parte de la muestra adicional. El cálculo se realizó de la siguiente manera: primero, se determinó qué proporción del total de celdas representa cada locación (un valor entre 0 y 1). Luego, esa proporción se aplicó a las ", dk$celdas_restantes, " celdas restantes para calcular cuántas celdas adicionales le correspondían a cada una.\n\n",
        
        "5. Teniendo el número exacto de celdas a muestrear que cada locación debe tener, se empleó el algoritmo S.piPS del paquete TeachingSampling en R (Rojas, 2020), garantizando una selección probabilística. Esta función seleccionó aleatoriamente, con probabilidad igual para todos los elementos a ser muestreados, los códigos de las celdas del marco muestral que formarán parte de la muestra.\n\n",
        
        "Segunda etapa del muestreo: Selección de rejillas dentro de las celdas seleccionadas\n\n",
        
        "6. La cantidad de rejillas a muestrear dentro de las celdas seleccionadas fue calculada anteriormente como \"n\" muestral: ", dk$n_rejillas, " rejillas a seleccionar. Para la repartición, se aplicó el criterio de asignar ", dk$minimo_rejillas, " rejillas. Considerando que son ", dk$n_celdas_seleccionadas, " celdas, el total de celdas a repartir uniformemente fue de ", dk$rejillas_uniformes, ". Las restantes ", dk$rejillas_proporcionales, " se asignaron con repartición proporcional a la cantidad de rejillas de cada celda. Celdas con mayor cantidad de rejillas recibieron mayor parte de la muestra de rejillas.\n\n",
        
        "7. Tras conocer el número de rejillas exacto que cada celda muestreada debe tener, se aplicó el mismo principio de muestreo: muestreo aleatorio de las rejillas con el algoritmo S.piPS del paquete TeachingSampling en R (Rojas, 2020). Nuevamente, la función seleccionó aleatoriamente, con probabilidad igual para todos los elementos a ser muestreados, los códigos de las rejillas del marco muestral que formarán parte de la muestra.\n\n",
        
        "8. La muestra, consistente de los códigos de las ", dk$n_rejillas_final, " rejillas, y sus respectivos códigos de celdas y locación a las que pertenecen, fue exportada en formato Excel para su procesamiento posterior.\n\n",
        
        "9. En adición se añadieron treinta y siete (37) rejillas en diecisiete (17) locaciones a juicio de experto a fin de tener una muestra representativa de las celdas evaluadas. Por lo que finalmente el número total de puntos de muestreo establecidos fue de quinientos sesenta y dos (562) rejillas.\n\n",
        
        "---\n\n",
        "RESUMEN EJECUTIVO\n\n",
        "- Población total (N): ", format(dk$N_rejillas_poblacion, big.mark = ","), " rejillas\n",
        "- Muestra calculada (n): ", dk$n_rejillas, " rejillas\n",
        "- Locaciones en el marco: ", dk$n_locaciones_marco, "\n",
        "- Locaciones consideradas para el muestreo: ", dk$n_locaciones_muestra, "\n",
        "- Celdas seleccionadas (l): ", dk$n_celdas_final, "\n",
        "- Tasa de muestreo: ", round(dk$n_rejillas / dk$N_rejillas_poblacion * 100, 2), "%\n\n",
        
        "---\n",
        "*Documento generado automáticamente el ", format(Sys.time(), "%d/%m/%Y %H:%M:%S"), "*"
      )
      
      writeLines(texto, file, useBytes = TRUE)
    }
  )
  
  # Mostrar tabla de muestra final
  output$tabla_muestra_final <- renderDT({
    req(datos_finales_df())
    
    datos <- datos_finales_df()
    
    dt <- datatable(
      datos,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE,
        columnDefs = list(
          list(width = "300px", targets = which(names(datos) == "DISTANCIA") - 1)  # Hacer columna DISTANCIA más ancha
        )
      ),
      rownames = FALSE
    )
    
    # Aplicar formato especial si existen las columnas DISTANCIA y ALTITUD
    if ("DISTANCIA" %in% names(datos)) {
      dt <- dt %>% formatStyle(
        "DISTANCIA",
        fontSize = "12px",
        whiteSpace = "normal",
        wordWrap = "break-word"
      )
    }
    
    if ("ALTITUD" %in% names(datos)) {
      dt <- dt %>% formatStyle(
        "ALTITUD",
        fontWeight = "bold",
        color = "#28a745"
      )
    }
    
    return(dt)
  })
  
  # Función auxiliar para encontrar un "orden de visita" por vecino más cercano
  nearest_neighbor_order <- function(x, y) {
    n <- length(x)
    if (n == 0) return(integer(0))
    if (n == 1) return(1L)
    
    indices_disponibles <- seq_len(n)
    idx_inicial <- order(x, y)[1]
    
    orden <- integer(n)
    current_idx_in_disponibles <- which(indices_disponibles == idx_inicial)
    
    for (i in seq_len(n)) {
      original_idx <- indices_disponibles[current_idx_in_disponibles]
      orden[i] <- original_idx
      
      indices_disponibles <- indices_disponibles[-current_idx_in_disponibles]
      
      if (length(indices_disponibles) == 0) break
      
      distancias <- sqrt((x[original_idx] - x[indices_disponibles])^2 + 
                         (y[original_idx] - y[indices_disponibles])^2)
      
      current_idx_in_disponibles <- which.min(distancias)
    }
    
    return(orden)
  }

  # Lógica para añadir códigos de campo
  observeEvent(input$generar_codigos_btn, {
    req(datos_finales_df())

    if ("COD_PUNTO_CAMPO" %in% names(datos_finales_df())) {
      showNotification("Los códigos de campo ya han sido generados.", type = "warning")
      return()
    }

    showNotification("Generando códigos de campo y colectora...", type = "message", duration = 5)

    tryCatch({
      datosFINAL <- datos_finales_df()

      datosFINAL_result <- datosFINAL %>%
        group_by(LOCACION) %>%
        group_map(.f = function(df_loc, key_loc) {
          # A) dbscan para agrupar puntos
          clustering <- dbscan(as.matrix(df_loc[, c("ESTE", "NORTE")]), eps = 10, minPts = 1)
          df_loc$cluster_id <- clustering$cluster

          # B) Calcular centroides y su orden
          centroides <- df_loc %>%
            group_by(cluster_id) %>%
            summarize(cE = mean(ESTE), cN = mean(NORTE), .groups = "drop") %>%
            arrange(cE, cN) %>%
            mutate(cluster_orden = row_number())

          # C) Unir el orden del cluster
          df_loc <- df_loc %>% left_join(centroides %>% dplyr::select(cluster_id, cluster_orden), by = "cluster_id")

          # D) Ordenar puntos dentro de cada cluster
          df_loc_ordenado <- df_loc %>%
            group_by(cluster_orden) %>%
            group_modify(.f = function(dcluster, key_cl) {
              idx_orden_local <- nearest_neighbor_order(dcluster$ESTE, dcluster$NORTE)
              dcluster$orden_en_cluster <- seq_len(nrow(dcluster))[order(idx_orden_local)]
              return(dcluster)
            }) %>%
            ungroup() %>%
            arrange(cluster_orden, orden_en_cluster)

          # E) Número correlativo final y código
          df_loc_ordenado <- df_loc_ordenado %>%
            mutate(num_final = row_number(),
                   COD_GRILLA_NUMERADA_ESPACIALMENTE = paste0(key_loc$LOCACION, "-", num_final),
                   LOCACION = key_loc$LOCACION) # Re-añadir la columna de agrupación

          return(df_loc_ordenado)
        }) %>%
        bind_rows()

      # F) Crear códigos finales y seleccionar columnas
      datosFINAL_result <- datosFINAL_result %>%
        mutate(
          COD_PUNTO_CAMPO = paste0(
            "L-X,6,",
            ifelse(grepl("^(MNF|MC|BAT|QDA)", LOCACION, ignore.case = TRUE), "", "PZ"),
            COD_GRILLA_NUMERADA_ESPACIALMENTE
          ),
          # La colectora debe ser estable e independiente del prefijo PZ
          COD_COLECTORA = COD_GRILLA_NUMERADA_ESPACIALMENTE
        )
      
      # Seleccionar columnas base y añadir DISTANCIA y ALTITUD si existen
      columnas_base <- c("LOCACION", "COD_CELDA", "COD_GRILLA", "ESTE", "NORTE", "PROF", "P_SUPERPOS", "COD_PUNTO_CAMPO", "COD_COLECTORA")
      columnas_adicionales <- c("DISTANCIA", "ALTITUD")
      columnas_existentes <- columnas_adicionales[columnas_adicionales %in% names(datosFINAL_result)]
      columnas_finales <- c(columnas_base, columnas_existentes)
      
      datosFINAL_result <- datosFINAL_result %>%
        dplyr::select(all_of(columnas_finales))

      datos_finales_df(datosFINAL_result)

      showNotification("Códigos generados y añadidos a la tabla.", type = "message")
    }, error = function(e) {
      registrar_error(e, "Generación de Códigos")
      showNotification(paste("Error al generar códigos:", conditionMessage(e)), type = "error")
    })
  })

  # Handlers para descargar tablas de verificación de marcos
  
  # 1. Conteo de Celdas por Locación
  output$download_conteo_celdas <- downloadHandler(
    filename = function() {
      paste("Conteo_Celdas_por_Locacion-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(conteo_celdas_por_locacion())
      openxlsx::write.xlsx(conteo_celdas_por_locacion(), file)
    }
  )
  
  # 2. Locaciones sin Celdas
  output$download_locaciones_sin_celdas <- downloadHandler(
    filename = function() {
      paste("Locaciones_sin_Celdas-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(conteo_celdas_por_locacion())
      # Identificar locaciones con 0 celdas (si las hubiera)
      locaciones_cero <- conteo_celdas_por_locacion() %>%
        filter(n == 0)
      
      if (nrow(locaciones_cero) > 0) {
        openxlsx::write.xlsx(locaciones_cero, file)
      } else {
        # Crear un dataframe con un mensaje si no hay locaciones sin celdas
        df_mensaje <- data.frame(mensaje = "Todas las locaciones tienen al menos una celda.")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # 3. Conteo de Grillas por Celda
  output$download_conteo_grillas <- downloadHandler(
    filename = function() {
      paste("Conteo_Grillas_por_Celda-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(conteo_grillas_por_celda())
      openxlsx::write.xlsx(conteo_grillas_por_celda(), file)
    }
  )
  
  # 4. Celdas con menos de 3 Grillas
  output$download_celdas_pocas_grillas <- downloadHandler(
    filename = function() {
      paste("Celdas_con_menos_de_3_Grillas-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(conteo_grillas_por_celda())
      # Filtrar directamente las celdas con menos de 3 grillas
      celdas_pocas <- conteo_grillas_por_celda() %>%
        filter(n < 3)
      
      if (nrow(celdas_pocas) > 0) {
        openxlsx::write.xlsx(celdas_pocas, file)
      } else {
        # Crear un dataframe con un mensaje si no hay celdas con pocas grillas
        df_mensaje <- data.frame(mensaje = "Todas las celdas tienen al menos 3 grillas.")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # 5. Celdas en marco_celdas pero no en marco_grillas
  output$download_celdas_no_en_grillas <- downloadHandler(
    filename = function() {
      paste("Celdas_en_marco_celdas_no_en_grillas-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(marco_celdas(), celdas_solo_en_marco_celdas())
      
      if (length(celdas_solo_en_marco_celdas()) > 0) {
        celdas_filtradas <- marco_celdas() %>%
          filter(COD_CELDA %in% celdas_solo_en_marco_celdas())
        openxlsx::write.xlsx(celdas_filtradas, file)
      } else {
        # Crear un dataframe con un mensaje si no hay celdas solo en marco_celdas
        df_mensaje <- data.frame(mensaje = "No hay celdas que estén solo en marco_celdas")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # 6. Celdas en marco_grillas pero no en marco_celdas
  output$download_celdas_no_en_marco <- downloadHandler(
    filename = function() {
      paste("Celdas_en_marco_grillas_no_en_celdas-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(marco_grillas(), celdas_solo_en_marco_grillas())
      
      if (length(celdas_solo_en_marco_grillas()) > 0) {
        grillas_filtradas <- marco_grillas() %>%
          filter(COD_CELDA %in% celdas_solo_en_marco_grillas()) %>%
          distinct(COD_CELDA, .keep_all = TRUE)
        openxlsx::write.xlsx(grillas_filtradas, file)
      } else {
        # Crear un dataframe con un mensaje si no hay celdas solo en marco_grillas
        df_mensaje <- data.frame(mensaje = "No hay celdas que estén solo en marco_grillas")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # ============================================================================ #
  # DOWNLOAD HANDLERS PARA REVISIÓN DE PROFUNDIDADES - FASE 2                 #
  # ============================================================================ #
  
  # 7. Celdas con profundidades inconsistentes
  output$download_prof_inconsistentes <- downloadHandler(
    filename = function() {
      paste("Celdas_Profundidades_Inconsistentes-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(celdas_profundidades_inconsistentes())
      
      if (nrow(celdas_profundidades_inconsistentes()) > 0) {
        openxlsx::write.xlsx(celdas_profundidades_inconsistentes(), file)
      } else {
        df_mensaje <- data.frame(Mensaje = "✅ No hay celdas con profundidades inconsistentes")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # 8. Grillas con profundidad inválida
  output$download_grillas_prof_invalida <- downloadHandler(
    filename = function() {
      paste("Grillas_Profundidad_Invalida-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(grillas_prof_invalida())
      
      if (nrow(grillas_prof_invalida()) > 0) {
        openxlsx::write.xlsx(grillas_prof_invalida(), file)
      } else {
        df_mensaje <- data.frame(Mensaje = "✅ Todas las grillas tienen profundidad válida")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # 9. Celdas con profundidad inválida
  output$download_celdas_prof_invalida <- downloadHandler(
    filename = function() {
      paste("Celdas_Profundidad_Invalida-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(celdas_prof_invalida())
      
      if (nrow(celdas_prof_invalida()) > 0) {
        openxlsx::write.xlsx(celdas_prof_invalida(), file)
      } else {
        df_mensaje <- data.frame(Mensaje = "✅ Todas las celdas tienen profundidad válida")
        openxlsx::write.xlsx(df_mensaje, file)
      }
    }
  )
  
  # Manejador de descarga para archivo Shapefile
  output$descargar_shp_btn <- downloadHandler(
    filename = function() {
      paste0("MuestraFinal_ConCodigos-", Sys.Date(), ".zip")
    },
    content = function(file) {
      req(datos_finales_df())
      
      showNotification("Preparando archivo Shapefile...", type = "message", duration = 5)
      
      tryCatch({
        # Asegurarse de que las columnas de coordenadas existan
        if (!all(c("ESTE", "NORTE") %in% names(datos_finales_df()))) {
          showNotification("Las columnas 'ESTE' y 'NORTE' son necesarias para el Shapefile.", type = "error")
          return(NULL)
        }

        # Convertir a objeto sf
        pts_sf <- st_as_sf(
          datos_finales_df(),
          coords = c("ESTE", "NORTE"),
          crs = 32717    # EPSG para WGS84 / UTM zona 17S
        )
        
        # Crear un directorio temporal para los archivos del shapefile
        temp_dir <- tempdir()
        shp_path <- file.path(temp_dir, "muestra_final.shp")
        
        # Escribir el shapefile
        st_write(
          obj = pts_sf,
          dsn = shp_path,
          delete_layer = TRUE # Sobrescribir si existe
        )
        
        # Listar todos los archivos componentes del shapefile
        files_to_zip <- list.files(temp_dir, pattern = "muestra_final\\..*", full.names = TRUE)
        
        # Comprimir los archivos en un .zip
        zip(zipfile = file, files = files_to_zip, flags = "-j") # -j para no guardar rutas
      }, error = function(e) {
        registrar_error(e$message, "Generación de Shapefile")
        showNotification(paste("Error al generar el Shapefile:", e$message), type = "error")
      })
    }
  )

  # Manejador de descarga para archivo Excel
  output$descargar_muestra_btn <- downloadHandler(
    filename = function() {
      paste("MuestraFinal_ConCodigos-", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(datos_finales_df())
      # Usar write.xlsx para una exportación directa y simple
      openxlsx::write.xlsx(datos_finales_df(), file)
    }
  )

  output$parametros_n_muestral <- renderPrint({
    req(parametros_calculo())
    
    params <- parametros_calculo()
    
    cat("PARÁMETROS UTILIZADOS EN EL CÁLCULO:\n\n")
    cat("Nivel de confianza: ", params$nivel_confianza, "%\n")
    cat("Valor Z: ", round(params$Z, 4), "\n")
    cat("Tasa de no respuesta (TNR): ", params$TNR, "%\n")
    cat("Media de TPH: ", round(params$media, 2), "\n")
    cat("Margen de error: ", params$margen_error, "% de la media\n")
    cat("Error absoluto: ", round(params$error_absoluto, 2), "\n")
    cat("Desviación estándar: ", round(params$desviacion_estandar, 2), "\n")
    cat("Tamaño de la población (N): ", params$N, " rejillas\n")
    cat("Efecto de diseño (DEFF): ", round(params$DEFF, 4), "\n")
    cat("\n")
    cat("RESULTADO:\n")
    cat("Tamaño muestral (n): ", params$n, " rejillas\n")
  })
  
  # ============================================================================ #
  # FASE 5: ANÁLISIS DE RESULTADOS DE LABORATORIO                              #
  # ============================================================================ #
  
  # Variables reactivas - Fase 5
  muestra_enriquecida <- reactiveVal(NULL)
  diagnostico_enriquecimiento <- reactiveVal(NULL)  # NUEVO: captura problemas de match
  promedios_celdas_resultado <- reactiveVal(NULL)
  promedios_locaciones_resultado <- reactiveVal(NULL)
  vertices_grillas_resultado <- reactiveVal(NULL)
  vertices_celdas_tph_resultado <- reactiveVal(NULL)
  vertices_celdas_prop_resultado <- reactiveVal(NULL)
  # Variables para análisis unificado (con exclusión jerárquica)
  vertices_grillas_unificado <- reactiveVal(NULL)
  vertices_celdas_unificado <- reactiveVal(NULL)
  
  # Variables reactivas para shapefiles
  shp_grillas_data <- reactiveVal(NULL)
  shp_celdas_data <- reactiveVal(NULL)
  columnas_shp_grillas <- reactiveVal(NULL)
  columnas_shp_celdas <- reactiveVal(NULL)
  
  # Variables reactivas para mapeo de columnas de archivos Excel
  columnas_resultados_lab <- reactiveVal(NULL)
  columnas_coordenadas <- reactiveVal(NULL)
  columnas_muestra_final <- reactiveVal(NULL)
  columnas_marco_grillas_shp_caso1 <- reactiveVal(NULL)
  columnas_pozos_ref <- reactiveVal(NULL)  # Para archivo de pozos en Fase 4C
  
  # ============================================================================ #
  # OBSERVERS PARA DETECTAR CARGA DE ARCHIVOS Y CAPTURAR COLUMNAS              #
  # ============================================================================ #
  
  # Observer para archivo de resultados de laboratorio
  observeEvent(input$archivo_resultados_lab, {
    req(input$archivo_resultados_lab)
    tryCatch({
      datos <- read_excel(input$archivo_resultados_lab$datapath, n_max = 1)
      columnas_resultados_lab(names(datos))
    }, error = function(e) {
      columnas_resultados_lab(NULL)
    })
  })
  
  # Observer para archivo de coordenadas (Caso 1)
  observeEvent(input$archivo_coordenadas, {
    req(input$archivo_coordenadas)
    tryCatch({
      datos <- read_excel(input$archivo_coordenadas$datapath, n_max = 1)
      columnas_coordenadas(names(datos))
    }, error = function(e) {
      columnas_coordenadas(NULL)
    })
  })
  
  # Observer para archivo de muestra final (Caso 2)
  observeEvent(input$archivo_muestra_final, {
    req(input$archivo_muestra_final)
    tryCatch({
      datos <- read_excel(input$archivo_muestra_final$datapath, n_max = 1)
      columnas_muestra_final(names(datos))
    }, error = function(e) {
      columnas_muestra_final(NULL)
    })
  })
  
  # Observer para shapefile de marco de grillas (Caso 1)
  observeEvent(input$archivo_marco_grillas_shp, {
    req(input$archivo_marco_grillas_shp)
    tryCatch({
      temp_dir <- file.path(tempdir(), "preview_shp", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(input$archivo_marco_grillas_shp$datapath, exdir = temp_dir)
      shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
      
      if (length(shp_files) > 0) {
        shp <- st_read(shp_files[1], quiet = TRUE)
        columnas_marco_grillas_shp_caso1(names(shp))
      }
    }, error = function(e) {
      columnas_marco_grillas_shp_caso1(NULL)
    })
  })
  
  # Observer para archivo de pozos de referencia (Fase 4C)
  observeEvent(input$archivo_pozos_referencia, {
    req(input$archivo_pozos_referencia)
    tryCatch({
      datos <- read_excel(input$archivo_pozos_referencia$datapath, n_max = 1)
      columnas_pozos_ref(names(datos))
    }, error = function(e) {
      columnas_pozos_ref(NULL)
    })
  })
  
  # ============================================================================ #
  # OUTPUTS PARA MAPEO DE COLUMNAS                                             #
  # ============================================================================ #
  
  # Mapeo de columnas para resultados de laboratorio
  output$mapeo_columnas_lab_ui <- renderUI({
    req(columnas_resultados_lab())
    
    cols <- columnas_resultados_lab()
    cols_upper <- toupper(cols)
    
    # Detectar columnas sugeridas
    patrones_punto <- c("PUNTO", "PUNTOS", "COD_PUNTO", "CODIGO_PUNTO", "POINT", "ID")
    patrones_tph <- c("TPH", "HIDROCARBUROS", "HC")
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_prof <- c("PROF", "PROFUNDIDAD", "DEPTH")
    
    col_punto_sugerida <- detectar_columna_candidata(cols, patrones_punto)
    col_tph_sugerida <- detectar_columna_candidata(cols, patrones_tph)
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_prof_sugerida <- detectar_columna_candidata(cols, patrones_prof)
    
    # Verificar columnas críticas
    tiene_punto <- any(grepl("PUNTO|POINT", cols_upper))
    tiene_tph <- any(grepl("TPH|HIDROCARB", cols_upper))
    
    mensaje_advertencia <- if (!tiene_punto || !tiene_tph) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        if (!tiene_punto) "No se detectó columna 'PUNTO'. " else "",
        if (!tiene_tph) "No se detectó columna 'TPH'. " else "",
        "Columnas: ", paste(head(cols, 5), collapse = ", "),
        if (length(cols) > 5) "..." else ""
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Columnas detectadas correctamente"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #0066cc; margin-bottom: 5px;"),
      selectInput("col_punto_lab", "Columna PUNTO:", choices = cols, selected = col_punto_sugerida),
      selectInput("col_tph_lab", "Columna TPH:", choices = cols, selected = col_tph_sugerida),
      selectInput("col_locacion_lab", "Columna LOCACION:", choices = cols, selected = col_locacion_sugerida),
      selectInput("col_prof_lab", "Columna PROFUNDIDAD:", choices = cols, selected = col_prof_sugerida)
    )
  })
  
  # Mapeo de columnas para coordenadas (Caso 1)
  output$mapeo_columnas_coords_ui <- renderUI({
    req(columnas_coordenadas())
    
    cols <- columnas_coordenadas()
    cols_upper <- toupper(cols)
    
    patrones_punto <- c("PUNTO", "PUNTOS", "COD_PUNTO", "POINT", "ID")
    patrones_norte <- c("NORTE", "NORTH", "Y", "COORD_Y", "NORTHING")
    patrones_este <- c("ESTE", "EAST", "X", "COORD_X", "EASTING")
    patrones_altitud <- c("ALTITUD", "ALTITUDE", "ELEVACION", "ELEVATION", "Z")
    
    col_punto_sugerida <- detectar_columna_candidata(cols, patrones_punto)
    col_norte_sugerida <- detectar_columna_candidata(cols, patrones_norte)
    col_este_sugerida <- detectar_columna_candidata(cols, patrones_este)
    col_altitud_sugerida <- detectar_columna_candidata(cols, patrones_altitud)
    
    tiene_coords <- any(grepl("NORTE|NORTH|Y", cols_upper)) && any(grepl("ESTE|EAST|X", cols_upper))
    
    mensaje_advertencia <- if (!tiene_coords) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        "No se detectaron coordenadas NORTE/ESTE. Columnas: ", paste(head(cols, 5), collapse = ", ")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Coordenadas detectadas"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #ff9800; margin-bottom: 5px;"),
      selectInput("col_punto_coords", "Columna PUNTO:", choices = cols, selected = col_punto_sugerida),
      selectInput("col_norte_coords", "Columna NORTE:", choices = cols, selected = col_norte_sugerida),
      selectInput("col_este_coords", "Columna ESTE:", choices = cols, selected = col_este_sugerida),
      selectInput("col_altitud_coords", "Columna ALTITUD (opcional):", choices = c("(ninguna)", cols), selected = col_altitud_sugerida)
    )
  })
  
  # Mapeo de columnas para shapefile de marco de grillas (Caso 1)
  output$mapeo_columnas_marco_shp_ui <- renderUI({
    req(columnas_marco_grillas_shp_caso1())
    
    cols <- columnas_marco_grillas_shp_caso1()
    cols_upper <- toupper(cols)
    
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_celda <- c("CELDA", "COD_CELDA", "CELL", "COD_UNIC")
    patrones_grilla <- c("GRILLA", "COD_GRILLA", "GRID", "CODIGO_GRILLA")
    patrones_area <- c("AREA", "SUPERFICIE", "Shape_Area")
    
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_celda_sugerida <- detectar_columna_candidata(cols, patrones_celda)
    col_grilla_sugerida <- detectar_columna_candidata(cols, patrones_grilla)
    col_area_sugerida <- detectar_columna_candidata(cols, patrones_area)
    
    tiene_grilla <- any(grepl("GRILL|GRID", cols_upper))
    tiene_celda <- any(grepl("CELD|CELL", cols_upper))
    
    mensaje_advertencia <- if (!tiene_grilla) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        "No se detectó columna GRILLA. ¿Es el shapefile correcto? Columnas: ", paste(head(cols, 5), collapse = ", ")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Shapefile de grillas detectado"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #2196f3; margin-bottom: 5px;"),
      selectInput("col_locacion_marco_shp", "Columna LOCACION:", choices = cols, selected = col_locacion_sugerida),
      selectInput("col_celda_marco_shp", "Columna CELDA:", choices = cols, selected = col_celda_sugerida),
      selectInput("col_grilla_marco_shp", "Columna GRILLA:", choices = cols, selected = col_grilla_sugerida),
      selectInput("col_area_marco_shp", "Columna AREA (opcional):", choices = c("(ninguna)", cols), selected = col_area_sugerida)
    )
  })
  
  # Mapeo de columnas para muestra final (Caso 2)
  output$mapeo_columnas_muestra_final_ui <- renderUI({
    req(columnas_muestra_final())
    
    cols <- columnas_muestra_final()
    cols_upper <- toupper(cols)
    
    patrones_punto <- c("PUNTO", "COD_PUNTO", "POINT", "ID")
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION")
    patrones_celda <- c("CELDA", "COD_CELDA", "CELL")
    patrones_grilla <- c("GRILLA", "COD_GRILLA", "GRID")
    
    col_punto_sugerida <- detectar_columna_candidata(cols, patrones_punto)
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_celda_sugerida <- detectar_columna_candidata(cols, patrones_celda)
    col_grilla_sugerida <- detectar_columna_candidata(cols, patrones_grilla)
    
    tiene_punto <- any(grepl("PUNTO|POINT", cols_upper))
    tiene_estructura <- any(grepl("GRILL|GRID|CELD|CELL", cols_upper))
    
    mensaje_advertencia <- if (!tiene_punto || !tiene_estructura) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        if (!tiene_punto) "No se detectó columna PUNTO. " else "",
        if (!tiene_estructura) "No se detectó estructura de grillas/celdas. " else "",
        "Columnas: ", paste(head(cols, 5), collapse = ", ")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " Muestra final de Fase 4 detectada"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #28a745; margin-bottom: 5px;"),
      selectInput("col_punto_muestra", "Columna PUNTO:", choices = cols, selected = col_punto_sugerida),
      selectInput("col_locacion_muestra", "Columna LOCACION:", choices = cols, selected = col_locacion_sugerida),
      selectInput("col_celda_muestra", "Columna CELDA (opcional):", choices = c("(ninguna)", cols), selected = col_celda_sugerida),
      selectInput("col_grilla_muestra", "Columna GRILLA (opcional):", choices = c("(ninguna)", cols), selected = col_grilla_sugerida),
      p(em("Nota: La muestra final ya debe contener todas las columnas necesarias"), style = "font-size: 10px; color: #666;")
    )
  })
  
  # Mapeo de columnas para pozos de referencia (Fase 4C)
  output$mapeo_columnas_pozos_ui <- renderUI({
    req(columnas_pozos_ref())
    
    cols <- columnas_pozos_ref()
    cols_upper <- toupper(cols)
    
    # Detectar columnas sugeridas
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC", "POZO", "WELL")
    patrones_este <- c("ESTE", "EAST", "X", "COORD_X", "EASTING")
    patrones_norte <- c("NORTE", "NORTH", "Y", "COORD_Y", "NORTHING")
    patrones_altitud <- c("ALTITUD", "ALTITUDE", "ELEVACION", "ELEVATION", "Z", "COTA")
    
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_este_sugerida <- detectar_columna_candidata(cols, patrones_este)
    col_norte_sugerida <- detectar_columna_candidata(cols, patrones_norte)
    col_altitud_sugerida <- detectar_columna_candidata(cols, patrones_altitud)
    
    # Verificar columnas críticas
    tiene_locacion <- any(grepl("LOCACION|LOCATION|LOC|POZO", cols_upper))
    tiene_este <- any(grepl("ESTE|EAST|X", cols_upper))
    tiene_norte <- any(grepl("NORTE|NORTH|Y", cols_upper))
    tiene_altitud <- any(grepl("ALTITUD|ALTITUDE|ELEVACION|ELEVATION", cols_upper))
    
    todas_presentes <- tiene_locacion && tiene_este && tiene_norte && tiene_altitud
    
    mensaje_advertencia <- if (!todas_presentes) {
      div(style = "background-color: #fff3cd; border: 2px solid #f0ad4e; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 11px; color: #856404;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        if (!tiene_locacion) "No se detectó LOCACION. " else "",
        if (!tiene_este) "No se detectó ESTE. " else "",
        if (!tiene_norte) "No se detectó NORTE. " else "",
        if (!tiene_altitud) "No se detectó ALTITUD. " else "",
        "Columnas: ", paste(head(cols, 5), collapse = ", ")
      )
    } else {
      div(style = "background-color: #d4edda; border: 1px solid #28a745; padding: 6px; border-radius: 4px; margin-bottom: 8px; font-size: 11px;",
        icon("check-circle"), " ✅ Columnas detectadas correctamente"
      )
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas:"), style = "font-size: 12px; color: #f0ad4e; margin-bottom: 5px;"),
      selectInput("col_locacion_pozos", "Columna LOCACION:", choices = cols, selected = col_locacion_sugerida),
      selectInput("col_este_pozos", "Columna ESTE:", choices = cols, selected = col_este_sugerida),
      selectInput("col_norte_pozos", "Columna NORTE:", choices = cols, selected = col_norte_sugerida),
      selectInput("col_altitud_pozos", "Columna ALTITUD:", choices = cols, selected = col_altitud_sugerida),
      p(em("Nota: Todas las columnas son obligatorias para el cálculo de distancias"), style = "font-size: 10px; color: #666;")
    )
  })
  
  # ============================================================================ #
  # CARGAR Y UNIFICAR DATOS - MANEJA CASO 1 Y CASO 2                          #
  # ============================================================================ #
  
  # Cargar y unificar datos - Maneja CASO 1 y CASO 2
  observeEvent(input$cargar_datos_resultados_btn, {
    req(input$archivo_resultados_lab)
    
    tryCatch({
      # PASO 1: Cargar y limpiar resultados de laboratorio (BASE PRINCIPAL)
      resultados_lab <- read_excel(input$archivo_resultados_lab$datapath)
      resultados_lab <- estandarizar_columnas(resultados_lab)
      
      # ==== APLICAR MAPEO DE COLUMNAS DEL USUARIO (Resultados Lab) ====
      col_punto_usuario <- toupper(input$col_punto_lab)
      col_tph_usuario <- toupper(input$col_tph_lab)
      col_locacion_usuario <- toupper(input$col_locacion_lab)
      col_prof_usuario <- toupper(input$col_prof_lab)
      
      # Validar que las columnas seleccionadas existen
      if (!col_punto_usuario %in% names(resultados_lab)) {
        stop(paste("La columna seleccionada para PUNTO no existe:", col_punto_usuario))
      }
      if (!col_tph_usuario %in% names(resultados_lab)) {
        stop(paste("La columna seleccionada para TPH no existe:", col_tph_usuario))
      }
      
      # Renombrar columnas según mapeo
      names(resultados_lab)[names(resultados_lab) == col_punto_usuario] <- "PUNTO"
      names(resultados_lab)[names(resultados_lab) == col_tph_usuario] <- "TPH"
      if (col_locacion_usuario %in% names(resultados_lab)) {
        names(resultados_lab)[names(resultados_lab) == col_locacion_usuario] <- "LOCACION"
      }
      if (col_prof_usuario %in% names(resultados_lab)) {
        names(resultados_lab)[names(resultados_lab) == col_prof_usuario] <- "PROF"
      }
      
      # Limpiar resultados de laboratorio
      resultados_lab_clean <- limpiar_resultados_laboratorio(resultados_lab)
      
      # PASO 2: Enriquecer según el caso seleccionado
      caso <- input$caso_carga
      
      if (caso == "caso1") {
        # CASO 1: Expedientes antiguos (3 archivos)
        showNotification("Procesando Caso 1: Expedientes antiguos...", type = "message", duration = 3)
        
        # Cargar archivo de coordenadas (obligatorio para matching espacial)
        coordenadas <- NULL
        if (!is.null(input$archivo_coordenadas)) {
          coordenadas <- read_excel(input$archivo_coordenadas$datapath)
          coordenadas <- estandarizar_columnas(coordenadas)
          
          # ==== APLICAR MAPEO DE COLUMNAS DEL USUARIO (Coordenadas) ====
          col_punto_coords_usuario <- toupper(input$col_punto_coords)
          col_norte_coords_usuario <- toupper(input$col_norte_coords)
          col_este_coords_usuario <- toupper(input$col_este_coords)
          col_altitud_coords_usuario <- if (!is.null(input$col_altitud_coords) && input$col_altitud_coords != "(ninguna)") {
            toupper(input$col_altitud_coords)
          } else {
            NULL
          }
          
          # Validar que las columnas seleccionadas existen
          if (!col_punto_coords_usuario %in% names(coordenadas)) {
            stop(paste("La columna seleccionada para PUNTO no existe:", col_punto_coords_usuario))
          }
          if (!col_norte_coords_usuario %in% names(coordenadas)) {
            stop(paste("La columna seleccionada para NORTE no existe:", col_norte_coords_usuario))
          }
          if (!col_este_coords_usuario %in% names(coordenadas)) {
            stop(paste("La columna seleccionada para ESTE no existe:", col_este_coords_usuario))
          }
          
          # Renombrar columnas según mapeo
          names(coordenadas)[names(coordenadas) == col_punto_coords_usuario] <- "PUNTO"
          names(coordenadas)[names(coordenadas) == col_norte_coords_usuario] <- "NORTE"
          names(coordenadas)[names(coordenadas) == col_este_coords_usuario] <- "ESTE"
          if (!is.null(col_altitud_coords_usuario) && col_altitud_coords_usuario %in% names(coordenadas)) {
            names(coordenadas)[names(coordenadas) == col_altitud_coords_usuario] <- "ALTITUD"
          }
        } else {
          stop("Para el Caso 1 es obligatorio cargar el archivo de coordenadas de puntos")
        }
        
        # Cargar shapefile de marco de grillas (opcional)
        marco_grillas_sf <- NULL
        if (!is.null(input$archivo_marco_grillas_shp)) {
          showNotification("Cargando shapefile de marco de grillas...", type = "message", duration = 2)
          
          # Crear directorio temporal
          temp_dir <- tempdir()
          zip_path <- input$archivo_marco_grillas_shp$datapath
          
          # Descomprimir shapefile
          unzip(zip_path, exdir = temp_dir)
          
          # Buscar archivo .shp
          shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
          if (length(shp_files) == 0) {
            stop("No se encontró archivo .shp en el ZIP")
          }
          
          # Cargar shapefile
          marco_grillas_sf <- st_read(shp_files[1], quiet = TRUE)
          
          # Obtener el nombre de la columna de geometría antes de cualquier modificación
          geom_col <- attr(marco_grillas_sf, "sf_column")
          
          # Estandarizar nombres de columnas a MAYÚSCULAS (excepto la geometría)
          col_names <- names(marco_grillas_sf)
          col_names_upper <- toupper(col_names)
          # Restaurar el nombre original de la columna de geometría
          col_names_upper[col_names == geom_col] <- geom_col
          names(marco_grillas_sf) <- col_names_upper
          
          # ==== APLICAR MAPEO DE COLUMNAS DEL USUARIO ====
          # Leer el mapeo seleccionado por el usuario en la UI
          col_locacion_usuario <- toupper(input$col_locacion_marco_shp)
          col_celda_usuario <- toupper(input$col_celda_marco_shp)
          col_grilla_usuario <- toupper(input$col_grilla_marco_shp)
          col_area_usuario <- if (!is.null(input$col_area_marco_shp) && input$col_area_marco_shp != "(ninguna)") {
            toupper(input$col_area_marco_shp)
          } else {
            NULL
          }
          
          # Validar que las columnas seleccionadas existen en el shapefile
          if (!col_locacion_usuario %in% names(marco_grillas_sf)) {
            stop(paste("La columna seleccionada para LOCACION no existe:", col_locacion_usuario))
          }
          if (!col_celda_usuario %in% names(marco_grillas_sf)) {
            stop(paste("La columna seleccionada para CELDA no existe:", col_celda_usuario))
          }
          if (!col_grilla_usuario %in% names(marco_grillas_sf)) {
            stop(paste("La columna seleccionada para GRILLA no existe:", col_grilla_usuario))
          }
          
          # Renombrar columnas según el mapeo del usuario
          # CRÍTICO: NUNCA renombrar la columna de geometría
          current_names <- names(marco_grillas_sf)
          if (current_names[current_names == col_locacion_usuario] != geom_col) {
            names(marco_grillas_sf)[names(marco_grillas_sf) == col_locacion_usuario] <- "LOCACION"
          }
          if (current_names[current_names == col_celda_usuario] != geom_col) {
            names(marco_grillas_sf)[names(marco_grillas_sf) == col_celda_usuario] <- "CELDA"
          }
          if (current_names[current_names == col_grilla_usuario] != geom_col) {
            names(marco_grillas_sf)[names(marco_grillas_sf) == col_grilla_usuario] <- "GRILLA"
          }
          if (!is.null(col_area_usuario) && col_area_usuario %in% names(marco_grillas_sf) && 
              col_area_usuario != geom_col) {
            names(marco_grillas_sf)[names(marco_grillas_sf) == col_area_usuario] <- "AREA"
          }
          
          showNotification("✓ Shapefile cargado y columnas mapeadas correctamente", type = "message", duration = 3)
        }
        
        # Enriquecer con Caso 1 (ahora con matching espacial - retorna lista con datos y diagnostico)
        resultado_caso1 <- enriquecer_caso1_espacial(resultados_lab_clean, coordenadas, marco_grillas_sf)
        muestra_enriq <- resultado_caso1$datos
        
        # Guardar diagnóstico
        diagnostico_enriquecimiento(resultado_caso1$diagnostico)
        
        # Mostrar alertas si hay problemas
        diag <- resultado_caso1$diagnostico
        
        # Alertas sobre matching Lab-Coordenadas
        if (diag$tiene_problema_coords) {
          mensaje_alerta <- paste0(
            "⚠️ ATENCIÓN: Se detectaron ", diag$n_puntos_solo_lab, " puntos en resultados de laboratorio ",
            "que NO tienen coordenadas.\n",
            "Ver detalles en la pestaña 'Diagnóstico de Match'."
          )
          showNotification(mensaje_alerta, type = "warning", duration = 10)
        }
        
        # Alertas sobre matching espacial
        if (isTRUE(diag$tiene_problema_espacial)) {
          mensaje_espacial <- paste0(
            "⚠️ MATCHING ESPACIAL: ", diag$n_sin_match_espacial, " puntos no cayeron dentro de ninguna grilla.\n",
            "Verifica que las coordenadas y el shapefile usen el mismo sistema de referencia.\n",
            "Ver detalles en la pestaña 'Diagnóstico de Match'."
          )
          showNotification(mensaje_espacial, type = "warning", duration = 10)
        }
        
      } else {
        # CASO 2: Expedientes recientes (2 archivos)
        showNotification("Procesando Caso 2: Expedientes recientes...", type = "message", duration = 3)
        
        if (is.null(input$archivo_muestra_final)) {
          stop("Para el Caso 2 debe cargar el archivo de Muestra Final (Fase 4)")
        }
        
        # Cargar muestra final de Fase 4
        muestra_final <- read_excel(input$archivo_muestra_final$datapath)
        muestra_final <- estandarizar_columnas(muestra_final)
        
        # ==== APLICAR MAPEO DE COLUMNAS DEL USUARIO (Muestra Final) ====
        col_punto_muestra_usuario <- toupper(input$col_punto_muestra)
        col_locacion_muestra_usuario <- toupper(input$col_locacion_muestra)
        col_celda_muestra_usuario <- if (!is.null(input$col_celda_muestra) && input$col_celda_muestra != "(ninguna)") {
          toupper(input$col_celda_muestra)
        } else {
          NULL
        }
        col_grilla_muestra_usuario <- if (!is.null(input$col_grilla_muestra) && input$col_grilla_muestra != "(ninguna)") {
          toupper(input$col_grilla_muestra)
        } else {
          NULL
        }
        
        # Validar que las columnas seleccionadas existen
        if (!col_punto_muestra_usuario %in% names(muestra_final)) {
          stop(paste("La columna seleccionada para PUNTO no existe:", col_punto_muestra_usuario))
        }
        if (!col_locacion_muestra_usuario %in% names(muestra_final)) {
          stop(paste("La columna seleccionada para LOCACION no existe:", col_locacion_muestra_usuario))
        }
        
        # Renombrar columnas según mapeo
        names(muestra_final)[names(muestra_final) == col_punto_muestra_usuario] <- "PUNTO"
        names(muestra_final)[names(muestra_final) == col_locacion_muestra_usuario] <- "LOCACION"
        if (!is.null(col_celda_muestra_usuario) && col_celda_muestra_usuario %in% names(muestra_final)) {
          names(muestra_final)[names(muestra_final) == col_celda_muestra_usuario] <- "CELDA"
        }
        if (!is.null(col_grilla_muestra_usuario) && col_grilla_muestra_usuario %in% names(muestra_final)) {
          names(muestra_final)[names(muestra_final) == col_grilla_muestra_usuario] <- "GRILLA"
        }
        
        # Enriquecer con Caso 2 (retorna lista con datos y diagnostico)
        resultado_caso2 <- enriquecer_caso2(resultados_lab_clean, muestra_final)
        muestra_enriq <- resultado_caso2$datos
        
        # Guardar diagnóstico
        diagnostico_enriquecimiento(resultado_caso2$diagnostico)
        
        # Mostrar alertas si hay problemas
        diag <- resultado_caso2$diagnostico
        if (diag$tiene_problema) {
          mensaje_alerta <- paste0(
            "⚠️ ATENCIÓN: Se detectaron ", diag$n_puntos_perdidos, " puntos de la muestra final ",
            "que NO aparecen en el archivo de laboratorio.\n",
            "Ver detalles en la pestaña 'Diagnóstico de Match'."
          )
          showNotification(mensaje_alerta, type = "warning", duration = 10)
        }
      }
      
      # Guardar resultado
      muestra_enriquecida(muestra_enriq)
      
      # Mensaje de éxito con detalles
      mensaje <- paste0(
        "✓ Datos cargados y enriquecidos exitosamente\n",
        "Registros totales: ", nrow(muestra_enriq), "\n",
        "Columnas: ", ncol(muestra_enriq)
      )
      
      showNotification(mensaje, type = "message", duration = 5)
      updateTabsetPanel(session, "tabset_fase5", selected = "Datos Cargados")
      
    }, error = function(e) {
      registrar_error(e, "Carga de Datos de Resultados")
      showNotification(paste("Error al cargar datos:", conditionMessage(e)), type = "error", duration = 10)
    })
  })
  
  # Mostrar resumen de carga
  output$resumen_carga_resultados <- renderPrint({
    req(muestra_enriquecida())
    
    datos <- muestra_enriquecida()
    diag <- diagnostico_enriquecimiento()
    
    cat("═══════════════════════════════════════════\n")
    cat("  MUESTRA FINAL ENRIQUECIDA\n")
    cat("═══════════════════════════════════════════\n\n")
    
    # === ALERTAS CRÍTICAS AL INICIO ===
    # Detectar si es Caso 1 o Caso 2 y mostrar alertas correspondientes
    if (!is.null(diag)) {
      # Caso 2: tiene_problema
      if (isTRUE(diag$tiene_problema)) {
        cat("🚨 ALERTAS CRÍTICAS - CASO 2\n")
        cat("═══════════════════════════════════════════\n")
        cat("⚠️  Se detectaron puntos NO incluidos en el análisis\n\n")
        cat("Puntos en muestra final:", diag$n_puntos_muestra_original, "\n")
        cat("Puntos en archivo lab:", diag$n_puntos_lab_original, "\n")
        cat("Puntos matcheados:", diag$n_puntos_en_ambos, "\n")
        cat("❌ PUNTOS PERDIDOS:", diag$n_puntos_perdidos, "\n\n")
        cat("⚠️  Estos puntos NO aparecerán en 'Todas las Grillas'\n")
        cat("⚠️  ni en 'Grillas Contaminadas'\n\n")
        cat("Ver detalles completos en pestaña 'Diagnóstico de Match'\n")
        cat("═══════════════════════════════════════════\n\n")
      }
      # Caso 1: tiene_problema_coords o tiene_problema_espacial
      else if (isTRUE(diag$tiene_problema_coords) || isTRUE(diag$tiene_problema_espacial)) {
        cat("🚨 ALERTAS CRÍTICAS - CASO 1\n")
        cat("═══════════════════════════════════════════\n")
        if (isTRUE(diag$tiene_problema_coords)) {
          cat("⚠️  Algunos puntos de laboratorio NO tienen coordenadas\n")
          cat("   Puntos sin coordenadas:", diag$n_puntos_solo_lab, "\n\n")
        }
        if (isTRUE(diag$tiene_problema_espacial)) {
          cat("⚠️  Algunos puntos NO cayeron en ninguna grilla\n")
          cat("   Puntos sin match espacial:", diag$n_sin_match_espacial, "\n\n")
        }
        cat("Ver detalles completos en pestaña 'Diagnóstico de Match'\n")
        cat("═══════════════════════════════════════════\n\n")
      }
    }
    
    cat("📊 INFORMACIÓN GENERAL\n")
    cat("──────────────────────\n")
    cat("Total de registros:", nrow(datos), "\n")
    cat("Total de columnas:", ncol(datos), "\n\n")
    
    cat("📋 COLUMNAS DISPONIBLES\n")
    cat("──────────────────────\n")
    cat(paste(names(datos), collapse = ", "), "\n\n")
    
    # Información por locación
    if ("LOCACION" %in% names(datos)) {
      cat("📍 LOCACIONES\n")
      cat("──────────────\n")
      locaciones <- unique(datos$LOCACION)
      cat("Total de locaciones únicas:", length(locaciones), "\n")
      cat("Locaciones:", paste(head(locaciones, 10), collapse = ", "))
      if (length(locaciones) > 10) cat(" ... y", length(locaciones) - 10, "más")
      cat("\n\n")
    }
    
    # Información de celdas y grillas
    if ("CELDA" %in% names(datos)) {
      cat("Celdas únicas:", length(unique(datos$CELDA)), "\n")
    } else if ("COD_CELDA" %in% names(datos)) {
      cat("Celdas únicas:", length(unique(datos$COD_CELDA)), "\n")
    }
    if ("GRILLA" %in% names(datos)) {
      cat("Grillas únicas:", length(unique(datos$GRILLA)), "\n\n")
    }
    
    # Estadísticas de TPH
    if ("TPH" %in% names(datos)) {
      cat("🧪 ESTADÍSTICAS DE TPH\n")
      cat("──────────────────────\n")
      cat("Mínimo:", min(datos$TPH, na.rm = TRUE), "mg/kg\n")
      cat("Máximo:", max(datos$TPH, na.rm = TRUE), "mg/kg\n")
      cat("Media:", round(mean(datos$TPH, na.rm = TRUE), 2), "mg/kg\n")
      cat("Mediana:", round(median(datos$TPH, na.rm = TRUE), 2), "mg/kg\n\n")
    }
    
    # Información de coordenadas
    tiene_coords <- all(c("NORTE", "ESTE") %in% names(datos))
    cat("📍 Coordenadas:", ifelse(tiene_coords, "✓ Disponibles", "✗ No disponibles"), "\n")
    
    tiene_prof <- "PROF" %in% names(datos)
    cat("📏 Profundidad:", ifelse(tiene_prof, "✓ Disponible", "✗ No disponible"), "\n")
    
    cat("\n═══════════════════════════════════════════\n")
  })
  
  # Mostrar tabla muestra enriquecida
  output$tabla_muestra_enriquecida <- renderDT({
    req(muestra_enriquecida())
    datatable(head(muestra_enriquecida(), 50), options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })
  
  # Ejecutar análisis completo
  observeEvent(input$ejecutar_analisis_btn, {
    req(muestra_enriquecida())
    
    tryCatch({
      umbral <- input$umbral_tph
      datos <- muestra_enriquecida()
      
      # Verificar columnas requeridas
      columnas_necesarias <- c("PUNTO", "LOCACION", "TPH")
      columnas_faltantes <- setdiff(columnas_necesarias, names(datos))
      
      if (length(columnas_faltantes) > 0) {
        stop(paste("Faltan columnas requeridas:", paste(columnas_faltantes, collapse = ", ")))
      }
      
      # Calcular promedios por celdas (buscar CELDA o COD_CELDA)
      tiene_celda <- "CELDA" %in% names(datos)
      tiene_cod_celda <- "COD_CELDA" %in% names(datos)
      
      if (tiene_celda || tiene_cod_celda) {
        # Si tiene COD_CELDA pero no CELDA, renombrar para análisis
        if (!tiene_celda && tiene_cod_celda) {
          datos <- datos %>% rename(CELDA = COD_CELDA)
          muestra_enriquecida(datos)  # Actualizar reactivo con columna renombrada
          showNotification("ℹ️ Columna COD_CELDA renombrada a CELDA para análisis", 
                          type = "message", duration = 3)
        }
        
        prom_celdas <- calcular_promedios_celdas(datos, umbral)
        promedios_celdas_resultado(prom_celdas)
        showNotification("✓ Análisis por celdas completado", type = "message", duration = 3)
      } else {
        showNotification("⚠ No se encontró columna CELDA ni COD_CELDA - análisis por celdas omitido", 
                        type = "warning", duration = 5)
      }
      
      # Calcular promedios por locaciones (siempre debe existir LOCACION)
      prom_loc <- calcular_promedios_locaciones(datos, umbral)
      promedios_locaciones_resultado(prom_loc)
      showNotification("✓ Análisis por locaciones completado", type = "message", duration = 3)
      
      showNotification("✓ Análisis estadístico completado exitosamente", type = "message")
      
      # Navegar a la pestaña de Análisis Nivel Grilla
      updateTabsetPanel(session, "tabset_fase5", selected = "Análisis Nivel Grilla")
      
    }, error = function(e) {
      registrar_error(e, "Análisis Estadístico")
      showNotification(paste("Error en análisis:", conditionMessage(e)), type = "error", duration = 10)
    })
  })
  
  # Análisis nivel grilla - outputs
  output$resumen_grillas_contaminadas <- renderPrint({
    req(muestra_enriquecida())
    datos <- muestra_enriquecida()
    umbral <- input$umbral_tph
    grillas_contam <- datos %>% filter(TPH > umbral)
    diag <- diagnostico_enriquecimiento()
    
    # Obtener códigos únicos contaminados
    codigos_unicos <- grillas_contam %>% 
      pull(if("GRILLA" %in% names(grillas_contam)) GRILLA else PUNTO) %>% 
      unique() %>% 
      sort()
    
    cat("ANÁLISIS NIVEL GRILLA\n")
    cat("═════════════════════\n\n")
    
    # ALERTAS CRÍTICAS si hay puntos perdidos (solo Caso 2)
    if (!is.null(diag) && isTRUE(diag$tiene_problema)) {
      cat("🚨 ATENCIÓN - PUNTOS OMITIDOS (CASO 2)\n")
      cat("─────────────────────────────\n")
      cat("⚠️  Se detectaron", diag$n_puntos_perdidos, "puntos de la muestra final\n")
      cat("   que NO aparecen en estas tablas (sin resultados de lab)\n\n")
      cat("📊 Puntos esperados (muestra final):", diag$n_puntos_muestra_original, "\n")
      cat("📊 Puntos en análisis (con TPH):", nrow(datos), "\n")
      cat("❌ Puntos perdidos:", diag$n_puntos_perdidos, "\n\n")
      cat("Ver detalles en pestaña '🔍 Diagnóstico de Match'\n")
      cat("═════════════════════════════\n\n")
    } else if (!is.null(diag) && (isTRUE(diag$tiene_problema_coords) || isTRUE(diag$tiene_problema_espacial))) {
      cat("🚨 ATENCIÓN - CASO 1\n")
      cat("─────────────────────────────\n")
      if (isTRUE(diag$tiene_problema_coords)) {
        cat("⚠️  Algunos puntos no tienen coordenadas:", diag$n_puntos_solo_lab, "\n")
      }
      if (isTRUE(diag$tiene_problema_espacial)) {
        cat("⚠️  Algunos puntos no cayeron en grillas:", diag$n_sin_match_espacial, "\n")
      }
      cat("\nVer detalles en pestaña '🔍 Diagnóstico de Match'\n")
      cat("═════════════════════════════\n\n")
    }
    
    cat("RESUMEN DE ANÁLISIS\n")
    cat("───────────────────\n")
    cat("Total de puntos en análisis:", nrow(datos), "\n")
    cat("Puntos contaminados (TPH >", umbral, "mg/kg):", nrow(grillas_contam), "\n")
    cat("Grillas/Códigos contaminados únicos:", length(codigos_unicos), "\n\n")
    cat("Códigos contaminados:\n")
    if (length(codigos_unicos) > 0) {
      cat(paste(codigos_unicos, collapse = ", "))
    }
  })
  
  output$tabla_grillas_contaminadas <- renderDT({
    req(muestra_enriquecida())
    datos <- muestra_enriquecida()
    umbral <- input$umbral_tph
    
    # Añadir columna criterio_contaminacion
    grillas_contam <- datos %>% 
      filter(TPH > umbral) %>%
      mutate(criterio_contaminacion = "Supera umbral TPH") %>%
      select(criterio_contaminacion, everything())
    
    # Encontrar índices de columnas TPH y PORC_EXCESO (base 0 para JavaScript)
    col_indices <- c()
    if ("TPH" %in% names(grillas_contam)) {
      col_indices <- c(col_indices, which(names(grillas_contam) == "TPH") - 1)
    }
    if ("PORC_EXCESO" %in% names(grillas_contam)) {
      col_indices <- c(col_indices, which(names(grillas_contam) == "PORC_EXCESO") - 1)
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
      grillas_contam, 
      options = list(
        pageLength = 10, 
        scrollX = TRUE,
        headerCallback = JS(header_callback)
      ), 
      rownames = FALSE
    ) %>%
      formatStyle(
        "criterio_contaminacion",
        backgroundColor = "#dc3545",
        color = "white",
        fontWeight = "bold"
      )
  })
  
  output$tabla_todas_grillas <- renderDT({
    req(muestra_enriquecida())
    datos <- muestra_enriquecida()
    umbral <- input$umbral_tph
    
    # Añadir columna criterio_contaminacion a todos
    datos_con_criterio <- datos %>%
      mutate(criterio_contaminacion = ifelse(TPH > umbral, "Supera umbral TPH", "No contaminada")) %>%
      select(criterio_contaminacion, everything())
    
    datatable(datos_con_criterio, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) %>%
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
  
  output$descargar_todas_grillas_btn <- downloadHandler(
    filename = function() {
      codigo_exp <- if (!is.null(input$codigo_expediente) && input$codigo_expediente != "") {
        paste0(input$codigo_expediente, "_")
      } else {
        ""
      }
      paste0(codigo_exp, "Todas_las_Grillas-", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(muestra_enriquecida())
      datos <- muestra_enriquecida()
      umbral <- input$umbral_tph
      
      datos_con_criterio <- datos %>%
        mutate(criterio_contaminacion = ifelse(TPH > umbral, "Supera umbral TPH", "No contaminada")) %>%
        select(criterio_contaminacion, everything())
      
      openxlsx::write.xlsx(datos_con_criterio, file)
    }
  )
  
  # ============================================================================ #
  # MANEJO DE SHAPEFILES - Detección y mapeo de columnas
  # ============================================================================ #
  
  # Función auxiliar para detectar columna candidata
  detectar_columna_candidata <- function(nombres_cols, patrones) {
    nombres_upper <- toupper(nombres_cols)
    for (patron in patrones) {
      patron_upper <- toupper(patron)
      match_idx <- which(nombres_upper == patron_upper)
      if (length(match_idx) > 0) {
        return(nombres_cols[match_idx[1]])
      }
    }
    # Si no hay match exacto, buscar que contenga el patrón
    for (patron in patrones) {
      patron_upper <- toupper(patron)
      match_idx <- which(grepl(patron_upper, nombres_upper))
      if (length(match_idx) > 0) {
        return(nombres_cols[match_idx[1]])
      }
    }
    return(nombres_cols[1])  # Default: primera columna
  }
  
  # Observer para cargar shapefile de grillas
  observeEvent(input$shp_grillas_upload, {
    req(input$shp_grillas_upload)
    
    tryCatch({
      # Crear directorio temporal ÚNICO para grillas
      temp_dir <- file.path(tempdir(), "shp_grillas", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(input$shp_grillas_upload$datapath, exdir = temp_dir)
      shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
      
      if (length(shp_files) > 0) {
        shp <- st_read(shp_files[1], quiet = TRUE)
        cols <- names(shp)
        
        # Verificar si parece ser el shapefile correcto
        tiene_grilla <- any(grepl("GRILL|GRID", toupper(cols)))
        tiene_celda_no_grilla <- any(grepl("CELDA|CELL", toupper(cols))) && !tiene_grilla
        
        if (tiene_celda_no_grilla) {
          showNotification(
            "⚠️ ADVERTENCIA: Este shapefile contiene 'CELDA' pero no 'GRILLA'. Parece ser un shapefile de CELDAS, no de GRILLAS. ¿Cargaste el archivo correcto?",
            type = "warning",
            duration = 10
          )
        }
        
        shp_grillas_data(shp)
        columnas_shp_grillas(cols)
        
        msg <- if (tiene_grilla) {
          paste("✓ Shapefile de grillas cargado. Columnas encontradas:", paste(cols, collapse = ", "))
        } else {
          paste("⚠️ Shapefile cargado pero no se detectó columna de grillas. Columnas:", paste(cols, collapse = ", "))
        }
        showNotification(msg, type = if(tiene_grilla) "message" else "warning", duration = 8)
      }
    }, error = function(e) {
      showNotification(paste("Error al cargar shapefile de grillas:", e$message), type = "error")
      registrar_error(e$message, "Carga shapefile grillas")
    })
  })
  
  # Observer para cargar shapefile de celdas
  observeEvent(input$shp_celdas_upload, {
    req(input$shp_celdas_upload)
    
    tryCatch({
      # Crear directorio temporal ÚNICO para celdas
      temp_dir <- file.path(tempdir(), "shp_celdas", basename(tempfile()))
      dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(input$shp_celdas_upload$datapath, exdir = temp_dir)
      shp_files <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
      
      if (length(shp_files) > 0) {
        shp <- st_read(shp_files[1], quiet = TRUE)
        cols <- names(shp)
        
        # Verificar si parece ser el shapefile correcto
        tiene_celda <- any(grepl("CELDA|CELL", toupper(cols)))
        tiene_grilla_no_celda <- any(grepl("GRILL|GRID", toupper(cols))) && !tiene_celda
        
        if (tiene_grilla_no_celda) {
          showNotification(
            "⚠️ ADVERTENCIA: Este shapefile contiene 'GRILLA' pero no 'CELDA'. Parece ser un shapefile de GRILLAS, no de CELDAS. ¿Cargaste el archivo correcto?",
            type = "warning",
            duration = 10
          )
        }
        
        shp_celdas_data(shp)
        columnas_shp_celdas(cols)
        
        msg <- if (tiene_celda) {
          paste("✓ Shapefile de celdas cargado. Columnas encontradas:", paste(cols, collapse = ", "))
        } else {
          paste("⚠️ Shapefile cargado pero no se detectó columna de celdas. Columnas:", paste(cols, collapse = ", "))
        }
        showNotification(msg, type = if(tiene_celda) "message" else "warning", duration = 8)
      }
    }, error = function(e) {
      showNotification(paste("Error al cargar shapefile de celdas:", e$message), type = "error")
      registrar_error(e$message, "Carga shapefile celdas")
    })
  })
  
  # UI dinámico para mapeo de columnas de grillas
  output$mapeo_columnas_grillas_ui <- renderUI({
    req(columnas_shp_grillas())
    
    cols <- columnas_shp_grillas()
    
    # Detectar columnas sugeridas
    patrones_grilla <- c("GRILLA", "GRILLAS", "COD_GRILLA", "COD_GRILLAS", "GRID", "CODIGO_GRILLA")
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_area <- c("AREA", "SUPERFICIE", "HECTARES", "Shape_Area")
    
    col_grilla_sugerida <- detectar_columna_candidata(cols, patrones_grilla)
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_area_sugerida <- detectar_columna_candidata(cols, patrones_area)
    
    # Verificar si se encontró una columna apropiada
    tiene_patron_grilla <- any(grepl("GRILL|GRID", toupper(paste(cols, collapse = "|"))))
    
    mensaje_advertencia <- if (!tiene_patron_grilla) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 10px; border-radius: 4px; margin-bottom: 10px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        "No se detectó ninguna columna con 'GRILLA' o 'GRID'. ",
        "¿Cargaste el shapefile correcto? Columnas disponibles: ",
        paste(cols, collapse = ", ")
      )
    } else {
      NULL
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas del shapefile de grillas:"), style = "color: #0066cc;"),
      selectInput("col_grilla_shp", "Columna de código de GRILLA:",
                 choices = cols,
                 selected = col_grilla_sugerida),
      selectInput("col_locacion_grilla_shp", "Columna de LOCACIÓN:",
                 choices = cols,
                 selected = col_locacion_sugerida),
      selectInput("col_area_grilla_shp", "Columna de ÁREA:",
                 choices = cols,
                 selected = col_area_sugerida),
      p(em("Selecciona las columnas que identifican grilla, locación y área"), style = "font-size: 0.9em; color: #666;")
    )
  })
  
  # UI dinámico para mapeo de columnas de celdas
  output$mapeo_columnas_celdas_ui <- renderUI({
    req(columnas_shp_celdas())
    
    cols <- columnas_shp_celdas()
    
    # Detectar columnas sugeridas
    patrones_celda <- c("CELDA", "CELDAS", "COD_CELDA", "COD_CELDAS", "CELL", "CODIGO_CELDA", "COD_UNIC")
    patrones_locacion <- c("LOCACION", "UBICACION", "LOCATION", "LOC")
    patrones_area <- c("AREA", "SUPERFICIE", "HECTARES", "Shape_Area")
    
    col_celda_sugerida <- detectar_columna_candidata(cols, patrones_celda)
    col_locacion_sugerida <- detectar_columna_candidata(cols, patrones_locacion)
    col_area_sugerida <- detectar_columna_candidata(cols, patrones_area)
    
    # Verificar si se encontró una columna apropiada
    tiene_patron_celda <- any(grepl("CELD|CELL", toupper(paste(cols, collapse = "|"))))
    
    mensaje_advertencia <- if (!tiene_patron_celda) {
      div(style = "background-color: #f8d7da; border: 2px solid #dc3545; padding: 10px; border-radius: 4px; margin-bottom: 10px; color: #721c24;",
        icon("exclamation-triangle"),
        strong(" ADVERTENCIA: "),
        "No se detectó ninguna columna con 'CELDA' o 'CELL'. ",
        "¿Cargaste el shapefile correcto? Columnas disponibles: ",
        paste(cols, collapse = ", ")
      )
    } else {
      NULL
    }
    
    tagList(
      mensaje_advertencia,
      p(strong("Mapeo de columnas del shapefile de celdas:"), style = "color: #0066cc;"),
      selectInput("col_celda_shp", "Columna de código de CELDA:",
                 choices = cols,
                 selected = col_celda_sugerida),
      selectInput("col_locacion_celda_shp", "Columna de LOCACIÓN:",
                 choices = cols,
                 selected = col_locacion_sugerida),
      selectInput("col_area_celda_shp", "Columna de ÁREA:",
                 choices = cols,
                 selected = col_area_sugerida),
      p(em("Selecciona las columnas que identifican celda, locación y área"), style = "font-size: 0.9em; color: #666;")
    )
  })
  
  # ============================================================================ #
  # OUTPUTS DIAGNÓSTICO DE MATCH (CASO 1 Y CASO 2)                             #
  # ============================================================================ #
  
  # Mostrar si hay diagnóstico disponible
  output$diagnostico_match_disponible <- reactive({
    !is.null(diagnostico_enriquecimiento())
  })
  outputOptions(output, "diagnostico_match_disponible", suspendWhenHidden = FALSE)
  
  # Resumen del diagnóstico
  output$resumen_diagnostico_match <- renderPrint({
    diag <- diagnostico_enriquecimiento()
    
    # Si no hay diagnóstico, mostrar mensaje amigable
    if (is.null(diag)) {
      cat("ℹ️  No hay diagnóstico disponible aún.\n\n")
      cat("El diagnóstico se genera automáticamente después de\n")
      cat("cargar y unificar los datos en la Fase 5.\n")
      return()
    }
    
    cat("═══════════════════════════════════════════\n")
    cat("  DIAGNÓSTICO DE MATCH ENTRE ARCHIVOS\n")
    cat("═══════════════════════════════════════════\n\n")
    
    # Detectar si es Caso 1 o Caso 2
    es_caso1 <- !is.null(diag$n_puntos_coord_original)
    es_caso2 <- !is.null(diag$n_puntos_muestra_original)
    
    if (es_caso1) {
      cat("📂 CASO 1: Matching Espacial\n")
      cat("──────────────────────────────\n\n")
      
      cat("1️⃣ MATCH LAB-COORDENADAS (por código PUNTO):\n")
      cat("  • Puntos en resultados lab:", if(!is.null(diag$n_puntos_lab_original)) diag$n_puntos_lab_original else 0, "\n")
      cat("  • Puntos en coordenadas:   ", if(!is.null(diag$n_puntos_coord_original)) diag$n_puntos_coord_original else 0, "\n")
      cat("  • Match exitoso:           ", if(!is.null(diag$n_puntos_en_ambos)) diag$n_puntos_en_ambos else 0, "\n")
      cat("  • Solo en lab:             ", if(!is.null(diag$n_puntos_solo_lab)) diag$n_puntos_solo_lab else 0, "\n")
      cat("  • Solo en coordenadas:     ", if(!is.null(diag$n_puntos_solo_coord)) diag$n_puntos_solo_coord else 0, "\n\n")
      
      if (!is.null(diag$n_con_match_espacial)) {
        n_finales <- if(!is.null(diag$n_puntos_finales)) diag$n_puntos_finales else 1
        cat("2️⃣ MATCH ESPACIAL (puntos DENTRO de grillas):\n")
        cat("  • Total puntos procesados: ", n_finales, "\n")
        cat("  • Con match espacial:      ", diag$n_con_match_espacial, 
            sprintf(" (%.1f%%)\n", (diag$n_con_match_espacial/n_finales)*100))
        cat("  • Sin match espacial:      ", if(!is.null(diag$n_sin_match_espacial)) diag$n_sin_match_espacial else 0, 
            sprintf(" (%.1f%%)\n", (if(!is.null(diag$n_sin_match_espacial)) diag$n_sin_match_espacial else 0)/n_finales*100))
        cat("  • Sin coordenadas:         ", if(!is.null(diag$n_sin_coordenadas)) diag$n_sin_coordenadas else 0, "\n\n")
      }
      
      # Validar si hay problemas (manejar NULL de forma segura)
      tiene_problema_coords <- isTRUE(diag$tiene_problema_coords)
      tiene_problema_espacial <- isTRUE(diag$tiene_problema_espacial)
      
      if (tiene_problema_coords || tiene_problema_espacial) {
        cat("⚠️  ADVERTENCIAS:\n")
        if (tiene_problema_coords) {
          cat("  • Hay puntos sin coordenadas\n")
        }
        if (tiene_problema_espacial) {
          cat("  • Hay puntos que no cayeron en ninguna grilla\n")
        }
      } else {
        cat("✅ Todos los puntos tienen match correcto\n")
      }
      
    } else if (es_caso2) {
      cat("📂 CASO 2: Matching por Códigos\n")
      cat("──────────────────────────────\n\n")
      
      cat("📊 MATCH MUESTRA-LABORATORIO:\n")
      cat("  • Puntos en muestra final: ", if(!is.null(diag$n_puntos_muestra_original)) diag$n_puntos_muestra_original else 0, "\n")
      cat("  • Puntos en resultados lab:", if(!is.null(diag$n_puntos_lab_original)) diag$n_puntos_lab_original else 0, "\n")
      cat("  • Match exitoso:           ", if(!is.null(diag$n_puntos_en_ambos)) diag$n_puntos_en_ambos else 0, "\n")
      cat("  • Solo en muestra:         ", if(!is.null(diag$n_puntos_solo_muestra)) diag$n_puntos_solo_muestra else 0, "\n")
      cat("  • Solo en lab:             ", if(!is.null(diag$n_puntos_solo_lab)) diag$n_puntos_solo_lab else 0, "\n")
      cat("  • Puntos perdidos:         ", if(!is.null(diag$n_puntos_perdidos)) diag$n_puntos_perdidos else 0, "\n")
      cat("  • Puntos finales:          ", if(!is.null(diag$n_puntos_finales)) diag$n_puntos_finales else 0, "\n\n")
      
      tiene_problema <- isTRUE(diag$tiene_problema)
      if (tiene_problema) {
        cat("⚠️  HAY PUNTOS DE LA MUESTRA SIN RESULTADOS DE LAB\n")
      } else {
        cat("✅ Todos los puntos de la muestra tienen resultados\n")
      }
    }
    
    cat("\n═══════════════════════════════════════════\n")
  })
  
  # Tabla de puntos perdidos (Caso 2) o puntos sin match (Caso 1)
  output$tabla_puntos_perdidos <- renderDT({
    diag <- diagnostico_enriquecimiento()
    
    # Si no hay diagnóstico, mostrar mensaje amigable
    if (is.null(diag)) {
      return(datatable(
        data.frame(Mensaje = "ℹ️ No hay diagnóstico disponible aún. Cargue y unifique los datos en la Fase 5."), 
        options = list(pageLength = 5, dom = 't', ordering = FALSE, searching = FALSE), 
        rownames = FALSE
      ))
    }
    
    # Función helper para validar dataframe con datos
    tiene_datos <- function(df) {
      !is.null(df) && is.data.frame(df) && nrow(df) > 0
    }
    
    # Determinar qué tabla mostrar según el caso
    if (tiene_datos(diag$puntos_sin_tph)) {
      # Caso 2: puntos de muestra sin TPH
      datatable(diag$puntos_sin_tph, 
                options = list(pageLength = 10, scrollX = TRUE), 
                rownames = FALSE,
                caption = "Puntos de muestra final sin resultados de laboratorio")
    } else if (tiene_datos(diag$puntos_sin_coordenadas)) {
      # Caso 1: puntos sin coordenadas
      datatable(diag$puntos_sin_coordenadas, 
                options = list(pageLength = 10, scrollX = TRUE), 
                rownames = FALSE,
                caption = "Puntos sin coordenadas")
    } else if (tiene_datos(diag$puntos_sin_match_espacial)) {
      # Caso 1: puntos sin match espacial
      datatable(diag$puntos_sin_match_espacial, 
                options = list(pageLength = 10, scrollX = TRUE), 
                rownames = FALSE,
                caption = "Puntos que no cayeron en ninguna grilla")
    } else {
      # Sin problemas - Match exitoso
      datatable(
        data.frame(Mensaje = "✅ Excelente! Todos los puntos tienen match correcto. No hay puntos perdidos."), 
        options = list(pageLength = 5, dom = 't', ordering = FALSE, searching = FALSE), 
        rownames = FALSE
      )
    }
  })
  
  # Listas de puntos solo en cada archivo
  output$lista_puntos_solo_muestra <- renderPrint({
    diag <- diagnostico_enriquecimiento()
    
    if (is.null(diag)) {
      cat("ℹ️ No hay diagnóstico disponible aún")
      return()
    }
    
    if (!is.null(diag$puntos_solo_en_muestra) && length(diag$puntos_solo_en_muestra) > 0) {
      cat(paste(diag$puntos_solo_en_muestra, collapse = ", "))
    } else if (!is.null(diag$puntos_solo_en_coord) && length(diag$puntos_solo_en_coord) > 0) {
      cat("Puntos solo en archivo de coordenadas:\n")
      cat(paste(diag$puntos_solo_en_coord, collapse = ", "))
    } else {
      cat("✅ No hay puntos huérfanos")
    }
  })
  
  output$lista_puntos_solo_lab <- renderPrint({
    diag <- diagnostico_enriquecimiento()
    
    if (is.null(diag)) {
      cat("ℹ️ No hay diagnóstico disponible aún")
      return()
    }
    
    if (!is.null(diag$puntos_solo_en_lab) && length(diag$puntos_solo_en_lab) > 0) {
      cat(paste(diag$puntos_solo_en_lab, collapse = ", "))
    } else {
      cat("✅ No hay puntos extra en laboratorio")
    }
  })
  
  # Descargar reporte de diagnóstico
  output$descargar_diagnostico_match_btn <- downloadHandler(
    filename = function() {
      paste("diagnostico_match-", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      diag <- diagnostico_enriquecimiento()
      
      sink(file)
      cat("═══════════════════════════════════════════\n")
      cat("  DIAGNÓSTICO COMPLETO DE MATCH\n")
      cat("  Generado:", as.character(Sys.time()), "\n")
      cat("═══════════════════════════════════════════\n\n")
      
      # Si no hay diagnóstico
      if (is.null(diag)) {
        cat("ℹ️ NO HAY DIAGNÓSTICO DISPONIBLE\n\n")
        cat("Cargue y unifique los datos en la Fase 5\n")
        cat("para generar el diagnóstico de match.\n")
        sink()
        return()
      }
      
      # Detectar caso y escribir diagnóstico completo
      es_caso1 <- !is.null(diag$n_puntos_coord_original)
      
      if (es_caso1) {
        cat("CASO 1: MATCHING ESPACIAL\n\n")
        cat("Match Lab-Coordenadas:\n")
        cat("  Puntos lab:", if(!is.null(diag$n_puntos_lab_original)) diag$n_puntos_lab_original else 0, "\n")
        cat("  Puntos coord:", if(!is.null(diag$n_puntos_coord_original)) diag$n_puntos_coord_original else 0, "\n")
        cat("  Match:", if(!is.null(diag$n_puntos_en_ambos)) diag$n_puntos_en_ambos else 0, "\n\n")
        
        if (!is.null(diag$puntos_solo_en_lab) && length(diag$puntos_solo_en_lab) > 0) {
          cat("Puntos solo en lab:\n")
          cat(paste(diag$puntos_solo_en_lab, collapse = ", "), "\n\n")
        }
        
        if (!is.null(diag$puntos_sin_match_espacial) && is.data.frame(diag$puntos_sin_match_espacial) && nrow(diag$puntos_sin_match_espacial) > 0) {
          cat("\nPuntos sin match espacial:\n")
          print(diag$puntos_sin_match_espacial)
        } else {
          cat("\n✅ Todos los puntos tienen match espacial correcto\n")
        }
      } else {
        cat("CASO 2: MATCHING POR CÓDIGOS\n\n")
        cat("Match Muestra-Lab:\n")
        cat("  Puntos muestra:", if(!is.null(diag$n_puntos_muestra_original)) diag$n_puntos_muestra_original else 0, "\n")
        cat("  Puntos lab:", if(!is.null(diag$n_puntos_lab_original)) diag$n_puntos_lab_original else 0, "\n")
        cat("  Match:", if(!is.null(diag$n_puntos_en_ambos)) diag$n_puntos_en_ambos else 0, "\n")
        cat("  Perdidos:", if(!is.null(diag$n_puntos_perdidos)) diag$n_puntos_perdidos else 0, "\n\n")
        
        if (!is.null(diag$puntos_sin_tph) && is.data.frame(diag$puntos_sin_tph) && nrow(diag$puntos_sin_tph) > 0) {
          cat("\nPuntos perdidos:\n")
          print(diag$puntos_sin_tph)
        } else {
          cat("\n✅ Todos los puntos de la muestra tienen resultados de laboratorio\n")
        }
      }
      
      sink()
    }
  )
  
  # Cargar handlers y outputs adicionales de Fase 5
  # IMPORTANTE: local = TRUE para ejecutar en el entorno del servidor con acceso a output, input, session
  tryCatch({
    source("scripts/server-fase5-handlers.R", local = TRUE, encoding = "UTF-8")
  }, error = function(e) {
    message("Nota: No se pudieron cargar handlers adicionales de Fase 5: ", e$message)
    registrar_error(e$message, "Carga de handlers Fase 5")
  })
  
  # ============================================================================ #
  # SISTEMA DE ERRORES                                                          #
  # ============================================================================ #
  
  # Mostrar el registro de errores
  output$registro_errores <- renderPrint({
    errores <- registro_errores_lista()
    
    if (length(errores) == 0) {
      cat("No se han registrado errores.\n")
      cat("\n")
      cat("✅ La aplicación está funcionando correctamente.")
    } else {
      cat("REGISTRO DE ERRORES DE LA APLICACIÓN\n")
      cat("=====================================\n\n")
      
      # Mostrar errores en orden cronológico inverso (más recientes primero)
      for (i in length(errores):1) {
        error <- errores[[i]]
        cat(sprintf("[%s] %s\n", error$timestamp, 
                   if(error$contexto != "") paste0("(", error$contexto, ") ") else ""))
        cat(sprintf("Error: %s\n", error$mensaje))
        cat("---\n")
      }
      
      cat(sprintf("\nTotal de errores registrados: %d\n", length(errores)))
    }
  })
  
  # Limpiar el registro de errores
  observeEvent(input$limpiar_errores_btn, {
    registro_errores_lista(list())
    showNotification("Registro de errores limpiado.", type = "message")
  })
  
  # Descargar log de errores
  output$descargar_errores_btn <- downloadHandler(
    filename = function() {
      paste("log_errores_bietapico-", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      errores <- registro_errores_lista()
      
      if (length(errores) == 0) {
        writeLines("No se han registrado errores.", file)
      } else {
        lineas <- c(
          "REGISTRO DE ERRORES - APLICACIÓN MUESTREO BIETÁPICO",
          paste("Generado el:", Sys.time()),
          paste(rep("=", 60), collapse = ""),
          ""
        )
        
        for (i in 1:length(errores)) {
          error <- errores[[i]]
          lineas <- c(lineas,
                     sprintf("ERROR #%d", i),
                     sprintf("Fecha/Hora: %s", error$timestamp),
                     sprintf("Contexto: %s", if(error$contexto != "") error$contexto else "General"),
                     sprintf("Mensaje: %s", error$mensaje),
                     "",
                     paste(rep("-", 40), collapse = ""),
                     "")
        }
        
        lineas <- c(lineas, sprintf("Total de errores: %d", length(errores)))
        writeLines(lineas, file)
      }
    }
  )
}

# Correr la aplicación
shinyApp(ui = ui, server = server) 
