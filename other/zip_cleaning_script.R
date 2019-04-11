# set working directory
setwd("~/Desktop/arts-vibrancy-index/other/")

# load libraries
library(utils)
library(rgdal)
library(dplyr)

# import relevant files
zip <- read.csv("~/Desktop/arts-vibrancy-index/other/zipcodes.csv", header = FALSE)
census <- read.csv("~/Desktop/arts-vibrancy-index/other/census_clean.csv", header = TRUE)
index_raw <- read.csv("~/Desktop/arts-vibrancy-index/index_raw.csv", header = TRUE)

# clean index data
# if columns 3-13 == 0, then delete row
rows2rm <- data.frame()
for (i in 1:nrow(index_raw)) {
  if(sum(index_raw[i,c(3:13)]) == 0) {
    rows2rm <- rbind(rows2rm,i)
  }
}
index <- index_raw[-rows2rm$X156L,]

# save population data from NYC Open Data zip code boundaries file
zipmap <- readOGR(dsn = "~/Desktop/arts-vibrancy-index/other/zip_boundaries", layer = "ZIP_CODE_040114" )
population<-as.data.frame(zipmap)
population <- population[,c(1,4)]
colnames(population) <- c("zip","population")
population$zip <- as.numeric(as.character(population$zip))

# identify ZIPs in index that do not have population data
'%ni%' <- Negate('%in%')
a <- as.data.frame(unique(index[index$zip %ni% population$zip, 1]))
colnames(a) <- "zip"

# identify ZIPs in index that were not part of the original ZIP file
b <- as.data.frame(unique(index[index$zip %ni% zip$V1,1]))
colnames(b) <- "zip"

# merge into single file of ZIPs to check
x <- union(a,b)

# export to csv
# write.csv(x, file = "~/Desktop/arts-vibrancy-index/other/zip_check.csv", row.names = FALSE)
