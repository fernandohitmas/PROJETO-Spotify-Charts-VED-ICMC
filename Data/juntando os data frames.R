df66$Country <- c("United States", "United States", "United States", "United States", "United States") # adicionando uma coluna de nome "Country"

library(dplyr)

df66 = df66 %>% select(Artist, Song, Country, Total.Streams) # reordenando as colunas de df66

total <- rbind(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13, df14, df15, df16, df17, df18, df19, df20, df21, df22, df23, df24, df25, df26, df27, df28, df29, df30, df31, df32, df33, df34, df35, df36, df37, df38, df39, df40, df41, df42, df43, df44, df45, df46, df47, df48, df49, df50, df51, df52, df53, df54, df55, df56, df57, df58, df59, df60, df61, df62, df63, df64, df65, df66, df67, df68) # juntando verticalmente os data frames

setwd("~/jupyter/data")

saveRDS(total, file = "paises.rds") # salvando o data frame "total"

a <- readRDS("paises.rds")

a # testando se foi realmente salvo