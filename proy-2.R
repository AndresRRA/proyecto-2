# Libraries
library(flexdashboard)
library(raster)
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
  mutate(coordinateUncertaintyInMeters = as.numeric
         (coordinateUncertaintyInMeters))%>%
  mutate(eventDate = as.Date(eventDate, "%Y-%m-%d"))
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
orquideas_10mayores <-
  orquideas %>% 
  st_drop_geometry() %>%
  filter(!is.na(species) & species != "") %>%
  group_by(species) %>% 
  summarise(registros = n()) %>%
  arrange(desc(registros)) %>%
  slice(1:10) 

orquideas_otros <-
  orquideas %>% 
  st_drop_geometry() %>%
  filter(!is.na(species) & species != "") %>%
  group_by(species) %>% 
  summarise(registros = n()) %>%
  arrange(desc(registros)) %>%
  slice(11:232) %>%
  group_by(species = as.character("Otros")) %>%
  summarise(registros = sum(registros))

especies_orquideas <- merge(orquideas_10mayores, orquideas_otros,
                                   all = TRUE)

pal_plotly <- c("#ffd700", "#0059cf", "#008024", "#0000bf", "#ba151b",
                "#00a1b3", "#ff7300", "#42087b", "#60BC83", "#1C2DAA")

plot_ly(especies_orquideas, labels = ~ species, values = ~ registros,
        type = "pie", sort = TRUE,
        textposition = 'inside',
        marker = list (colors = pal_plotly),
        textinfo = 'label+percent',
        hover = ~ 'Cantidad de registros',
        hoverinfo = "label+value",
        showlegend = TRUE) %>%
  layout(title = "Porcentaje de registros de orquídeas en Costa Rica")%>%
  config(locale = "es")

# Mapas
