# MANUAL DE PROCEDIMIENTO DE USO DE LA APLICACIÓN

## I. ÍNDICE

**I. ÍNDICE** ............................................................. 2

**II. OBJETIVO** .......................................................... 3

**III. PROPÓSITO DE LA APP** .............................................. 4

**IV. ESTRUCTURA GENERAL DE LA APLICACIÓN** .............................. 5
   - IV.1. Arquitectura del Sistema ..................................... 5
   - IV.2. Componentes Principales ...................................... 6
   - IV.3. Flujo de Procesamiento de Datos .............................. 7
   - IV.4. Tecnologías y Dependencias ................................... 8

**V. REQUISITOS PREVIOS AL USO** ......................................... 9
   - V.1. Requisitos de Hardware ........................................ 9
   - V.2. Requisitos de Software ........................................ 10
   - V.3. Formato de Datos de Entrada ................................... 11
   - V.4. Conocimientos Técnicos Requeridos ............................. 12

**VI. INSTALACIÓN O ACCESO** ............................................. 13
   - VI.1. Acceso Web Directo ........................................... 13
   - VI.2. Instalación Local ............................................ 14
   - VI.3. Despliegue con Docker ........................................ 15
   - VI.4. Verificación de la Instalación ............................... 16

**VII. PROCEDIMENTO DE USO PASO A PASO POR PESTAÑA** .................... 17
   - VII.1. Pestaña 1: Carga Inicial y Análisis de Percentiles ......... 17
   - VII.2. Pestaña 2: Carga de Marcos Muestrales ....................... 22
   - VII.3. Pestaña 3: Cálculo del Tamaño Muestral ..................... 27
   - VII.4. Pestaña 4: Ejecución del Muestreo Bietápico ................ 30
   - VII.5. Pestaña de Errores: Monitoreo y Diagnóstico ................ 36

**VIII. RESOLUCIÓN DE PROBLEMAS** ........................................ 38
   - VIII.1. Errores Comunes de Carga de Datos ......................... 38
   - VIII.2. Problemas de Formato de Archivos .......................... 40
   - VIII.3. Errores de Cálculo Estadístico ............................ 42
   - VIII.4. Problemas de Exportación .................................. 44
   - VIII.5. Diagnóstico Avanzado ....................................... 46

**IX. GLOSARIO DE TÉRMINOS** ............................................. 48
   - IX.1. Términos Estadísticos ........................................ 48
   - IX.2. Términos Geoespaciales ....................................... 50
   - IX.3. Términos de Muestreo ......................................... 52
   - IX.4. Términos Técnicos de la Aplicación .......................... 54

## II. OBJETIVO

El presente manual tiene como objetivo principal proporcionar una guía técnica integral y científicamente fundamentada para el uso eficiente de la aplicación de diseño de muestreo bietápico desarrollada para análisis geoespaciales y estadísticos en estudios ambientales.

### Objetivos Específicos:

**2.1. Objetivo Metodológico:**
Establecer los procedimientos estandarizados para la implementación de diseños de muestreo bietápico, garantizando la aplicación correcta de principios estadísticos y geoespaciales en la selección de unidades primarias de muestreo (UPM) y unidades secundarias de muestreo (USM).

**2.2. Objetivo Operativo:**
Facilitar la operación sistemática de la aplicación web, desde la carga inicial de datos hasta la exportación de resultados finales, asegurando la reproducibilidad y trazabilidad de todos los procesos analíticos.

**2.3. Objetivo de Calidad:**
Garantizar la integridad, precisión y validez científica de los resultados obtenidos mediante la aplicación, estableciendo controles de calidad y procedimientos de verificación en cada etapa del proceso.

**2.4. Objetivo de Capacitación:**
Proveer los conocimientos técnicos necesarios para que los usuarios puedan interpretar correctamente los resultados estadísticos, comprender las limitaciones metodológicas y tomar decisiones informadas basadas en los análisis realizados.

**2.5. Objetivo de Estandarización:**
Unificar criterios y procedimientos para el manejo de datos geoespaciales, cálculos estadísticos y generación de reportes, asegurando consistencia en la aplicación de la metodología de muestreo bietápico en diferentes contextos y proyectos.

Este manual está dirigido a profesionales en ciencias ambientales, estadística aplicada, ingeniería ambiental y disciplinas afines que requieran implementar diseños de muestreo espacialmente representativos con rigor científico y eficiencia operativa.

## III. PROPÓSITO DE LA APP

La aplicación de Diseño Bietápico constituye una herramienta científico-técnica especializada desarrollada para la implementación sistemática de metodologías de muestreo probabilístico en dos etapas, optimizando la representatividad espacial y la eficiencia estadística en estudios ambientales y territoriales.

### 3.1. Fundamento Científico

El muestreo bietápico representa una metodología estadística avanzada que permite la selección probabilística de unidades de muestreo en dos fases secuenciales:

- **Primera Etapa (Unidades Primarias):** Selección de locaciones o áreas geográficas mediante técnicas de muestreo aleatorio estratificado
- **Segunda Etapa (Unidades Secundarias):** Selección de puntos específicos de muestreo dentro de cada unidad primaria seleccionada

Esta aproximación metodológica maximiza la eficiencia del diseño muestral al reducir costos operativos mientras mantiene la precisión estadística requerida para inferencias poblacionales válidas.

### 3.2. Capacidades Funcionales Principales

**3.2.1. Procesamiento de Datos Geoespaciales:**
- Carga y validación de archivos Excel con datos de celdas preliminares
- Estandarización automática de nomenclatura de columnas (LOCACION, AREA, COD_CELDA)
- Integración de marcos muestrales de celdas y grillas con coordenadas UTM
- Manejo de sistemas de referencia espacial y transformaciones geométricas

**3.2.2. Análisis Estadístico Avanzado:**
- Cálculo de percentiles de área para optimización de tamaños de rejilla
- Determinación del tamaño muestral óptimo mediante algoritmos de TeachingSampling
- Implementación de técnicas de clustering espacial usando DBSCAN
- Análisis de distribuciones espaciales y detección de patrones geográficos

**3.2.3. Algoritmos de Muestreo:**
- Muestreo aleatorio simple y estratificado para unidades primarias
- Algoritmos de vecino más cercano para optimización de rutas de campo
- Asignación proporcional y óptima de unidades secundarias
- Control de restricciones espaciales y operativas

**3.2.4. Generación de Productos Cartográficos:**
- Creación automática de códigos únicos de identificación para puntos de muestreo
- Cálculo de distancias y orientaciones cardinales a pozos de referencia
- Exportación a formatos Shapefile (.shp) con metadatos completos
- Generación de archivos Excel con tablas estructuradas para trabajo de campo

### 3.3. Aplicaciones Científicas

**3.3.1. Estudios de Contaminación Ambiental:**
- Caracterización de suelos impactados con representatividad espacial
- Monitoreo de calidad de aguas subterráneas en áreas extensas
- Evaluación de impactos ambientales en ecosistemas terrestres

**3.3.2. Investigación Geológica y Minera:**
- Exploración mineral con optimización de recursos de perforación
- Caracterización geotécnica de grandes extensiones territoriales
- Estudios de estabilidad de taludes y riesgo geológico

**3.3.3. Planificación Territorial:**
- Inventarios de recursos naturales con criterios estadísticos
- Evaluación de aptitud de suelos para diferentes usos
- Zonificación ambiental basada en evidencia científica

### 3.4. Ventajas Metodológicas

**3.4.1. Eficiencia Operativa:**
- Reducción significativa de costos de campo mediante optimización espacial
- Minimización de tiempo de desplazamiento entre puntos de muestreo
- Automatización de cálculos complejos y reducción de errores humanos

**3.4.2. Rigor Científico:**
- Garantía de representatividad estadística mediante técnicas probabilísticas
- Trazabilidad completa de todos los procesos analíticos
- Reproducibilidad de resultados mediante control de semillas aleatorias

**3.4.3. Flexibilidad Adaptativa:**
- Capacidad de ajuste a diferentes escalas espaciales y temporales
- Integración con múltiples fuentes de datos geoespaciales
- Compatibilidad con estándares internacionales de calidad (ISO, EPA)

La aplicación representa una solución integral que combina fundamentos teóricos sólidos con implementación práctica eficiente, facilitando la toma de decisiones basada en evidencia científica robusta.

## IV. ESTRUCTURA GENERAL DE LA APLICACIÓN

La aplicación de Diseño Bietápico está construida sobre una arquitectura modular y escalable que integra tecnologías web modernas con algoritmos estadísticos especializados, garantizando robustez, eficiencia y mantenibilidad del sistema.

### IV.1. Arquitectura del Sistema

**4.1.1. Patrón Arquitectónico:**
La aplicación implementa el patrón Model-View-Controller (MVC) adaptado al framework Shiny de R, donde:

- **Model (Modelo):** Funciones especializadas en `scripts/` que encapsulan la lógica de negocio y algoritmos estadísticos
- **View (Vista):** Interfaz de usuario reactiva definida en el objeto `ui` con componentes HTML5 y CSS3
- **Controller (Controlador):** Lógica del servidor en el objeto `server` que gestiona eventos y estados reactivos

**4.1.2. Arquitectura de Capas:**
```
┌──────────────────────────────────────────────────┐
│              CAPA DE PRESENTACIÓN                    │
│    (Interfaz Web Reactiva - Shiny UI)           │
├──────────────────────────────────────────────────┤
│              CAPA DE APLICACIÓN                     │
│      (Lógica de Negocio - Shiny Server)         │
├──────────────────────────────────────────────────┤
│              CAPA DE SERVICIOS                      │
│    (Funciones Especializadas - scripts/)        │
├──────────────────────────────────────────────────┤
│               CAPA DE DATOS                        │
│  (Parámetros Precalculados - parametros.RData)   │
└──────────────────────────────────────────────────┘
```

### IV.2. Componentes Principales

**4.2.1. Módulo de Interfaz de Usuario (`ui`):**

*Estructura de Navegación:*
- **navbarPage:** Contenedor principal con navegación por pestañas
- **tabPanel:** Cinco pestañas funcionales especializadas
- **fluidRow/column:** Sistema de grilla responsiva Bootstrap
- **wellPanel:** Paneles de control con agrupación lógica

*Componentes Interactivos:*
- **fileInput:** Cargadores de archivos Excel con validación de formato
- **actionButton:** Botones de acción con retroalimentación visual
- **DT::dataTableOutput:** Tablas interactivas con funcionalidades avanzadas
- **downloadButton:** Exportadores con múltiples formatos de salida

**4.2.2. Módulo de Lógica del Servidor (`server`):**

*Variables Reactivas:*
```r
# Variables de Estado Principal
marco_celdas_original()     # Datos originales sin modificaciones
marco_celdas_filtrado()     # Datos procesados y filtrados
bd_percentiles_completa()   # Resultados de análisis de percentiles
datos_finales_df()          # Muestra final con códigos generados

# Variables de Control
registro_errores_lista      # Sistema de manejo de errores
simulacion_activa()         # Estado de simulaciones
```

*Observadores de Eventos:*
- **observeEvent:** Manejadores de eventos de interfaz de usuario
- **reactive:** Expresiones reactivas para cálculos dinámicos
- **renderDT/renderUI:** Renderizadores de componentes dinámicos

**4.2.3. Módulo de Funciones Especializadas (`scripts/`):**

*Funciones de Procesamiento de Datos:*
- **`f-estandarizar_columnas.R`:** Normalización de nomenclatura de columnas
- **`f-corregir_nombres_loc.R`:** Corrección de nombres de locaciones
- **`f-normalize.R`:** Funciones de normalización matemática
- **`f-nfil.R`:** Utilidades de filtrado de datos

*Funciones de Análisis Geoespacial:*
- **`f-calcular_distancias_pozos.R`:** Cálculos de distancia y orientación cardinal

### IV.3. Flujo de Procesamiento de Datos

**4.3.1. Fase de Inicialización:**
```
1. Carga de Paquetes → 2. Carga de Scripts → 3. Carga de Parámetros
         ↓                      ↓                     ↓
   Validación de      Verificación de      Carga de parametros.RData
   Dependencias       Integridad de         (866KB de datos
                      Funciones             precalculados)
```

**4.3.2. Flujo de Datos Principal:**
```
Carga Excel → Estandarización → Validación → Análisis Percentiles
     ↓                ↓               ↓              ↓
Archivos de    Normalización de   Control de    Cálculos
Celdas/Grillas   Columnas       Integridad    Estadísticos
     ↓                ↓               ↓              ↓
Marcos         Mapeo de        Detección     Selección de
Muestrales     Variaciones     de Errores    Umbrales
     ↓                ↓               ↓              ↓
Muestreo       Integración     Registro      Generación de
Bietápico      de Datos       de Log        Muestra Final
     ↓                ↓               ↓              ↓
Generación     Cálculo de      Sistema de    Exportación
de Códigos     Distancias     Alertas       (Excel/SHP)
```

**4.3.3. Manejo de Estados y Errores:**
- **Sistema de Logging:** Captura automática de errores con contexto temporal
- **Validación de Integridad:** Verificación de formatos y estructuras de datos
- **Recuperación de Estados:** Capacidad de revertir simulaciones y cambios
- **Notificaciones Reactivas:** Retroalimentación inmediata al usuario

### IV.4. Tecnologías y Dependencias

**4.4.1. Framework Principal:**
- **R (v4.2.2+):** Lenguaje de programación estadística
- **Shiny:** Framework web reactivo para R
- **shinydashboard:** Extensiones de interfaz de usuario

**4.4.2. Paquetes Estadísticos:**
- **TeachingSampling:** Algoritmos de diseño muestral
- **dbscan:** Clustering espacial basado en densidad
- **dplyr:** Manipulación eficiente de datos

**4.4.3. Paquetes Geoespaciales:**
- **sf:** Manejo de datos vectoriales geoespaciales
- **sp:** Clases y métodos para datos espaciales

**4.4.4. Paquetes de E/S:**
- **readxl:** Lectura de archivos Excel
- **openxlsx:** Escritura de archivos Excel con formato
- **DT:** Tablas interactivas HTML

**4.4.5. Infraestructura de Despliegue:**
- **Docker:** Containerización con imagen `rocker/geospatial:4.2.2`
- **Render:** Plataforma de despliegue en la nube
- **Sistema Operativo:** Compatible con Linux/Windows/macOS

Esta arquitectura modular garantiza escalabilidad, mantenibilidad y extensibilidad del sistema, permitiendo futuras mejoras y adaptaciones sin comprometer la estabilidad operativa.

## V. REQUISITOS PREVIOS AL USO

La operación eficiente de la aplicación de Diseño Bietápico requiere el cumplimiento de especificaciones técnicas mínimas y la disponibilidad de recursos computacionales adecuados para garantizar el procesamiento óptimo de datos geoespaciales y cálculos estadísticos complejos.

### V.1. Requisitos de Hardware

**5.1.1. Especificaciones Mínimas:**

*Procesador:*
- **CPU:** Intel Core i5-8400 / AMD Ryzen 5 2600 o superior
- **Arquitectura:** x64 (64 bits) obligatorio
- **Frecuencia:** Mínimo 2.8 GHz base, 3.4 GHz boost recomendado
- **Núcleos:** Mínimo 4 núcleos físicos, 6+ recomendado para datasets grandes

*Memoria RAM:*
- **Mínimo:** 8 GB DDR4
- **Recomendado:** 16 GB DDR4 para datasets >10,000 registros
- **Óptimo:** 32 GB DDR4 para procesamiento de múltiples locaciones simultáneas
- **Consideración Técnica:** R carga datasets completos en memoria; datasets de 50,000+ celdas requieren >16GB

*Almacenamiento:*
- **Espacio Mínimo:** 2 GB disponibles
- **Tipo Recomendado:** SSD NVMe para acceso rápido a archivos temporales
- **Espacio de Trabajo:** 500 MB adicionales por proyecto activo
- **Archivos Temporales:** Hasta 200 MB durante procesamiento de Shapefiles

*Conectividad:*
- **Red:** Conexión a Internet estable (mínimo 10 Mbps) para acceso web
- **Latencia:** <100ms para operación fluida de interfaz reactiva
- **Ancho de Banda:** 50+ Mbps recomendado para carga de archivos Excel grandes

**5.1.2. Especificaciones Recomendadas para Uso Profesional:**

*Configuración Óptima:*
- **CPU:** Intel Core i7-12700K / AMD Ryzen 7 5800X
- **RAM:** 32 GB DDR4-3200 o superior
- **Almacenamiento:** SSD NVMe 1TB + HDD 2TB para respaldos
- **GPU:** No requerida (procesamiento CPU-intensivo)

### V.2. Requisitos de Software

**5.2.1. Sistema Operativo:**

*Sistemas Compatibles:*
- **Windows:** Windows 10 (v1903+) / Windows 11
- **macOS:** macOS 10.15 Catalina o superior
- **Linux:** Ubuntu 20.04 LTS, CentOS 8, Debian 10+

*Configuraciones Específicas:*
- **Codificación:** UTF-8 habilitado para caracteres especiales
- **Permisos:** Acceso de escritura en directorio de trabajo
- **Firewall:** Puerto 3838 abierto para acceso local (instalación local)

**5.2.2. Entorno de Ejecución R:**

*Versión de R:*
- **Mínimo:** R 4.1.0
- **Recomendado:** R 4.2.2 o superior
- **Fuente:** CRAN oficial (https://cran.r-project.org/)

*Paquetes Obligatorios:*
```r
# Paquetes Core
install.packages(c(
  "shiny",           # v1.7.0+
  "shinydashboard",  # v0.7.2+
  "DT",              # v0.24+
  "dplyr",           # v1.0.9+
  "readxl",          # v1.4.0+
  "openxlsx",        # v4.2.5+
))

# Paquetes Estadísticos
install.packages(c(
  "TeachingSampling", # v4.1.0+
  "dbscan",           # v1.1-11+
  "purrr"             # v0.3.4+
))

# Paquetes Geoespaciales
install.packages(c(
  "sf",               # v1.0-8+
  "sp"                # v1.5-0+
))

# Paquetes de Interfaz
install.packages(c(
  "colourpicker",     # v1.1.1+
  "uuid"              # v1.1-0+
))
```

**5.2.3. Navegador Web (para acceso web):**

*Navegadores Compatibles:*
- **Google Chrome:** v90+ (recomendado)
- **Mozilla Firefox:** v88+
- **Microsoft Edge:** v90+
- **Safari:** v14+ (macOS)

*Configuraciones Requeridas:*
- **JavaScript:** Habilitado obligatoriamente
- **Cookies:** Permitidas para sesión
- **LocalStorage:** Habilitado para estado de aplicación
- **Resolución Mínima:** 1366x768 px
- **Resolución Recomendada:** 1920x1080 px o superior

### V.3. Formato de Datos de Entrada

**5.3.1. Archivos Excel Requeridos:**

*Archivo de Celdas Preliminares:*
```
Formato: .xlsx o .xls
Columnas Obligatorias:
- LOCACION    (Texto): Identificador único de locación
- AREA        (Numérico): Área en unidades consistentes
- COD_CELDA   (Texto): Código único de celda

Ejemplo de estructura:
LOCACION | AREA  | COD_CELDA
LOC001   | 2.45  | C001
LOC001   | 3.12  | C002
LOC002   | 1.89  | C003
```

*Archivo de Marco de Celdas:*
```
Formato: .xlsx o .xls
Columnas Obligatorias:
- COD_CELDA   (Texto): Código de celda (debe coincidir con archivo principal)
- ESTE        (Numérico): Coordenada X en UTM
- NORTE       (Numérico): Coordenada Y en UTM
- PROF        (Numérico): Profundidad o elevación

Ejemplo:
COD_CELDA | ESTE    | NORTE    | PROF
C001      | 456789  | 8234567  | 1250
C002      | 456820  | 8234580  | 1245
```

*Archivo de Marco de Grillas:*
```
Formato: .xlsx o .xls
Columnas Obligatorias:
- COD_CELDA   (Texto): Código de celda de referencia
- ESTE        (Numérico): Coordenada X de punto de grilla
- NORTE       (Numérico): Coordenada Y de punto de grilla
- PROF        (Numérico): Profundidad de grilla

Nota: Múltiples registros por COD_CELDA permitidos
```

*Archivo de Pozos de Referencia (Opcional):*
```
Formato: .xlsx o .xls
Columnas Obligatorias:
- LOCACION    (Texto): Identificador de locación
- ESTE        (Numérico): Coordenada X del pozo
- NORTE       (Numérico): Coordenada Y del pozo
- ALTITUD     (Numérico): Elevación del pozo
```

**5.3.2. Consideraciones de Calidad de Datos:**

*Integridad Referencial:*
- Todos los COD_CELDA en archivo principal deben existir en marcos
- Coordenadas UTM deben estar en el mismo sistema de referencia
- No se permiten valores nulos en columnas obligatorias

*Validaciones Automáticas:*
- Detección de duplicados en códigos de celda
- Verificación de rangos válidos para coordenadas
- Control de consistencia entre archivos relacionados

### V.4. Conocimientos Técnicos Requeridos

**5.4.1. Conocimientos Estadísticos Fundamentales:**

*Conceptos Obligatorios:*
- **Muestreo Probabilístico:** Principios de selección aleatoria y representatividad
- **Diseños Muestrales:** Diferencias entre muestreo simple, estratificado y por conglomerados
- **Tamaño Muestral:** Cálculo de n óptimo basado en precisión requerida
- **Percentiles:** Interpretación de distribuciones y selección de umbrales

*Conceptos Avanzados Recomendados:*
- **Muestreo Bietápico:** Teoría de muestreo en dos etapas
- **Clustering Espacial:** Algoritmos DBSCAN y detección de agrupaciones
- **Optimización Muestral:** Balance entre precisión y costos operativos

**5.4.2. Conocimientos Geoespaciales:**

*Sistemas de Coordenadas:*
- **UTM (Universal Transverse Mercator):** Comprensión de zonas y proyecciones
- **Datum Geodésico:** WGS84, SIRGAS2000 y sistemas locales
- **Transformaciones:** Conversión entre sistemas de coordenadas

*Análisis Espacial:*
- **Distancias Euclidianas:** Cálculos en coordenadas planas
- **Orientaciones Cardinales:** Sistema de 8 direcciones principales
- **Formatos Vectoriales:** Estructura de archivos Shapefile

**5.4.3. Competencias Informáticas:**

*Nivel Básico Requerido:*
- **Manejo de Excel:** Carga, edición y formato de hojas de cálculo
- **Navegación Web:** Uso de aplicaciones web interactivas
- **Gestión de Archivos:** Organización y respaldo de datos

*Nivel Intermedio Recomendado:*
- **R Básico:** Comprensión de sintaxis y estructuras de datos
- **GIS Básico:** Conceptos de sistemas de información geográfica
- **Control de Calidad:** Validación y limpieza de datasets

**5.4.4. Conocimientos del Dominio de Aplicación:**

*Áreas de Especialización:*
- **Ciencias Ambientales:** Muestreo de suelos, aguas y sedimentos
- **Ingeniería Ambiental:** Caracterización de sitios impactados
- **Geología Aplicada:** Exploración y evaluación de recursos
- **Planificación Territorial:** Inventarios de recursos naturales

El cumplimiento de estos requisitos garantiza la operación eficiente de la aplicación y la obtención de resultados científicamente válidos y metodológicamente robustos.

## VI. INSTALACIÓN O ACCESO

La aplicación de Diseño Bietápico ofrece múltiples modalidades de acceso y despliegue, adaptadas a diferentes necesidades operativas y niveles de control técnico. Cada modalidad presenta características específicas de rendimiento, seguridad y mantenimiento.

### VI.1. Acceso Web Directo

**6.1.1. Características del Acceso Web:**

La modalidad de acceso web representa la opción más conveniente para usuarios finales, eliminando la necesidad de instalación local y garantizando acceso inmediato a la última versión de la aplicación.

*Ventajas Operativas:*
- **Acceso Inmediato:** Sin requerimientos de instalación o configuración
- **Actualizaciones Automáticas:** Versión siempre actualizada sin intervención del usuario
- **Compatibilidad Universal:** Funciona en cualquier dispositivo con navegador web
- **Mantenimiento Centralizado:** Soporte técnico y respaldos gestionados externamente

*Limitaciones Técnicas:*
- **Dependencia de Conectividad:** Requiere conexión a Internet estable
- **Latencia de Red:** Posible retraso en operaciones intensivas
- **Limitaciones de Carga:** Restricciones en tamaño de archivos según proveedor
- **Privacidad de Datos:** Los datos se procesan en servidores externos

**6.1.2. Procedimiento de Acceso:**

*Paso 1: Verificación de Requisitos*
```
1. Navegador compatible (Chrome 90+, Firefox 88+, Edge 90+)
2. Conexión a Internet activa (mínimo 10 Mbps)
3. JavaScript habilitado
4. Cookies permitidas para el dominio de la aplicación
```

*Paso 2: Acceso a la URL*
```
1. Abrir navegador web
2. Navegar a la URL proporcionada por el administrador
3. Esperar carga completa de la interfaz (indicador de carga desaparecerá)
4. Verificar que todas las pestañas sean visibles y funcionales
```

*Paso 3: Verificación de Funcionalidad*
```
1. Comprobar carga de pestaña "1. Carga inicial y Percentil"
2. Verificar disponibilidad de botón "Cargar datos"
3. Confirmar visualización correcta de paneles laterales
4. Validar responsividad de la interfaz al redimensionar ventana
```

### VI.2. Instalación Local

**6.2.1. Ventajas de la Instalación Local:**

*Control y Seguridad:*
- **Privacidad Total:** Todos los datos permanecen en el equipo local
- **Control de Versiones:** Capacidad de mantener versiones específicas
- **Independencia de Red:** Operación sin conexión a Internet
- **Personalización Avanzada:** Modificación de parámetros y configuraciones

*Rendimiento Optimizado:*
- **Velocidad Máxima:** Sin latencia de red en operaciones
- **Recursos Dedicados:** Uso completo de capacidad de hardware local
- **Archivos Grandes:** Sin restricciones de tamaño de carga
- **Procesamiento Intensivo:** Ideal para datasets extensos

**6.2.2. Procedimiento de Instalación Paso a Paso:**

*Fase 1: Preparación del Entorno*
```bash
# 1. Descargar e instalar R desde CRAN
# Visitar: https://cran.r-project.org/
# Seleccionar versión para su sistema operativo
# Ejecutar instalador con privilegios de administrador

# 2. Verificar instalación de R
R --version
# Debe mostrar: R version 4.2.2 (o superior)
```

*Fase 2: Instalación de Dependencias*
```r
# Abrir R o RStudio
# Ejecutar script de instalación de paquetes

# Paquetes fundamentales
install.packages(c(
  "shiny", "shinydashboard", "readxl", "DT", "dplyr", 
  "TeachingSampling", "dbscan", "purrr", "openxlsx", "sf",
  "colourpicker", "uuid"
), dependencies = TRUE)

# Verificar instalación exitosa
lapply(c("shiny", "sf", "TeachingSampling"), 
       function(pkg) {
         if(require(pkg, character.only = TRUE)) {
           cat(paste(pkg, "instalado correctamente\n"))
         } else {
           cat(paste("ERROR:", pkg, "no se pudo instalar\n"))
         }
       })
```

*Fase 3: Descarga y Configuración de la Aplicación*
```bash
# 1. Crear directorio de trabajo
mkdir C:\Apps\MuestreoBietapico
cd C:\Apps\MuestreoBietapico

# 2. Descargar archivos de la aplicación
# (Desde repositorio o paquete proporcionado)
# Estructura requerida:
# ├── app_01_muestreo_bietapico.R
# ├── scripts/
# │   ├── f-calcular_distancias_pozos.R
# │   ├── f-estandarizar_columnas.R
# │   └── [...otros scripts]
# ├── Parámetros generales/
# │   └── parametros.RData
# └── www/
#     └── styles_v2.css
```

*Fase 4: Ejecución y Verificación*
```r
# 1. Establecer directorio de trabajo
setwd("C:/Apps/MuestreoBietapico")

# 2. Verificar estructura de archivos
list.files(recursive = TRUE)
# Debe mostrar todos los archivos requeridos

# 3. Ejecutar aplicación
shiny::runApp("app_01_muestreo_bietapico.R", 
              host = "127.0.0.1", 
              port = 3838,
              launch.browser = TRUE)

# 4. La aplicación se abrirá automáticamente en el navegador
# URL local: http://127.0.0.1:3838
```

### VI.3. Despliegue con Docker

**6.3.1. Ventajas del Despliegue Containerizado:**

*Consistencia y Portabilidad:*
- **Entorno Aislado:** Eliminación de conflictos de dependencias
- **Reproducibilidad:** Comportamiento idéntico en diferentes sistemas
- **Escalabilidad:** Fácil replicación para múltiples usuarios
- **Mantenimiento Simplificado:** Actualizaciones mediante nuevas imágenes

**6.3.2. Requisitos Previos para Docker:**

*Instalación de Docker:*
```bash
# Windows (Docker Desktop)
# Descargar desde: https://www.docker.com/products/docker-desktop
# Ejecutar instalador y reiniciar sistema

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Verificar instalación
docker --version
# Debe mostrar: Docker version 20.10.0 o superior
```

**6.3.3. Procedimiento de Despliegue:**

*Método 1: Usando Imagen Precompilada*
```bash
# 1. Descargar imagen desde registro
docker pull [registro]/muestreo-bietapico:latest

# 2. Ejecutar contenedor
docker run -d \
  --name muestreo-bietapico \
  -p 3838:3838 \
  -v $(pwd)/data:/srv/shiny-server/app/data \
  [registro]/muestreo-bietapico:latest

# 3. Verificar ejecución
docker ps
# Debe mostrar contenedor en estado "Up"

# 4. Acceder a aplicación
# URL: http://localhost:3838
```

*Método 2: Construcción Local*
```bash
# 1. Clonar repositorio con Dockerfile
git clone [repositorio-url]
cd muestreo-bietapico

# 2. Construir imagen
docker build -t muestreo-bietapico:local .

# 3. Ejecutar contenedor
docker run -d \
  --name muestreo-local \
  -p 3838:3838 \
  muestreo-bietapico:local
```

*Configuración Avanzada con Docker Compose:*
```yaml
# docker-compose.yml
version: '3.8'
services:
  muestreo-bietapico:
    build: .
    ports:
      - "3838:3838"
    volumes:
      - ./data:/srv/shiny-server/app/data
      - ./logs:/var/log/shiny-server
    environment:
      - SHINY_LOG_LEVEL=INFO
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3838"]
      interval: 30s
      timeout: 10s
      retries: 3
```

```bash
# Ejecutar con Docker Compose
docker-compose up -d

# Monitorear logs
docker-compose logs -f

# Detener servicios
docker-compose down
```

### VI.4. Verificación de la Instalación

**6.4.1. Lista de Verificación Funcional:**

*Pruebas de Interfaz:*
```
☐ Carga completa de todas las pestañas (5 principales + Errores)
☐ Visualización correcta de paneles laterales y área principal
☐ Funcionalidad de botones de carga de archivos
☐ Responsividad de la interfaz en diferentes resoluciones
☐ Carga correcta de estilos CSS (colores, fuentes, espaciado)
```

*Pruebas de Funcionalidad Core:*
```
☐ Carga exitosa de archivo Excel de prueba
☐ Ejecución de cálculo de percentiles sin errores
☐ Generación de tabla de resultados interactiva
☐ Funcionalidad de descarga de archivos
☐ Sistema de notificaciones operativo
```

*Pruebas de Rendimiento:*
```
☐ Tiempo de carga inicial < 10 segundos
☐ Respuesta de interfaz < 2 segundos para operaciones básicas
☐ Procesamiento de dataset de prueba (1000 registros) < 30 segundos
☐ Exportación de Shapefile < 15 segundos
☐ Uso de memoria RAM < 2GB para operaciones estándar
```

**6.4.2. Diagnóstico de Problemas Comunes:**

*Error: "Paquete no encontrado"*
```r
# Solución: Reinstalar paquetes faltantes
install.packages("[nombre_paquete]", dependencies = TRUE)

# Verificar instalación
packageVersion("[nombre_paquete]")
```

*Error: "Puerto 3838 en uso"*
```bash
# Identificar proceso usando el puerto
netstat -tulpn | grep 3838

# Terminar proceso si es necesario
kill -9 [PID]

# O usar puerto alternativo
shiny::runApp(port = 3839)
```

*Error: "Memoria insuficiente"*
```r
# Verificar uso de memoria
memory.size()
memory.limit()

# Aumentar límite de memoria (Windows)
memory.limit(size = 8000)  # 8GB

# Optimizar garbage collection
gc()
```

**6.4.3. Configuración de Monitoreo:**

*Logs de Sistema:*
```r
# Habilitar logging detallado
options(shiny.trace = TRUE)
options(shiny.error = browser)

# Configurar archivo de log
sink("app_log.txt", append = TRUE, split = TRUE)
```

*Monitoreo de Recursos:*
```bash
# Monitoreo continuo de recursos (Linux/macOS)
top -p $(pgrep -f "R.*shiny")

# Windows (PowerShell)
Get-Process | Where-Object {$_.ProcessName -eq "R"} | 
  Select-Object ProcessName, CPU, WorkingSet
```

La selección de la modalidad de acceso debe basarse en los requisitos específicos de seguridad, rendimiento y control operativo de cada organización, considerando las capacidades técnicas disponibles y las políticas de manejo de datos institucionales.

## VII. PROCEDIMENTO DE USO PASO A PASO POR PESTAÑA

Esta sección proporciona una guía detallada para la operación sistemática de cada componente funcional de la aplicación, siguiendo el flujo lógico del proceso de diseño de muestreo bietápico desde la carga inicial de datos hasta la exportación de resultados finales.

### VII.1. Pestaña 1: Carga Inicial y Análisis de Percentiles

**7.1.1. Propósito y Funcionalidad:**

La primera pestaña constituye el punto de entrada principal del sistema, donde se realiza la carga de datos preliminares y el análisis estadístico fundamental para determinar umbrales óptimos de área de rejilla mediante cálculos de percentiles.

**7.1.2. Sección 1A: Cargar Archivo Excel**

*Procedimiento de Carga:*

1. **Selección de Archivo:**
   - Hacer clic en el botón "Examinar..." en la sección "1A. Cargar Archivo Excel"
   - Navegar hasta la ubicación del archivo de celdas preliminares
   - Seleccionar archivo con extensión .xlsx o .xls
   - El sistema validará automáticamente el formato

2. **Validación de Estructura:**
   ```
   Columnas Requeridas (estandarización automática):
   - LOCACION: Identificador único de locación
   - AREA: Valor numérico de área (unidades consistentes)
   - COD_CELDA: Código único de celda
   
   Variaciones Aceptadas:
   - locacion, Locacion, LOCACION, ubicacion, UBICACION
   - area, Area, AREA, superficie, SUPERFICIE
   - cod_celda, Cod_Celda, COD_CELDA, codigo_celda, celda
   ```

3. **Ejecución de Carga:**
   - Hacer clic en "Cargar datos"
   - El sistema ejecutará la función `estandarizar_columnas()`
   - Se mostrará notificación de éxito o error
   - Los datos se almacenarán en la variable reactiva `marco_celdas_original()`

*Controles de Calidad Automáticos:*
- Detección de valores nulos en columnas críticas
- Verificación de tipos de datos (numérico para AREA)
- Control de duplicados en COD_CELDA
- Validación de consistencia en LOCACION

**7.1.3. Funcionalidad de Simulación:**

*Simulación de Eliminación de Locaciones:*

1. **Configuración:**
   - Ingresar código de locación en el campo "Simular eliminación de locación"
   - El código debe coincidir exactamente con valores en columna LOCACION

2. **Ejecución de Simulación:**
   - Hacer clic en botón "Simular"
   - El sistema creará un dataset temporal excluyendo la locación especificada
   - Se activará el indicador visual de "Simulación Activa"
   - Los análisis posteriores usarán el dataset simulado

3. **Reversión:**
   - Hacer clic en botón "Revertir"
   - Se restaurará el dataset original completo
   - Se desactivará el indicador de simulación

**7.1.4. Sección 1B: Análisis de Percentiles**

*Configuración de Parámetros:*

1. **Definición de Valores de Área:**
   - Campo predeterminado: "1.4, 2.5, 2.88, 3, 3.5, 4, 4.25, 4.5, 5, 6, 7, 7.81, 8, 9"
   - Modificar valores según requerimientos del proyecto
   - Separar valores con comas
   - Usar punto decimal para números decimales

2. **Ejecución de Cálculos:**
   - Hacer clic en "Calcular Percentiles"
   - El sistema ejecutará algoritmos estadísticos avanzados
   - Se generará la tabla de percentiles completa

*Interpretación de Resultados:*

La tabla de percentiles mostrará las siguientes columnas:
- **area_rejilla:** Valor de área evaluado
- **percentil:** Percentil correspondiente en la distribución
- **n_locaciones:** Número de locaciones que cumplirían el criterio
- **n_celdas_total:** Total de celdas disponibles
- **eficiencia_muestral:** Ratio de eficiencia del diseño

**7.1.5. Selección de Umbral Óptimo:**

*Criterios de Selección:*

1. **Análisis de Eficiencia:**
   - Identificar valores con mayor eficiencia muestral
   - Considerar balance entre número de locaciones y celdas
   - Evaluar viabilidad operativa del diseño

2. **Procedimiento de Confirmación:**
   - Seleccionar fila deseada en la tabla de percentiles
   - Copiar el número de fila mostrado
   - Ingresar en el campo "Número de fila seleccionada"
   - Hacer clic en "Confirmar Selección"

3. **Validación del Sistema:**
   - Verificación de existencia de la fila seleccionada
   - Extracción de parámetros de la fila
   - Filtrado automático del dataset según umbral seleccionado
   - Generación de estadísticas de resumen

**7.1.6. Visualización de Resultados:**

*Panel de Estadísticas:*
- **Total de locaciones originales:** Conteo inicial
- **Locaciones después del filtro:** Locaciones que cumplen criterio
- **Total de celdas disponibles:** Suma de celdas por locación
- **Promedio de celdas por locación:** Media aritmética
- **Rango de celdas:** Mínimo y máximo por locación

### VII.2. Pestaña 2: Carga de Marcos Muestrales

**7.2.1. Propósito y Funcionalidad:**

La segunda pestaña permite la integración de marcos muestrales geoespaciales, incluyendo coordenadas UTM y datos de profundidad, esenciales para la implementación del diseño bietápico con referencia espacial precisa.

**7.2.2. Sección 2A: Cargar Archivos de Marcos**

*Carga de Marco de Celdas:*

1. **Selección de Archivo:**
   - Hacer clic en "Examinar..." para "Marco de Celdas"
   - Seleccionar archivo Excel con estructura requerida
   - Validación automática de formato

2. **Estructura Requerida:**
   ```
   Columnas Obligatorias:
   - COD_CELDA: Código de celda (coincidente con archivo principal)
   - ESTE: Coordenada X en sistema UTM (numérico)
   - NORTE: Coordenada Y en sistema UTM (numérico)
   - PROF: Profundidad o elevación (numérico)
   
   Variaciones Aceptadas:
   - este, Este, ESTE, x, X, coord_x, COORD_X
   - norte, Norte, NORTE, y, Y, coord_y, COORD_Y
   - prof, Prof, PROF, profundidad, depth, DEPTH
   ```

*Carga de Marco de Grillas:*

1. **Características del Archivo:**
   - Estructura similar al marco de celdas
   - Permite múltiples registros por COD_CELDA
   - Define puntos específicos de muestreo dentro de cada celda

2. **Validación de Integridad:**
   - Verificación de correspondencia entre marcos
   - Control de consistencia en coordenadas
   - Detección de valores atípicos en rangos geográficos

**7.2.3. Ejecución de Carga Integrada:**

*Procedimiento:*

1. **Validación Previa:**
   - Verificar que ambos archivos estén seleccionados
   - Confirmar compatibilidad de formatos

2. **Carga Simultánea:**
   - Hacer clic en "Cargar Marcos"
   - Ejecución de `estandarizar_columnas()` para ambos archivos
   - Integración con dataset principal mediante COD_CELDA

3. **Controles de Calidad:**
   - Verificación de integridad referencial
   - Detección de celdas sin coordenadas
   - Identificación de coordenadas sin celdas asociadas

**7.2.4. Visualización y Análisis:**

*Pestaña "Vista Previa":*
- Tabla interactiva con primeras 100 filas de cada marco
- Funcionalidades de ordenamiento y filtrado
- Verificación visual de calidad de datos

*Pestaña "Estadísticas":*
- Resumen de locaciones por número de celdas
- Distribución espacial de coordenadas
- Rangos de profundidad por locación

*Pestaña "Control de Calidad":*
- Listado de celdas sin coordenadas
- Identificación de coordenadas huérfanas
- Sugerencias de corrección de inconsistencias

**7.2.5. Diagnóstico de Problemas:**

*Errores Comunes:*

1. **"Celdas sin coordenadas":**
   - Causa: COD_CELDA en archivo principal sin correspondencia en marcos
   - Solución: Verificar consistencia de códigos entre archivos

2. **"Coordenadas sin celdas":**
   - Causa: COD_CELDA en marcos sin correspondencia en archivo principal
   - Acción: Revisar filtros aplicados en Pestaña 1

3. **"Rangos de coordenadas inválidos":**
   - Causa: Coordenadas fuera de rangos UTM válidos
   - Verificación: Confirmar sistema de referencia utilizado

### VII.3. Pestaña 3: Cálculo del Tamaño Muestral

**7.3.1. Propósito y Funcionalidad:**

La tercera pestaña implementa algoritmos estadísticos especializados para determinar el tamaño muestral óptimo basado en parámetros de precisión, confianza y variabilidad poblacional, utilizando la librería TeachingSampling para cálculos rigurosos.

**7.3.2. Parámetros de Entrada:**

*Configuración de Parámetros Estadísticos:*

1. **Nivel de Confianza:**
   - Valores típicos: 90%, 95%, 99%
   - Recomendado: 95% para estudios ambientales estándar
   - Impacto: Mayor confianza requiere mayor tamaño muestral

2. **Error Máximo Admisible:**
   - Expresado como porcentaje de la media poblacional
   - Rango típico: 5% - 20%
   - Consideración: Menor error requiere mayor precisión muestral

3. **Coeficiente de Variación:**
   - Estimación de variabilidad poblacional
   - Fuentes: Estudios piloto, literatura especializada
   - Valores conservadores recomendados en ausencia de datos

**7.3.3. Algoritmos de Cálculo:**

*Metodología Estadística Implementada:*

La aplicación utiliza la siguiente fórmula para poblaciones finitas con ajustes por diseño:

```r
# Fórmula implementada en la aplicación
n = ((N * Z^2 * σ^2) / (e^2 * (N-1) + Z^2 * σ^2)) * (1 / (1-TNR)) * DEFF

# Donde:
# N = Tamaño de la población (total de rejillas en marco_grillas)
# Z = Valor crítico de distribución normal estándar
# σ = Desviación estándar de la variable TPH
# e = Margen de error absoluto (porcentaje de la media * media)
# TNR = Tasa de no respuesta (como proporción)
# DEFF = Efecto de diseño (valor predeterminado: 1.5)

# Cálculos auxiliares:
# Z = qnorm(1 - (1 - nivel_confianza) / 2)
# e = (margen_error_porcentaje / 100) * media_TPH
# σ = sd(base_tph_umbral_fil$TPH, na.rm = TRUE)
```

*Consideraciones Específicas de la Implementación:*
- Utiliza datos de TPH (Total Petroleum Hydrocarbons) como variable de referencia
- Incorpora factor DEFF fijo de 1.5 para diseño bietápico
- Ajusta por tasa de no respuesta definida por el usuario
- Calcula sobre el total de rejillas disponibles en el marco muestral

**7.3.4. Interpretación de Resultados:**

*Outputs del Sistema:*

1. **Tamaño Muestral Final (n):**
   - Resultado directo de la fórmula implementada
   - Incluye todos los ajustes (población finita, TNR, DEFF)
   - Expresado en número de rejillas a muestrear

2. **Parámetros Utilizados:**
   - Nivel de confianza y valor Z correspondiente
   - Media y desviación estándar de TPH
   - Error absoluto calculado
   - Tamaño poblacional (N rejillas)
   - Efecto de diseño aplicado

3. **Información Complementaria:**
   - Total de rejillas en el marco muestral
   - Rejillas que representan la TNR
   - Fórmula matemática con notación LaTeX
   - Resumen detallado de todos los parámetros

### VII.4. Pestaña 4: Ejecución del Muestreo Bietápico

**7.4.1. Propósito y Funcionalidad:**

La cuarta pestaña constituye el núcleo operativo del sistema, donde se ejecuta el algoritmo de muestreo bietápico, se generan códigos únicos de identificación, se calculan distancias a pozos de referencia y se preparan los productos finales para trabajo de campo.

**7.4.2. Sección 4A: Ejecutar Muestreo**

*Parámetros de Configuración:*

1. **Semilla Aleatoria (Seed):**
   - Valor numérico para reproducibilidad
   - Rango recomendado: 1-9999
   - Importancia: Garantiza resultados idénticos en ejecuciones repetidas

2. **Ejecución del Algoritmo:**
   - Hacer clic en "Ejecutar Muestreo Bietápico"
   - El sistema implementará la siguiente secuencia:

*Algoritmo de Muestreo Bietápico Implementado:*

```
Etapa 1: Determinación del Número de Celdas (l)
│
├── Cálculo: l = floor(mean(c(l_min, l_max)))
├── l_min = número de locaciones únicas
├── l_max = floor(n / minimo_rejillas) donde minimo_rejillas = 3
└── l = promedio entre l_min y l_max

Etapa 2: Asignación de Celdas por Locación
│
├── Asignación base: 1 celda por locación
├── Cálculo de proporción: total_celdas / sum(total_celdas)
├── Distribución proporcional de celdas restantes
└── Ajuste de residuos por método de mayores restos

Etapa 3: Selección Aleatoria de Celdas (Primera Etapa)
│
├── Uso de función S.piPS() de TeachingSampling
├── Muestreo aleatorio simple (SRS) con tamaños iguales
└── Selección independiente por locación

Etapa 4: Asignación de Rejillas por Celda
│
├── Asignación base: 3 rejillas por celda
├── Distribución proporcional de rejillas restantes
├── Control de excesos: muestra_rejillas ≤ total_rejillas
└── Redistribución de excesos según capacidad disponible

Etapa 5: Selección Aleatoria de Rejillas (Segunda Etapa)
│
├── Uso de función S.piPS() para cada celda
├── Muestreo aleatorio simple (nota: PPS no implementado)
└── Selección final de rejillas por celda
```

**7.4.3. Sección 4B: Generar Códigos de Muestreo**

*Funcionalidad de Generación:*

1. **Estructura del Código:**
   ```
   Formato: [PREFIJO]-[LOCACION]-[SECUENCIAL]
   Ejemplo: SM-LOC001-001, SM-LOC001-002
   
   Componentes:
   - PREFIJO: Identificador del proyecto (configurable)
   - LOCACION: Código de locación de origen
   - SECUENCIAL: Número correlativo por locación
   ```

2. **Algoritmo de Generación:**
   - Utilización de librería UUID para generar identificadores únicos
   - Integración automática con coordenadas UTM del marco de grillas
   - Preservación de información de profundidad (PROF)
   - Aplicación de algoritmo de vecino más cercano para optimizar orden
   - Generación de variable ORDEN para secuencia de campo

**7.4.4. Sección 4C: Generar Distancias a Pozos**

*Carga de Pozos de Referencia:*

1. **Estructura del Archivo:**
   ```
   Columnas Requeridas:
   - LOCACION: Identificador de locación
   - ESTE: Coordenada X del pozo (UTM)
   - NORTE: Coordenada Y del pozo (UTM)
   - ALTITUD: Elevación del pozo (metros)
   ```

2. **Algoritmos de Cálculo:**

*Cálculo de Distancia Euclidiana:*
```r
distancia = sqrt((x2-x1)^2 + (y2-y1)^2)
```

*Determinación de Orientación Cardinal:*
```r
# Sistema de 8 direcciones principales
Orientaciones: Norte, Noreste, Este, Sureste, 
               Sur, Suroeste, Oeste, Noroeste

# Basado en ángulos de 45° cada dirección
```

3. **Generación de Texto Descriptivo:**
   - Formato: "Punto de muestreo de suelo ubicado aproximadamente a [X] metros con dirección al [orientación] de la locación [código]"
   - Integración automática en tabla final

**7.4.5. Sección 4D: Exportar Resultados**

*Formatos de Exportación Disponibles:*

1. **Archivo Excel (.xlsx):**
   - Tabla completa con todos los campos calculados
   - Formato optimizado para trabajo de campo
   - Incluye metadatos de procesamiento

2. **Shapefile (.shp):**
   - Archivo vectorial geoespacial
   - Compatible con software GIS estándar
   - Incluye sistema de coordenadas UTM
   - Atributos completos en tabla asociada

*Contenido de Exportación:*
- Códigos únicos de muestreo
- Coordenadas UTM precisas
- Información de profundidad
- Distancias y orientaciones a pozos
- Metadatos de procesamiento

### VII.5. Pestaña de Errores: Monitoreo y Diagnóstico

**7.5.1. Propósito del Sistema de Errores:**

La pestaña de errores implementa un sistema integral de monitoreo, registro y diagnóstico que captura automáticamente todas las excepciones y errores operativos, proporcionando trazabilidad completa para soporte técnico y mejora continua.

**7.5.2. Funcionalidades del Sistema:**

*Captura Automática:*

1. **Puntos de Captura:**
   - Carga de archivos Excel
   - Procesamiento de marcos muestrales
   - Ejecución de muestreo bietápico
   - Generación de códigos
   - Exportación de resultados

2. **Información Registrada:**
   ```
   Estructura del Registro:
   - Timestamp: Fecha y hora exacta del error
   - Contexto: Sección donde ocurrió el error
   - Mensaje: Descripción técnica del error
   - Stack Trace: Información de depuración (si disponible)
   ```

**7.5.3. Interfaz de Usuario:**

*Visualización de Errores:*
- Lista cronológica (más recientes primero)
- Formato legible con contexto claro
- Diferenciación por tipo de error
- Límite de 50 errores para optimización de memoria

*Controles Disponibles:*

1. **Limpiar Registro:**
   - Botón para eliminar todos los errores registrados
   - Útil para iniciar sesión limpia

2. **Descargar Log:**
   - Exportación completa en formato .txt
   - Incluye timestamp y contexto detallado
   - Formato compatible con herramientas de análisis

**7.5.4. Interpretación de Errores Comunes:**

*Categorías de Errores:*

1. **Errores de Formato de Datos:**
   - "Columna no encontrada": Verificar nombres de columnas
   - "Tipo de dato incorrecto": Revisar formato numérico
   - "Archivo corrupto": Validar integridad del archivo Excel

2. **Errores de Procesamiento:**
   - "Memoria insuficiente": Dataset demasiado grande
   - "Timeout de cálculo": Operación muy compleja
   - "División por cero": Datos con valores nulos críticos

3. **Errores de Integridad:**
   - "Referencia no encontrada": Inconsistencia entre archivos
   - "Coordenadas inválidas": Valores fuera de rango UTM
   - "Duplicados detectados": Códigos no únicos

**7.5.5. Estrategias de Resolución:**

*Protocolo de Diagnóstico:*

1. **Identificación del Contexto:**
   - Revisar la sección donde ocurrió el error
   - Verificar la secuencia de operaciones realizadas

2. **Análisis del Mensaje:**
   - Interpretar el mensaje técnico del error
   - Identificar la causa raíz probable

3. **Acción Correctiva:**
   - Aplicar solución específica según tipo de error
   - Verificar resolución mediante nueva ejecución

4. **Prevención:**
   - Documentar la solución aplicada
   - Implementar controles preventivos

Este sistema integral de monitoreo garantiza la trazabilidad completa de todos los procesos y facilita el mantenimiento proactivo de la aplicación.

## VIII. RESOLUCIÓN DE PROBLEMAS

Esta sección proporciona un compendio sistemático de diagnósticos y soluciones para los problemas más frecuentes en la operación de la aplicación de Diseño Bietápico, organizado por categorías funcionales y niveles de complejidad técnica.

### VIII.1. Errores Comunes de Carga de Datos

**8.1.1. Problemas de Formato de Archivo**

*Error: "Archivo no compatible" o "Error al leer archivo Excel"*

**Causas Probables:**
- Archivo en formato .xls muy antiguo (Excel 97-2003)
- Archivo dañado o corrupto
- Archivo protegido con contraseña
- Archivo abierto en otra aplicación

**Soluciones:**
```
1. Verificar formato de archivo:
   - Convertir a .xlsx usando Excel moderno
   - Guardar como "Libro de Excel (.xlsx)"
   - Evitar formatos .csv o .txt

2. Validar integridad:
   - Abrir archivo en Excel para verificar que no esté corrupto
   - Eliminar contraseñas de protección
   - Cerrar archivo en todas las aplicaciones

3. Recrear archivo si es necesario:
   - Copiar datos a nuevo archivo Excel
   - Verificar que no hay caracteres especiales en nombres de columnas
```

*Error: "Columnas requeridas no encontradas"*

**Diagnóstico:**
- El sistema de estandarización no reconoció las columnas
- Nombres de columnas con caracteres especiales o espacios extra
- Columnas en idioma diferente al esperado

**Solución Paso a Paso:**
```
1. Verificar nombres exactos de columnas:
   Archivo Principal: LOCACION, AREA, COD_CELDA
   Marco Celdas: COD_CELDA, ESTE, NORTE, PROF
   Marco Grillas: COD_CELDA, ESTE, NORTE, PROF
   Pozos: LOCACION, ESTE, NORTE, ALTITUD

2. Correcciones comunes:
   - Eliminar espacios antes/después de nombres
   - Cambiar "área" por "AREA"
   - Cambiar "locación" por "LOCACION"
   - Verificar que no hay tildes o caracteres especiales

3. Variaciones aceptadas por el sistema:
   ESTE: este, Este, ESTE, x, X, coord_x, COORD_X
   NORTE: norte, Norte, NORTE, y, Y, coord_y, COORD_Y
   PROF: prof, Prof, PROF, profundidad, depth, DEPTH
```

**8.1.2. Problemas de Contenido de Datos**

*Error: "Valores nulos detectados en columnas críticas"*

**Análisis:**
- Celdas vacías en columnas obligatorias
- Valores "#N/A" o "#ERROR" en Excel
- Espacios en blanco interpretados como nulos

**Protocolo de Corrección:**
```
1. Identificar filas problemáticas:
   - Usar filtros en Excel para encontrar celdas vacías
   - Buscar valores "#N/A" o similares

2. Estrategias de corrección:
   - Eliminar filas con datos incompletos
   - Completar datos faltantes desde fuente original
   - Usar valores por defecto cuando sea apropiado

3. Validación final:
   - Verificar que todas las columnas obligatorias tienen datos
   - Confirmar tipos de datos (numéricos para AREA, ESTE, NORTE, PROF)
```

### VIII.2. Problemas de Formato de Archivos

**8.2.1. Inconsistencias entre Archivos**

*Error: "Códigos de celda no coinciden entre archivos"*

**Diagnóstico Avanzado:**
```r
# Script de diagnóstico (ejecutar en R)
# Comparar códigos entre archivos
codigos_principal <- unique(datos_principal$COD_CELDA)
codigos_marco <- unique(marco_celdas$COD_CELDA)

# Encontrar diferencias
faltantes_en_marco <- setdiff(codigos_principal, codigos_marco)
sobrantes_en_marco <- setdiff(codigos_marco, codigos_principal)

print(paste("Faltantes en marco:", length(faltantes_en_marco)))
print(paste("Sobrantes en marco:", length(sobrantes_en_marco)))
```

**Estrategias de Resolución:**
1. **Reconciliación de Códigos:**
   - Verificar que los códigos usen el mismo formato
   - Eliminar espacios extra o caracteres ocultos
   - Estandarizar mayúsculas/minúsculas

2. **Actualización de Archivos:**
   - Añadir códigos faltantes al marco
   - Eliminar códigos sobrantes si no son necesarios
   - Verificar que la fuente de datos sea consistente

**8.2.2. Problemas de Coordenadas**

*Error: "Coordenadas fuera de rango UTM válido"*

**Validación de Rangos:**
```
Rangos típicos UTM para Perú:
Zona 17S: ESTE 600,000 - 900,000, NORTE 8,500,000 - 9,000,000
Zona 18S: ESTE 160,000 - 834,000, NORTE 8,500,000 - 9,000,000
Zona 19S: ESTE 160,000 - 500,000, NORTE 8,500,000 - 9,000,000

Verificaciones:
1. Confirmar zona UTM correcta
2. Verificar que no hay confusión entre ESTE/NORTE
3. Comprobar que las coordenadas no están en grados decimales
```

**Corrección de Coordenadas:**
```
Problemas comunes:
1. Coordenadas en grados decimales (ej: -75.123, -12.456)
   Solución: Convertir a UTM usando software GIS

2. Coordenadas intercambiadas (ESTE en columna NORTE)
   Solución: Intercambiar columnas en Excel

3. Zona UTM incorrecta
   Solución: Reproyectar coordenadas a zona correcta
```

### VIII.3. Errores de Cálculo Estadístico

**8.3.1. Problemas en Análisis de Percentiles**

*Error: "No se pueden calcular percentiles" o "Resultado vacío"*

**Causas Técnicas:**
- Dataset muy pequeño (menos de 10 registros)
- Todos los valores de AREA son idénticos
- Valores de área negativos o cero
- Distribución de datos extremadamente sesgada

**Soluciones Metodológicas:**
```
1. Validación de dataset:
   - Verificar que hay al menos 20 registros
   - Confirmar variabilidad en valores de AREA
   - Eliminar valores atípicos extremos

2. Ajuste de parámetros:
   - Modificar valores de área de rejilla evaluados
   - Usar rangos más amplios o más estrechos
   - Considerar transformación logarítmica si hay gran variabilidad

3. Interpretación alternativa:
   - Usar medidas de tendencia central
   - Aplicar técnicas de suavizado
   - Considerar agrupación por categorías
```

**8.3.2. Errores en Cálculo de Tamaño Muestral**

*Error: "Tamaño muestral excesivamente grande" o "Parámetros inválidos"*

**Diagnóstico de Parámetros:**
```
Verificaciones necesarias:
1. Nivel de confianza: 90%, 95%, o 99% (no otros valores)
2. Error máximo: Entre 5% y 30% (valores extremos causan problemas)
3. Coeficiente de variación: Entre 0.1 y 2.0 (valores típicos)

Fórmula de verificación:
n = (Z^2 * CV^2) / E^2

Ejemplo problemático:
CV = 3.0, E = 0.01 (1%) → n muy grande

Ejemplo correcto:
CV = 0.5, E = 0.10 (10%) → n razonable
```

**Ajustes Recomendados:**
```
Para reducir tamaño muestral:
1. Aumentar error admisible (ej: de 5% a 10%)
2. Reducir nivel de confianza (ej: de 99% a 95%)
3. Usar coeficiente de variación más conservador
4. Aplicar corrección por población finita

Para aumentar precisión:
1. Reducir error admisible con precaución
2. Aumentar nivel de confianza solo si es necesario
3. Usar datos piloto para estimar CV real
```

### VIII.4. Problemas de Exportación

**8.4.1. Errores en Generación de Shapefile**

*Error: "No se puede crear Shapefile" o "Coordenadas inválidas"*

**Diagnóstico Técnico:**
```
Verificaciones del sistema sf:
1. Verificar instalación de librería sf
   install.packages("sf", dependencies = TRUE)

2. Comprobar dependencias del sistema:
   - GDAL (Geospatial Data Abstraction Library)
   - PROJ (Cartographic Projections Library)
   - GEOS (Geometry Engine Open Source)

3. Validar estructura de datos:
   - Coordenadas numéricas válidas
   - Sistema de referencia definido
   - Geometrías válidas
```

**Soluciones por Plataforma:**
```
Windows:
1. Reinstalar paquete sf con dependencias
2. Verificar que R esté actualizado (v4.2.2+)
3. Instalar Rtools si es necesario

Linux:
sudo apt-get install libgdal-dev libproj-dev libgeos-dev
install.packages("sf")

macOS:
brew install gdal proj geos
install.packages("sf")
```

**8.4.2. Problemas de Descarga de Archivos**

*Error: "Descarga fallida" o "Archivo vacío"*

**Causas Comunes:**
- Bloqueador de descargas del navegador
- Permisos insuficientes en directorio de descarga
- Archivo temporal corrupto
- Sesión de aplicación expirada

**Protocolo de Resolución:**
```
1. Verificar configuración del navegador:
   - Permitir descargas desde el sitio
   - Verificar directorio de descarga
   - Desactivar bloqueadores temporalmente

2. Limpiar datos de sesión:
   - Refrescar página de aplicación
   - Limpiar cache del navegador
   - Reiniciar sesión si es necesario

3. Alternativas de exportación:
   - Usar navegador diferente
   - Intentar descarga en horario de menor tráfico
   - Verificar conexión a Internet
```

### VIII.5. Diagnóstico Avanzado

**8.5.1. Herramientas de Monitoreo**

*Monitoreo de Rendimiento:*
```r
# Script de diagnóstico de rendimiento
system.time({
  # Operación problemática aquí
})

# Monitoreo de memoria
memory.size()  # Uso actual
memory.limit() # Límite máximo

# Limpieza de memoria
gc()  # Garbage collection
rm(list = ls())  # Limpiar workspace
```

*Análisis de Logs:*
```bash
# Revisar logs del sistema (Linux/macOS)
tail -f /var/log/shiny-server.log

# Buscar errores específicos
grep -i "error" /var/log/shiny-server.log

# Monitoreo de recursos
top -p $(pgrep -f "R.*shiny")
```

**8.5.2. Optimización de Rendimiento**

*Para Datasets Grandes (>50,000 registros):*
```r
# Optimizaciones recomendadas
options(shiny.maxRequestSize = 100*1024^2)  # 100MB
memory.limit(size = 8000)  # 8GB (Windows)

# Procesamiento por lotes
process_in_batches <- function(data, batch_size = 1000) {
  n_batches <- ceiling(nrow(data) / batch_size)
  results <- list()
  
  for(i in 1:n_batches) {
    start_row <- (i-1) * batch_size + 1
    end_row <- min(i * batch_size, nrow(data))
    batch_data <- data[start_row:end_row, ]
    
    # Procesar lote
    results[[i]] <- process_batch(batch_data)
    
    # Limpieza de memoria
    if(i %% 10 == 0) gc()
  }
  
  return(do.call(rbind, results))
}
```

*Configuración de Servidor:*
```yaml
# docker-compose.yml optimizado
version: '3.8'
services:
  muestreo-bietapico:
    image: muestreo-bietapico:latest
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4.0'
    environment:
      - R_MAX_VSIZE=8Gb
      - SHINY_LOG_LEVEL=WARN
    ulimits:
      memlock:
        soft: -1
        hard: -1
```

**8.5.3. Contacto de Soporte Técnico**

*Información Requerida para Soporte:*
```
Al reportar un problema, incluir:
1. Versión de R y paquetes (sessionInfo())
2. Sistema operativo y versión
3. Descripción exacta del error
4. Pasos para reproducir el problema
5. Archivos de ejemplo (si es posible)
6. Logs de error de la pestaña de Errores
7. Capturas de pantalla relevantes
```

*Escalamiento de Problemas:*
```
Nivel 1 - Usuario Final:
- Consultar este manual
- Verificar requisitos básicos
- Intentar soluciones estándar

Nivel 2 - Administrador Local:
- Diagnóstico avanzado
- Configuración de sistema
- Optimización de rendimiento

Nivel 3 - Soporte Técnico:
- Problemas de código
- Bugs no documentados
- Mejoras funcionales
```

Esta sección de resolución de problemas proporciona un marco sistemático para el diagnóstico y corrección de los problemas más frecuentes, facilitando la operación autónoma y eficiente de la aplicación.

## IX. GLOSARIO DE TÉRMINOS

Este glosario proporciona definiciones precisas y científicamente fundamentadas de los términos técnicos, estadísticos y geoespaciales utilizados en la aplicación de Diseño Bietápico, organizados por categorías temáticas para facilitar la consulta y comprensión.

### IX.1. Términos Estadísticos

**Coeficiente de Variación (CV):**
Medida estadística de dispersión relativa que expresa la desviación estándar como porcentaje de la media aritmética. Fórmula: CV = (σ/μ) × 100, donde σ es la desviación estándar y μ es la media poblacional. Valores típicos en estudios ambientales oscilan entre 0.2 y 1.5.

**Diseño de Efectos (DEFF):**
Ratio que compara la varianza de un estimador bajo un diseño muestral complejo con la varianza del mismo estimador bajo muestreo aleatorio simple. DEFF > 1 indica pérdida de eficiencia debido a la complejidad del diseño.

**Error Máximo Admisible:**
Margen de error tolerable en la estimación de parámetros poblacionales, expresado como porcentaje de la media verdadera. Determina la precisión requerida del estudio y afecta directamente el tamaño muestral necesario.

**Estimador Insesgado:**
Estimador estadístico cuyo valor esperado es igual al parámetro poblacional que se desea estimar. Propiedad fundamental para garantizar la validez de las inferencias estadísticas.

**Intervalo de Confianza:**
Rango de valores que, con una probabilidad especificada (nivel de confianza), contiene el verdadero valor del parámetro poblacional. Niveles comunes: 90%, 95%, y 99%.

**Muestreo Aleatorio Estratificado:**
Técnica de muestreo probabilístico donde la población se divide en subgrupos homogéneos (estratos) y se selecciona una muestra aleatoria de cada estrato. Mejora la precisión al reducir la varianza entre unidades.

**Muestreo Bietápico (Two-Stage Sampling):**
Diseño muestral complejo que involucra dos etapas de selección: primero se seleccionan unidades primarias de muestreo (UPM), luego unidades secundarias (USM) dentro de cada UPM seleccionada. Eficiente para poblaciones geográficamente dispersas.

**Percentil:**
Valor que divide una distribución ordenada en 100 partes iguales. El percentil P indica que P% de las observaciones son menores o iguales a ese valor. Utilizado para establecer umbrales y criterios de selección.

**Población Finita:**
Conjunto de unidades de análisis con tamaño conocido y limitado. Requiere factor de corrección en el cálculo del tamaño muestral cuando la muestra representa una fracción significativa (>5%) de la población.

**Tamaño Muestral Óptimo:**
Número de unidades de muestreo que minimiza el costo total del estudio sujeto a restricciones de precisión, o alternativamente, maximiza la precisión sujeto a restricciones presupuestarias.

### IX.2. Términos Geoespaciales

**Coordenadas UTM (Universal Transverse Mercator):**
Sistema de coordenadas cartesianas basado en la proyección Mercator Transversa, que divide la Tierra en 60 zonas de 6° de longitud. Proporciona coordenadas planas (Este, Norte) en metros, facilitando cálculos de distancia y área.

**Datum Geodésico:**
Sistema de referencia que define la forma y tamaño de la Tierra para propósitos cartográficos. Ejemplos: WGS84 (mundial), SIRGAS2000 (Sudamérica), PSAD56 (Perú histórico).

**Distancia Euclidiana:**
Distancia en línea recta entre dos puntos en un plano cartesiano, calculada mediante el teorema de Pitágoras: d = √[(x₂-x₁)² + (y₂-y₁)²]. Apropiada para coordenadas proyectadas como UTM.

**EPSG (European Petroleum Survey Group):**
Código numérico que identifica de manera única sistemas de coordenadas, proyecciones y transformaciones geodésicas. Ejemplo: EPSG:32718 corresponde a UTM Zona 18S WGS84.

**Orientación Cardinal:**
Dirección geográfica expresada en términos de puntos cardinales. Sistema de 8 direcciones: Norte (N), Noreste (NE), Este (E), Sureste (SE), Sur (S), Suroeste (SO), Oeste (O), Noroeste (NO).

**Proyección Cartográfica:**
Transformación matemática que convierte coordenadas geográficas (latitud, longitud) de la superficie curva de la Tierra a coordenadas planas en un mapa. Introduce distorsiones controladas en área, distancia o forma.

**Shapefile:**
Formato vectorial de archivo geoespacial desarrollado por ESRI, compuesto por mínimo tres archivos: .shp (geometrías), .shx (índice), .dbf (atributos). Estándar de facto en sistemas de información geográfica.

**Sistema de Referencia Espacial (SRS):**
Marco de coordenadas que define cómo se relacionan las coordenadas numéricas con ubicaciones reales en la superficie terrestre. Incluye datum, proyección y parámetros de transformación.

**Zona UTM:**
División geográfica de 6° de longitud en el sistema UTM. Perú abarca las zonas 17S, 18S y 19S. Cada zona tiene su propio sistema de coordenadas con origen y parámetros específicos.

### IX.3. Términos de Muestreo

**Celda de Muestreo:**
Unidad espacial discreta que define un área geográfica específica donde se pueden ubicar puntos de muestreo. Corresponde a la unidad primaria de muestreo en el contexto de la aplicación.

**Código de Identificación Único:**
Identificador alfanumérico que distingue inequívocamente cada punto de muestreo. Estructura típica: [PREFIJO]-[LOCACION]-[SECUENCIAL], garantizando trazabilidad y organización.

**Grilla de Muestreo:**
Conjunto de puntos específicos dentro de una celda donde se pueden realizar mediciones o tomar muestras. Representa las unidades secundarias de muestreo en el diseño bietápico.

**Locación:**
Área geográfica mayor que agrupa múltiples celdas de muestreo, generalmente definida por criterios administrativos, geológicos o operativos. Unidad de estratificación en el diseño muestral.

**Marco Muestral:**
Lista completa y actualizada de todas las unidades de la población objetivo, con información auxiliar necesaria para la selección de la muestra. Incluye identificadores, coordenadas y variables de estratificación.

**Muestra Representativa:**
Subconjunto de la población seleccionado mediante técnicas probabilísticas que permite hacer inferencias válidas sobre las características poblacionales con precisión conocida.

**Punto de Muestreo:**
Ubicación geográfica específica, definida por coordenadas precisas, donde se realiza la recolección de muestras o mediciones. Unidad final de observación en el diseño muestral.

**Rejilla:**
Patrón geométrico regular (cuadrado, rectangular, hexagonal) que organiza espacialmente los puntos de muestreo dentro de una celda. El tamaño de rejilla determina la densidad de muestreo.

**Semilla Aleatoria (Random Seed):**
Valor numérico inicial que controla la secuencia de números pseudoaleatorios generados por algoritmos computacionales. Garantiza reproducibilidad exacta de resultados en ejecuciones repetidas.

**Unidad Primaria de Muestreo (UPM):**
Unidad seleccionada en la primera etapa del muestreo bietápico. En la aplicación, corresponde a las locaciones o celdas seleccionadas inicialmente.

**Unidad Secundaria de Muestreo (USM):**
Unidad seleccionada en la segunda etapa del muestreo bietápico, dentro de las UPM previamente seleccionadas. Corresponde a los puntos específicos de grilla donde se realizará el muestreo.

### IX.4. Términos Técnicos de la Aplicación

**Algoritmo DBSCAN:**
Density-Based Spatial Clustering of Applications with Noise. Algoritmo de agrupamiento que identifica clusters de puntos con alta densidad, separados por regiones de baja densidad. Útil para detectar patrones espaciales.

**Algoritmo de Vecino Más Cercano:**
Técnica de optimización que ordena puntos de muestreo para minimizar la distancia total de recorrido. Reduce costos operativos de campo al optimizar rutas de desplazamiento.

**API (Application Programming Interface):**
Conjunto de definiciones y protocolos que permiten la comunicación entre diferentes componentes de software. En la aplicación, facilita la integración con librerías especializadas.

**Bootstrap:**
Framework CSS que proporciona componentes de interfaz de usuario responsivos y estéticamente consistentes. Utilizado en Shiny para crear interfaces web profesionales.

**Containerización:**
Tecnología que empaqueta aplicaciones y sus dependencias en contenedores portables y aislados. Docker es la plataforma de containerización utilizada para despliegue de la aplicación.

**CSV (Comma-Separated Values):**
Formato de archivo de texto plano que almacena datos tabulares usando comas como separadores de campo. Formato de intercambio común entre aplicaciones.

**DataFrame:**
Estructura de datos bidimensional en R que almacena datos en filas y columnas, similar a una tabla de base de datos o hoja de cálculo. Estructura fundamental para análisis estadístico.

**Docker:**
Plataforma de containerización que permite empaquetar aplicaciones con todas sus dependencias en contenedores ligeros y portables. Facilita despliegue consistente en diferentes entornos.

**Estandarización de Columnas:**
Proceso automático que normaliza nombres de columnas en archivos de entrada, convirtiendo variaciones (mayúsculas, minúsculas, sinónimos) a nomenclatura estándar predefinida.

**Framework Shiny:**
Paquete de R que permite crear aplicaciones web interactivas directamente desde R, sin requerir conocimientos de HTML, CSS o JavaScript. Combina análisis estadístico con interfaces web modernas.

**GDAL (Geospatial Data Abstraction Library):**
Biblioteca de software libre para leer y escribir formatos de datos geoespaciales raster y vectoriales. Dependencia crítica para operaciones geoespaciales en R.

**Git:**
Sistema de control de versiones distribuido que rastrea cambios en archivos y coordina trabajo entre múltiples desarrolladores. Utilizado para mantenimiento y actualización del código fuente.

**JSON (JavaScript Object Notation):**
Formato ligero de intercambio de datos basado en texto, fácil de leer y escribir para humanos y máquinas. Utilizado para configuración y comunicación entre componentes.

**Librería sf:**
Paquete de R que implementa estándares Simple Features para datos vectoriales geoespaciales. Proporciona funcionalidades avanzadas para manipulación, análisis y visualización de datos espaciales.

**Logging:**
Práctica de registrar eventos, errores y actividades del sistema en archivos de texto estructurados. Facilita diagnóstico, monitoreo y mantenimiento de aplicaciones.

**Metadatos:**
Datos que describen otros datos, proporcionando información sobre contenido, calidad, condición y características de un dataset. Incluyen fecha de creación, fuente, precisión y métodos utilizados.

**MVC (Model-View-Controller):**
Patrón arquitectónico que separa la lógica de aplicación en tres componentes interconectados: Modelo (datos), Vista (interfaz) y Controlador (lógica de negocio).

**Programación Reactiva:**
Paradigma de programación orientado a flujos de datos y propagación de cambios. En Shiny, permite que la interfaz se actualice automáticamente cuando cambian los datos subyacentes.

**R:**
Lenguaje de programación y entorno de software libre especializado en computación estadística y gráficos. Ampliamente utilizado en ciencias de datos, estadística aplicada e investigación científica.

**Reproducibilidad:**
Principio científico que requiere que los resultados de un análisis puedan ser replicados exactamente por otros investigadores usando los mismos datos y métodos. Garantizada mediante control de semillas aleatorias.

**RStudio:**
Entorno de desarrollo integrado (IDE) para R que proporciona interfaz gráfica, editor de código, consola, herramientas de depuración y gestión de proyectos.

**TeachingSampling:**
Paquete de R especializado en diseños de muestreo complejos, que implementa algoritmos para cálculo de tamaños muestrales, selección de muestras y estimación de parámetros bajo diferentes diseños.

**Trazabilidad:**
Capacidad de seguir y documentar el historial, aplicación o localización de datos, procesos y resultados a través de todas las etapas del análisis. Fundamental para validación científica y auditoría.

**UUID (Universally Unique Identifier):**
Identificador de 128 bits que garantiza unicidad global sin requerir autoridad central de asignación. Utilizado para generar códigos únicos de muestreo con probabilidad despreciable de duplicación.

**Variable Reactiva:**
En Shiny, expresión que se recalcula automáticamente cuando cambian sus dependencias. Permite crear interfaces dinámicas que responden inmediatamente a acciones del usuario.

**Workflow:**
Secuencia estructurada de pasos o procesos interconectados que transforman entradas en salidas deseadas. En la aplicación, define el flujo desde carga de datos hasta exportación de resultados.

Este glosario proporciona la base conceptual necesaria para comprender completamente los aspectos técnicos, metodológicos y operativos de la aplicación de Diseño Bietápico, facilitando su uso eficiente y la interpretación correcta de resultados.
