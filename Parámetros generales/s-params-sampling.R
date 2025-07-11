# ESTE SCRIPT PERMITE CALCULAR LOS PARÁMETROS DE LA FÓRMULA DEL N MUESTRAL PARA LA CORRIDA DE CÓDIGO ESTADÍSTICO: PASAR AQUÍ LOS DEL N MUESTRAL

# --------------------------------------------------------- -
# Extraer Locación
library(tidyverse)
library(stringr)
library(lme4)

source("scripts/f-corregir_nombres_loc.R")

tmp_base_tph <- openxlsx::read.xlsx("Parámetros generales/REPORTE_RESULTADOS_LABORATORIOv4.xlsx")

tmp_base_tph$locacion <- corregir_nombres_loc(tmp_base_tph$PUNTO_MUESTREO)
# 
tmp_base_tph %>% openxlsx::write.xlsx("Parámetros generales/TPH_prelim_250204_con_locaciones.xlsx")

# --------------------------------------------------------- -
# Data de TPH para cálculo del N muestral
base_tph <- openxlsx::read.xlsx("Parámetros generales/TPH_prelim_250204_con_locaciones.xlsx")

base_tph$TPH <- ifelse(!is.na(base_tph$TPH_count), 
                       base_tph$TPH_count,
                       base_tph$TPH_low)

# --------------------------------------------------------- -
# Cálculo de DEFF basado en ICC (Correlación intraclase)
umbral <- base_tph %>% 
  filter(TPH < 10000) %>% 
  pull(TPH) %>% 
  quantile(probs = 1/3) # (cuantil 33.333% y no 50% de modo arbitrario para que sea más estricto)

# CONDICIÓN 1 UMBRAL:
# Mantener solo filas con TPH mayor al umbral
base_tph_umbral <-  base_tph %>% 
  filter(TPH > umbral)

# CONDICIÓN 2 LOCACIONES:
# Identificar locaciones con 3 a más celdas
loc3 <- base_tph_umbral %>% 
  count(locacion) %>% arrange((n)) %>% 
  mutate(filtrar = ifelse(n < 3, 1, 0)) %>% 
  filter(filtrar == 0) %>% 
  pull(locacion) %>% 
  unique()

# Mantener solo locaciones identificadas
base_tph_umbral_fil <- base_tph_umbral %>% 
  filter(locacion %in% loc3) 

# --------------------------------------------------------- -
# Correlación intraclase por LOCACION
# Ajustamos un modelo lineal de efectos mixto para estimar la correlación intraclase (rho)

fit_lmer <- lmer(log(TPH) ~ 1 + (1 | locacion), data = base_tph_umbral_fil)

# Vector de tamaños de cada yacimiento
n_i <- table(base_tph_umbral_fil$locacion)

# Tamaño promedio real
n_bar <- mean(n_i)

# Varianza de los tamaños
var_n  <- var(n_i)

ICC <- performance::icc(fit_lmer)$ICC_adjusted 
# ICC <- sigma2_B / (sigma2_B + sigma2_W)
DEFF_extended <- 1 + ICC * (n_bar + var_n / n_bar - 1)
DEFF_extended
