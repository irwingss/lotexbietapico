library(readxl)

# Leer muestra final
df <- read_excel("excel_rar/0016-2025/0016-2025_muestra_final.xlsx")

cat("Columnas del archivo:\n")
print(names(df))

cat("\n\nPrimeras 10 filas de columnas que contengan 'GRILL':\n")
grilla_cols <- names(df)[grepl("GRILL", toupper(names(df)))]
if(length(grilla_cols) > 0) {
  print(head(df[, grilla_cols], 10))
} else {
  cat("No se encontraron columnas con 'GRILL'\n")
}

cat("\n\nPrimeras 10 filas de todas las columnas:\n")
print(head(df, 10))
