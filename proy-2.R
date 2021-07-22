# Libraries
library(plotly)
library(udunits2)
library(sf)
library(spData)
library(leaflet)
library(dplyr)
library(DT)

# Carga datos

## Capa cantones
cantones <- st_read(
  "https://raw.githubusercontent.com/gf0604-procesamientodatosgeograficos/2021i-datos/main/ign/delimitacion-territorial-administrativa/cr_cantones_simp_wgs84.geojson",
  quiet = TRUE
)

## Capa provincias
provincias <-
  st_read(
    "https://raw.githubusercontent.com/gf0604-procesamientodatosgeograficos/2021i-datos/main/ign/delimitacion-territorial-administrativa/cr_provincias_simp_wgs84.geojson",
    quiet = TRUE
  )

## Datos orquídeas

orquideas <-
  st_read(
    "https://raw.githubusercontent.com/gf0604-procesamientodatosgeograficos/2021i-datos/main/gbif/orchidaceae-cr-registros.csv",
    options = c(
      "X_POSSIBLE_NAMES=decimalLongitude",
      "Y_POSSIBLE_NAMES=decimalLatitude"
    ),
    quiet = TRUE
  )
st_crs(orquideas) = 4326

### Eliminación datos con incertidumbre alta
orquideas <-
  orquideas %>%
  filter(coordinateUncertaintyInMeters < 1000)

### Cruce datos cantón
orquideas <- orquideas %>%
  st_join(cantones["canton"])

# Tabla DT
orquideas %>%
  st_drop_geometry() %>%
  dplyr::select(species, eventDate, stateProvince, canton) %>%
  datatable(colnames = c("Especie", "Fecha", "Provincia", "Cantón"),
            options = list(searchHighlight = TRUE,
                           language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json'),
                           pageLength = 10))

# Gráfico Plotly