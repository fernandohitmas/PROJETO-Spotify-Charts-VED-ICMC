library(shiny)
library(spData)
library(leaflet)
library(tidyverse)
library(sf)
library(leaflet)
library(plotly)
library(data.table)

# Data Import
data.ranking <- read_csv("../Data/paises_e_nome_abreviado.csv")
data.total.daily <- read_csv("../Data/all_countries_by_date.csv")
data.countries.list <- read_csv("../Data/country_names.csv")
data.map <- world

# Total Streams by country - from the available period in the spotify charts website and only for the top 200 musics.
data.total.country <- data.total.daily %>%
  group_by(Abreviatted) %>%
  summarise(total_plays = sum(Total.Streams))

# Concatenation of Spotify Data to World data by utilizing inner_join
data.map <- inner_join(data.map, data.total.country, by = c("iso_a2" = "Abreviatted"))
# Adding the Streams per Population for each country.
data.map <- data.map %>% mutate(streams_per_pop = total_plays/pop)


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
  
  # Map Output
  output$mapa <- renderLeaflet({
    
    # Interval in which the color palette (pal = RdPu) will be applied 
    colorData <- data.map$streams_per_pop
    pal <- colorBin("RdPu", colorData, na.color = "#808080")
    
    data.map %>%
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
                    "Total de Streams: ", round(total_plays/1e+9,2), "B<br>",
                    "População: ", round(pop/1000000,2) , "M<br>",
                    "Streams/População: ", round(streams_per_pop,2), "<br>"
                  )) %>%
      addLegend("topright",
                title = "Streams per<br> population",
                pal = pal,
                values = ~colorData)
    
    
  })
   
  # Table Output
  output$tabela <- renderPlotly({
    
    # Leaflet Input via map click
    p <- input$mapa_shape_click
    country <- p$id
    
    # If the user has not clicked country it won't display any Table
    if(is.null(country)){return()}  
    
    # Ranking Data filtered by the selected country 
    rank <- data.ranking %>%
      filter(Abreviatted == country) %>%
      select(Artist, Song,Total.Streams) %>%
      t()
    
    dados %>% filter(Abreviatted == country) %>%
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
  
  # Time Series output
  output$serie_temp <- renderPlotly({
    
    # Leaflet Input via map click
    p <- input$mapa_shape_click
    country <- p$id
    
    # If the user has not clicked country it won't display any Time Series
    if(is.null(country)){return()}  
    
    # Country identification 
    country.abrev <- data.countries.list$Abreviatted[data.countries.list$Abreviatted %in% country]
    country.complete <- data.countries.list$Name[data.countries.list$Abreviatted %in% country]
    
    # Linear Regression Model for selected country
    fit <- lm(Total.Streams ~ Date, data = data.total.daily%>% filter(Abreviatted %in% country.abrev) %>%
                group_by(Abreviatted))
    
    data.total.daily %>%
      filter(Abreviatted %in% country.abrev) %>%
      plot_ly(type="scatter",mode="line")%>%
      add_lines(x=~Date,y=~Total.Streams, name="Série Temporal")%>%
      layout(title = list(text = ~country.complete, x = 0.55, y = 0.92), 
             legend = list(y=.95, x=.05), 
             xaxis = list(title="Data"), 
             yaxis = list(title="Total de Streams"))%>%                                 
      add_lines(x = ~Date, y = fitted(fit), name="Regressão Linear")%>%
      add_lines(x=~Date,y=~frollmean(Total.Streams,7),name="Média Semanal")  
  })
}

shinyApp(ui, server)