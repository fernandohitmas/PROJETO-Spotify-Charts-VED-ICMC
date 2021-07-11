library(spData)
library(leaflet)
library(tidyverse)
library(sf)
library(leaflet)


dados <- readRDS("paises.rds")

musicas.mais.tocadas <- dados %>%
     group_by(Country) %>%
     summarise(total_plays = sum(Total.Streams))

artistas.mais.tocadas <- dados %>%
  group_by(Artist) %>%
  summarise(total_plays = sum(Total.Streams))

mapa <- world %>% select(name_long, geom) %>% as_tibble()

dados_mapa <- left_join(mapa, musicas.mais.tocadas, by = c("name_long" = "Country"))

colorData <- dados_mapa$total_plays
pal <- colorBin("YlOrRd", colorData, na.color = "#808080")

dados_mapa %>%
  leaflet %>%
  addTiles() %>%
  addPolygons(fillColor = ~pal(colorData), label = ~name_long,
                                                        smoothFactor = 0.5,
                                                        fillOpacity = 1,
                                                        weight = 0.5,
                                                        opacity = 0.8,
                                                        stroke = T,
                                                        color = "black",
                                                        highlightOptions = highlightOptions(
                                                          color = "black",
                                                          weight = 2,
                                                          bringToFront = TRUE
                                                        )#,
#                                                        popup = ~ paste0(
#                                                          sep = " ",
#                                                          "<b>", name_long, "<b><br>",
#                                                          "área km2: ", area_km2, "<br>",
 #                                                         "Expectativa de vida: ", round(lifeExp,1) , "<br>",
                                                          #"Pib per capita: ", round(gdpPercap,2), "<br>"
                                                        ) %>%
  addLegend("bottomright",
            title = " ",
            pal = pal,
            values = ~colorData)
