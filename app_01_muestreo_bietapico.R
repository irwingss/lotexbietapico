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
                        p(strong("Columnas:"), "LOCACION, AREA, COD_CELDA"),
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
                        p(strong("Nota:"), " Los nombres de columnas se estandarizan automáticamente a mayúsculas al cargar los archivos.")
                      ),
                      tags$hr(),
                      div(class = "card",
                        fileInput("archivo_marco_celdas", "Seleccionar archivo Excel de marco de CELDAS",
                                  accept = c(".xlsx", ".xls")),
                        fileInput("archivo_marco_grillas", "Seleccionar archivo Excel de marco de GRILLAS",
                                  accept = c(".xlsx", ".xls")),
                        actionButton("cargar_marcos_btn", "Cargar marcos", 
                                    class = "btn-primary btn-block")
                      ),
                      tags$hr(),
                      h3("2B. Verificación de Marcos", class = "fade-in"),
                      div(class = "card",
                        actionButton("verificar_marcos_btn", "Verificar integridad", 
                                    class = "btn-success btn-block")
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
                      tabPanel("Verificación de Locaciones", 
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
                      tabPanel("Verificación de Grillas", 
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
                      tabPanel("Verificación Cruzada", 
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
                        fileInput("archivo_pozos_referencia", "Seleccionar archivo Excel de pozos",
                                  accept = c(".xlsx", ".xls")),
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
                                    choices = c(
                                      "Caso 1: Expedientes antiguos (3 archivos)" = "caso1",
                                      "Caso 2: Expedientes recientes (2 archivos)" = "caso2"
                                    ),
                                    selected = "caso2"),
                        tags$hr(),
                        
                        # ARCHIVO OBLIGATORIO - Resultados de Laboratorio
                        p(strong("OBLIGATORIO:"), " Resultados de Laboratorio (BASE PRINCIPAL)"),
                        p(em("Columnas:"), " locacion, punto, tph, prof"),
                        fileInput("archivo_resultados_lab", "Archivo Excel Resultados Lab (REMA/RAR)",
                                  accept = c(".xlsx", ".xls")),
                        tags$hr(),
                        
                        # CASO 1: Expedientes antiguos
                        conditionalPanel(
                          condition = "input.caso_carga == 'caso1'",
                          h5("Archivos adicionales para Caso 1:"),
                          p(strong("Archivo A:"), " Coordenadas de puntos"),
                          p(em("Columnas:"), " punto, norte, este, altitud, prof, ca"),
                          fileInput("archivo_coordenadas", "Coordenadas Puntos",
                                    accept = c(".xlsx", ".xls")),
                          p(strong("Archivo B:"), " Marco de grillas"),
                          p(em("Columnas:"), " locacion, celda_cod_plano, celda, grilla, norte, este, prof, area"),
                          fileInput("archivo_marco_grillas", "Marco Grillas Final",
                                    accept = c(".xlsx", ".xls"))
                        ),
                        
                        # CASO 2: Expedientes recientes
                        conditionalPanel(
                          condition = "input.caso_carga == 'caso2'",
                          h5("Archivo adicional para Caso 2:"),
                          p(strong("Muestra Final:"), " Exportada de Fase 4. Muestreo Bietápico."),
                          p(em("Nota:"), " Ya contiene coordenadas, códigos de grilla, celda, etc."),
                          fileInput("archivo_muestra_final", "Muestra Final (Fase 4)",
                                    accept = c(".xlsx", ".xls"))
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
                      tabPanel("Resumen final y shapefiles", 
                               h3("Reporte Final de Resultados", class = "fade-in"),
                               div(class = "card fade-in",
                                 h4("Resumen Ejecutivo"),
                                 verbatimTextOutput("reporte_final_resultados")
                               ),
                               tags$br(),
                               div(class = "card fade-in",
                                 h4("Códigos de Elementos Contaminados"),
                                 fluidRow(
                                   column(width = 4,
                                          h5("Grillas Contaminadas"),
                                          verbatimTextOutput("codigos_grillas_contaminadas")),
                                   column(width = 4,
                                          h5("Celdas Contaminadas"),
                                          verbatimTextOutput("codigos_celdas_contaminadas")),
                                   column(width = 4,
                                          h5("Locaciones Contaminadas"),
                                          verbatimTextOutput("codigos_locaciones_contaminadas"))
                                 )
                               ),
                               tags$br(),
                               div(class = "card fade-in",
                                 h4("Exportar Reporte Completo"),
                                 downloadButton("descargar_reporte_completo_btn", 
                                               "Descargar Reporte Completo (.xlsx)", 
                                               class = "btn-success btn-block")
                               ),
                               tags$br(),
                               div(class = "card fade-in",
                                 h4("Exportar Shapefiles Contaminados"),
                                 p("Descarga shapefiles de grillas y celdas con columna CRITERIO_CONTAMINACION"),
                                 downloadButton("descargar_shapefiles_contaminados_btn", 
                                               "Descargar Shapefiles Contaminados (.zip)", 
                                               class = "btn-warning btn-block")
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
  
  # Variables reactivas - Fase 2
  marco_celdas <- reactiveVal(NULL)
  marco_grillas <- reactiveVal(NULL)
  conteo_celdas_por_locacion <- reactiveVal(NULL)
  conteo_grillas_por_celda <- reactiveVal(NULL)
  locaciones_faltantes <- reactiveVal(NULL)
  celdas_con_pocas_grillas <- reactiveVal(NULL)
  celdas_solo_en_marco_celdas <- reactiveVal(NULL)
  celdas_solo_en_marco_grillas <- reactiveVal(NULL)
  
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
  
  # Función para cargar los datos cuando se presione el botón
  observeEvent(input$cargar_btn, {
    req(input$archivo_excel)
    
    # Leer el archivo Excel
    tryCatch({
      datos <- read_excel(input$archivo_excel$datapath)
      
      # Estandarizar nombres de columnas (convertir a mayúsculas y mapear variaciones)
      datos <- estandarizar_columnas(datos)
      
      # Verificar que existan las columnas requeridas para celdas preliminares
      verificar_columnas_requeridas(datos, c("LOCACION", "AREA", "COD_CELDA"), "archivo de celdas preliminares")
      
      marco_celdas_original(datos) # Guardar en la variable reactiva
      showNotification("Archivo cargado exitosamente con columnas estandarizadas", type = "message")
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
      # Cargar marco de celdas
      datos_celdas <- read_excel(input$archivo_marco_celdas$datapath)
      # Estandarizar nombres de columnas
      datos_celdas <- estandarizar_columnas(datos_celdas)
      # Verificar columnas requeridas para marco de celdas
      verificar_columnas_requeridas(datos_celdas, c("COD_CELDA", "LOCACION"), "marco de celdas")
      marco_celdas(datos_celdas)
      
      # Cargar marco de grillas
      datos_grillas <- read_excel(input$archivo_marco_grillas$datapath)
      # Estandarizar nombres de columnas
      datos_grillas <- estandarizar_columnas(datos_grillas)
      # Verificar columnas requeridas para marco de grillas (ESTE, NORTE, PROF son clave)
      verificar_columnas_requeridas(datos_grillas, c("COD_CELDA", "ESTE", "NORTE", "PROF"), "marco de grillas")
      marco_grillas(datos_grillas)
      
      # Mostrar notificación de éxito
      showNotification("Marcos cargados exitosamente con columnas estandarizadas", type = "message")
      
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
      conteo_por_celda <- marco_grillas() %>% 
        count(COD_CELDA) %>% 
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
      
      # Estandarizar nombres de columnas
      pozos_data <- estandarizar_columnas(pozos_data)
      
      # Verificar que existan las columnas requeridas
      verificar_columnas_requeridas(pozos_data, c("LOCACION", "ESTE", "NORTE", "ALTITUD"), "archivo de pozos de referencia")
      
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
  promedios_celdas_resultado <- reactiveVal(NULL)
  promedios_locaciones_resultado <- reactiveVal(NULL)
  vertices_grillas_resultado <- reactiveVal(NULL)
  vertices_celdas_tph_resultado <- reactiveVal(NULL)
  vertices_celdas_prop_resultado <- reactiveVal(NULL)
  
  # Variables reactivas para shapefiles
  shp_grillas_data <- reactiveVal(NULL)
  shp_celdas_data <- reactiveVal(NULL)
  columnas_shp_grillas <- reactiveVal(NULL)
  columnas_shp_celdas <- reactiveVal(NULL)
  
  # Cargar y unificar datos - Maneja CASO 1 y CASO 2
  observeEvent(input$cargar_datos_resultados_btn, {
    req(input$archivo_resultados_lab)
    
    tryCatch({
      # PASO 1: Cargar y limpiar resultados de laboratorio (BASE PRINCIPAL)
      resultados_lab <- read_excel(input$archivo_resultados_lab$datapath)
      resultados_lab <- estandarizar_columnas(resultados_lab)
      
      # Verificar columnas requeridas (en MAYÚSCULAS después de estandarizar)
      if (!all(c("PUNTO", "TPH") %in% names(resultados_lab))) {
        stop("El archivo de resultados debe contener las columnas: punto, tph (o sus variaciones)")
      }
      
      # Limpiar resultados de laboratorio
      resultados_lab_clean <- limpiar_resultados_laboratorio(resultados_lab)
      
      # PASO 2: Enriquecer según el caso seleccionado
      caso <- input$caso_carga
      
      if (caso == "caso1") {
        # CASO 1: Expedientes antiguos (3 archivos)
        showNotification("Procesando Caso 1: Expedientes antiguos...", type = "message", duration = 3)
        
        # Cargar archivo de coordenadas (opcional)
        coordenadas <- NULL
        if (!is.null(input$archivo_coordenadas)) {
          coordenadas <- read_excel(input$archivo_coordenadas$datapath)
          coordenadas <- estandarizar_columnas(coordenadas)
        }
        
        # Cargar archivo de marco de grillas (opcional)
        marco_grillas <- NULL
        if (!is.null(input$archivo_marco_grillas)) {
          marco_grillas <- read_excel(input$archivo_marco_grillas$datapath)
          marco_grillas <- estandarizar_columnas(marco_grillas)
        }
        
        # Enriquecer con Caso 1
        muestra_enriq <- enriquecer_caso1(resultados_lab_clean, coordenadas, marco_grillas)
        
      } else {
        # CASO 2: Expedientes recientes (2 archivos)
        showNotification("Procesando Caso 2: Expedientes recientes...", type = "message", duration = 3)
        
        if (is.null(input$archivo_muestra_final)) {
          stop("Para el Caso 2 debe cargar el archivo de Muestra Final (Fase 4)")
        }
        
        # Cargar muestra final de Fase 4
        muestra_final <- read_excel(input$archivo_muestra_final$datapath)
        muestra_final <- estandarizar_columnas(muestra_final)
        
        # Enriquecer con Caso 2
        muestra_enriq <- enriquecer_caso2(resultados_lab_clean, muestra_final)
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
    
    cat("═══════════════════════════════════════════\n")
    cat("  MUESTRA FINAL ENRIQUECIDA\n")
    cat("═══════════════════════════════════════════\n\n")
    
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
      
      # Calcular promedios por celdas (solo si existe CELDA)
      if ("CELDA" %in% names(datos)) {
        prom_celdas <- calcular_promedios_celdas(datos, umbral)
        promedios_celdas_resultado(prom_celdas)
        showNotification("✓ Análisis por celdas completado", type = "message", duration = 3)
      } else {
        showNotification("⚠ No se encontró columna CELDA - análisis por celdas omitido", 
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
    
    # Obtener códigos únicos contaminados
    codigos_unicos <- grillas_contam %>% 
      pull(if("GRILLA" %in% names(grillas_contam)) GRILLA else PUNTO) %>% 
      unique() %>% 
      sort()
    
    cat("Total de puntos:", nrow(datos), "\n")
    cat("Puntos contaminados:", nrow(grillas_contam), "\n")
    cat("Contaminadas únicas (ambos criterios):", length(codigos_unicos), "\n\n")
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
    
    datatable(grillas_contam, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) %>%
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
      div(style = "background-color: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
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
      div(style = "background-color: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 4px; margin-bottom: 10px;",
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
