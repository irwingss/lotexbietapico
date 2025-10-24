# Diagnóstico: Códigos de Grillas Malformados

## Problema Reportado

Los códigos de grillas en la sección "📋 Códigos de Elementos Contaminados" aparecen como:
- `BAT-LA07_SUE-BAT-LA07-927_025`

Cuando deberían ser:
- `SUE-BAT-LA07-927`

## Causa Raíz

**El shapefile de grillas que se carga en la Fase 5C tiene códigos malformados en la columna seleccionada.**

## Flujo del Código

### 1. Carga de Datos (Fase 5A - Caso 2)
```
Archivo: muestra_final.xlsx
Columna GRILLA: "SUE-BAT-LA07-927" ✅ CORRECTO
```

### 2. Carga de Shapefile (Fase 5C)
```
Archivo: shapefile_grillas.zip
Usuario selecciona columna: [¿Cuál?]
Valores en esa columna: "BAT-LA07_SUE-BAT-LA07-927_025" ❌ MALFORMADO
```

### 3. Generación de Vértices
```r
# En scripts/f-analisis_resultados_lab.R líneas 638-682
generar_vertices_grillas <- function(shp_marco_grillas, muestra_final_e, ...) {
  # 1. Extrae vértices del shapefile usando COD_GRILLA
  vertices_grillas <- get_vertices(sf_obj = shp_marco_grillas, 
                                   code_col = "COD_GRILLA", ...)
  
  # 2. Extrae códigos de GRILLA desde muestra_final_e
  lk_punto_grilla <- muestra_final_e %>% 
    filter(grilla %in% superan_grilla) %>%
    transmute(COD_GRILLA = to_key(grilla), ...)
  
  # 3. Extrae atributos del shapefile
  attrs_grillas <- shp_marco_grillas %>%
    transmute(COD_GRILLA = to_key(COD_GRILLA), ...)  # ← AQUÍ VIENE EL CÓDIGO MALO
  
  # 4. JOIN - El código del shapefile prevalece
  vertices_grillas_enriq <- vertices_grillas %>%
    left_join(attrs_grillas, by = "COD_GRILLA") %>%  # ← USO CÓDIGOS DEL SHAPEFILE
    inner_join(lk_punto_grilla, by = "COD_GRILLA")  # ← MATCH CON MUESTRA
}
```

## ¿Por qué el join funciona si los códigos son diferentes?

El `inner_join` en la línea 674 solo incluirá grillas que tengan match en **ambos** datasets. 
Si estás viendo resultados, significa que:

1. **O** el shapefile tiene AMBAS columnas (una correcta y una malformada) y seleccionaste la malformada
2. **O** hay códigos duplicados/parciales que hacen match por trimws()

## Verificación del Problema

### Paso 1: Revisar el shapefile de grillas

Abre el shapefile en QGIS o ArcGIS y verifica:

```
1. ¿Qué columnas tiene?
2. ¿Cuál columna estás seleccionando como "Código de GRILLA"?
3. ¿Qué valores tiene esa columna?
```

### Paso 2: Verificar la selección en la app

En la Fase 5C, después de cargar el shapefile de grillas:

1. Mira el selector "Columna de CÓDIGO DE GRILLA"
2. ¿Qué columna está seleccionada?
3. ¿Hay otras columnas disponibles con códigos correctos?

## Solución Recomendada

### Opción 1: Seleccionar la columna correcta

Si el shapefile tiene múltiples columnas, selecciona la que tenga los códigos simples:
- ✅ GRILLA, COD_GRILLA, CODIGO
- ❌ GRILLA_COMPLETA, COD_CONCATENADO, etc.

### Opción 2: Corregir el shapefile

Si el shapefile solo tiene la columna malformada, necesitas:

1. Abrir el shapefile en QGIS/ArcGIS
2. Crear una nueva columna con el código correcto extraído
3. O usar un shapefile diferente/original

### Opción 3: Extraer código correcto (si el patrón es consistente)

Si TODOS los códigos tienen el formato `PREFIJO_CODIGO_SUFIJO`, podemos agregar código para extraer solo la parte central.

## Código para Depurar

Agrega esto en `scripts/server-fase5-handlers.R` después de la línea 550:

```r
# DEBUG: Verificar códigos de grilla
cat("\n==================== DEBUG CÓDIGOS DE GRILLA ====================\n")
cat("Primeros 10 códigos en shapefile (COD_GRILLA):\n")
print(head(unique(shp_grillas$COD_GRILLA), 10))
cat("\nPrimeros 10 códigos en muestra (grilla):\n")
print(head(unique(datos_prep$grilla), 10))
cat("\nCódigos que superan umbral:\n")
print(superan_grilla)
cat("==================================================================\n\n")
```

Esto imprimirá en la consola R los códigos reales antes del procesamiento.

## Archivos Involucrados

- `app_01_muestreo_bietapico.R` líneas 5738-5790: Carga de shapefile de grillas
- `scripts/server-fase5-handlers.R` líneas 536-574: Procesamiento de grillas
- `scripts/f-analisis_resultados_lab.R` líneas 638-682: Generación de vértices

## Conclusión

**El código de la aplicación NO está construyendo códigos malformados.**
**El shapefile de grillas que cargas YA TIENE esos códigos malformados.**

Verifica:
1. ¿De dónde obtuviste el shapefile de grillas?
2. ¿Lo generaste tú? ¿Con qué proceso?
3. ¿Tiene múltiples columnas? ¿Cuál estás seleccionando?
