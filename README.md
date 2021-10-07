# Visualização de dados do Spotify Charts
## Autores: <a href="https://github.com/alicegp">Alice Pérez</a> e Fernando Masumoto

Hoje o Spotify diponibiliza um rank das 200 músicas mais tocadas do seu catálogo no site <a href="www.spotifycharts.com">www.spotifycharts.com</a>, nele é possível acessar um histórico, a depender do país, que conta com o registro desde 01 de janeiro de 2017.

Os dados foram obtidos utilizando Web Scrapping com Python e as visualizações posteriores foram todas construídas com R.

Serão utilizadas visualizações em mapa, série temporal e tabela.

<hr>

## (EN) Data Visuzaliation from Spotify Charts

Spotify has today a rank of the 200 most played musics in the site <a href="www.spotifycharts.com">www.spotifycharts.com</a>, you can choose the country and you can choose the date (by day or by week). The oldest data goes back to 2017-01-01, but not all countries have all this data, some of them started more recently.

The main objective was to build an app to visualize all this data and the platform we have chosen to use is the program language R and its Shiny and Plotly libraries.

The data we utilized was scrapped from the site already mentioned and for this task we created a script based in the program from the user <a href="https://gist.github.com/hktosun/d4f98488cb8f005214acd12296506f48">hktosun</a>. The main difference is the utilization of parallel requests.
