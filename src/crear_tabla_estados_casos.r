#!/usr/bin/env Rscript
library(tidyverse)

crear_tabla_estados_casos <- function(dir){
  fechas_dirs <- list.dirs(dir, recursive = FALSE, full.names = TRUE)
  
  # Calcular casos acumulados
  Dat <- fechas_dirs %>%
    map_dfr(function(fecha_dir){
      # fecha_dir <- "../datos/ssa_dge/2020-04-06/"
      archivo_tabla <- file.path(fecha_dir, "tabla_casos_confirmados.csv")
      if(file.exists(archivo_tabla)){
        Tab <- read_csv(archivo_tabla,
                        col_types = cols(estado = col_character(),
                                         sexo = col_character(),
                                         edad = col_number(),
                                         fecha_sintomas = col_date(format = "%Y-%m-%d"),
                                         procedencia = col_character(),
                                         fecha_llegada = col_date(format = "%Y-%m-%d")))
        stop_for_problems(Tab)
        
        fecha <- basename(fecha_dir) %>% as.Date()
        acum_estado <- table(Tab$estado)
        res <- tibble(estado = names(acum_estado),
                      casos_acumulados = as.numeric(acum_estado),
                      fecha = fecha)
        
        return(res)
      }
    })
  
  # Calcular casos nuevos
  Dat <- Dat %>%
    split(.$estado) %>%
    map_dfr(function(d){
      d %>%
        arrange(fecha) %>%
        mutate(casos_nuevos = casos_acumulados - lag(casos_acumulados, 1, default = 0))
    })
  
  Dat
}

args <- list(dge_dir = "ssa_dge/",
             csv_salida = "ssa_dge/serie_tiempo_estados_casos.csv")

# Crear tabla estados
Dat <- crear_tabla_estados_casos(dir = args$dge_dir)
if(any(is.na(Dat$estado)))
  stop("ERROR: Hay un problema con los nombres de los estados.")
if(length(unique(Dat$estado)) != 32)
  stop("ERROR: Hay un problema con los nombres de los estados.")
write_csv(Dat, args$csv_salida)