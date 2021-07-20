library(shiny)
library(spData)
library(leaflet)
library(tidyverse)
library(sf)
library(leaflet)
library(plotly)
library(data.table)

dados <- readRDS("paises_e_nome_abreviado.rds")

musicas.mais.tocadas <- dados %>%
  group_by(Abreviatted) %>%
  summarise(total_plays = sum(Total.Streams))

artistas.mais.tocadas <- dados %>%
  group_by(Artist) %>%
  summarise(total_plays = sum(Total.Streams))

mapa <- world

dados_mapa <- inner_join(mapa, musicas.mais.tocadas, by = c("iso_a2" = "Abreviatted"))

dados_mapa <- dados_mapa %>% mutate(streams_por_pop = total_plays/pop)

todos.paises <- read_csv("all_countries_by_date.csv")

countries.spotify <- read_csv("country_names.csv")

lista.paises <- countries.spotify %>%
  filter(Name != "Global" & Name != "Hong Kong" & Name != "Singapore" & Name != "Cyprus")
ui <- fluidPage(
  titlePanel("Visualização de dados do Spotify Charts"),
  
  sidebarLayout(
    
    sidebarPanel(width=0),
    
    mainPanel(width=40,
              tabsetPanel(
                tabPanel("Mapa", leafletOutput("mapa")), 
                tabPanel("Gráfico", plotlyOutput(outputId = "serie_temp")), 
                tabPanel("Tabela", plotlyOutput(outputId = "tabela"))
              )
    )
  )
  
)   


server <- function(input, output, session) {
  
  output$mapa <- renderLeaflet({
    
    colorData <- dados_mapa$streams_por_pop
    pal <- colorBin("RdPu", colorData, na.color = "#808080")
    
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
                  ),
                  layerId = ~iso_a2,
                  popup = ~ paste0(
                    sep = " ",
                    "<b>", name_long, "</b><br>",
                    "Total Streams: ", round(total_plays/1000000), "M<br>",
                    "Population: ", round(pop/1000000,2) , "M<br>",
                    "Streams/Population: ", round(streams_por_pop,2), "<br>"
                  )) %>%
      addLegend("topright",
                title = "Streams per<br> population",
                pal = pal,
                values = ~colorData)
    
    
  })
  
  output$tabela <- renderPlotly({
    pais <- input$mapa_shape_click
    if(is.null(pais)) return()
    
    rank <- dados %>%
      filter(Abreviatted == pais$id) %>%
      select(Artist, Song,Total.Streams) %>%
      t()
    
    #browser()
    dados %>% filter(Abreviatted == pais$id) %>%
      plot_ly(
        type = 'table',
        columnwidth = c(200, 200, 200),
        columnorder = c(0, 1, 2),
        header = list(
          values = c("Artista","Música","Streams"),
          align = c("center", "center"),
          line = list(width = 1, color = 'SlateGray'),
          fill = list(color = c("#87cefa", "#87cefa", "#fae987")),
          font = list(size = 16, color = "DarkSlateGray")
        ),
        cells = list(
          values = rank,
          align = c("center","center", "center"),
          line = list(color = "SlateGray", width = 1),
          font = list( size = 14, color = c("DarkSlateGray")),
          height=30
        )
      )
  })
  
  output$serie_temp <- renderPlotly({
    
    comeco <- input$data[1]
    fim <- input$data[2]
    
    p <- input$mapa_shape_click
    
    pais <- p$id
    
    pais.abrev <- lista.paises$Abreviatted[lista.paises$Abreviatted %in% pais]
    pais.completo <- lista.paises$Name[lista.paises$Abreviatted %in% pais]
    fit <- lm(Total.Streams ~ Date, data = todos.paises%>% filter(Abreviatted %in% pais.abrev) %>%
                group_by(Abreviatted))
    todos.paises %>%
      filter(Abreviatted %in% pais.abrev) %>%
      group_by(Abreviatted) %>%
      plot_ly(type="scatter",mode="line")%>%
      add_lines(x=~Date,y=~Total.Streams, name="Série Temporal")%>%
      layout(title = list(text = ~pais.completo, x = 0.55, y = 0.92), legend = list(y=.95, x=.05))%>%                                 
      add_lines(x = ~Date, y = fitted(fit), name="Regressão Linear")%>%
      add_lines(x=~Date,y=~frollmean(Total.Streams,7),name="Média Semanal")  
  })
}

shinyApp(ui, server)