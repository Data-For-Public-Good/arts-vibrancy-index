# set working directory
setwd("~/Desktop/arts-vibrancy-index/")

# load libraries
library(utils)
library(rgdal)
library(dplyr)
library(psych)

# import relevant files
population <- read.csv("~/Desktop/arts-vibrancy-index/population_zipmap.csv", header = TRUE)
index_raw <- read.csv("~/Desktop/arts-vibrancy-index/index_clean_raw.csv", header = TRUE)

# standardize index measures by population
# for each
index <- index_raw
art_zips <- unique(index[,1])
for (i in art_zips) {
  pop <- population[population$zip == i, 2]
  index[which(index$zip == i),c(3:13)] <- index_raw[which(index_raw$zip == i),c(3:13)]/pop
}

# save metric measures
providers <- index[,c(1,2,3:5)]
dollars <- index[,c(1,2,6:9)]
gov_sup <- index[,c(1,2,10:13)]

#calculate the correlation matrix
corMat <- cor(index[,c(3:5)])
#display the correlation matrix
corMat

#use fa() to conduct an oblique principal-axis exploratory factor analysis
#save the solution to an R variable
solution <- fa(r = corMat, nfactors = 2, rotate = "oblimin", fm = "pa")
#display the solution output
solution

