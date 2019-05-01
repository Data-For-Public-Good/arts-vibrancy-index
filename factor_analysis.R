# refered to https://data.library.virginia.edu/getting-started-with-factor-analysis/
# for guidance on performing this factor analysis

# set working directory
setwd("~/Desktop/arts-vibrancy-index/")

# load libraries
library(dplyr)

# import relevant files
population <- read.csv("~/Desktop/arts-vibrancy-index/population_zipmap.csv", header = TRUE)
index_raw <- read.csv("~/Desktop/arts-vibrancy-index/index_clean_raw.csv", header = TRUE)

# standardize index measures by population
index <- index_raw
art_zips <- unique(index[,1])
for (i in art_zips) {
  pop <- population[population$zip == i, 2]
  index[which(index$zip == i),c(3:13)] <- index_raw[which(index_raw$zip == i),c(3:13)]/pop
}

#calculate the correlation matrices for each year
corMat <- list(prov_corMat=list(),
               doll_corMat=list(),
               govt_corMat=list())
for (i in 2005:2015) {
  x <- index[index$year == i, ]
  prov_corMat <- cor(x[,c(3:5)])
  doll_corMat <- cor(x[,c(6:9)])
  govt_corMat <- cor(x[,c(10:13)])
  corMat[[1]][[paste(i)]] <- prov_corMat
  corMat[[2]][[paste(i)]] <- doll_corMat
  corMat[[3]][[paste(i)]] <- govt_corMat
}

# perform factor analysis with factors = 1 because more factors are too many for 3-4 variables
factLoad <- list(prov_factLoad=list(),
                 doll_factLoad=list(),
                 govt_factLoad=list())
for (i in 2005:2015) {
  prov_factLoad <- factanal(covmat = corMat[[1]][[paste(i)]], factors = 1)
  doll_factLoad <- factanal(covmat = corMat[[2]][[paste(i)]], factors = 1)
  govt_factLoad <- factanal(covmat = corMat[[3]][[paste(i)]], factors = 1)
  factLoad[[1]][[paste(i)]] <- prov_factLoad$loadings
  factLoad[[2]][[paste(i)]] <- doll_factLoad$loadings
  factLoad[[3]][[paste(i)]] <- govt_factLoad$loadings
}

# weight measures according to factor loadings and scale (generate z-score)
index_weighted <- index
for (i in 2005:2015) {
  index_weighted[index_weighted$year== i, 3] <- scale(index[index$year== i, 3] * factLoad[["prov_factLoad"]][["2005"]][1])
  index_weighted[index_weighted$year== i, 4] <- scale(index[index$year== i, 4] * factLoad[["prov_factLoad"]][["2005"]][2])
  index_weighted[index_weighted$year== i, 5] <- scale(index[index$year== i, 5] * factLoad[["prov_factLoad"]][["2005"]][3])
  index_weighted[index_weighted$year== i, 6] <- scale(index[index$year== i, 6] * factLoad[["doll_factLoad"]][["2005"]][1])
  index_weighted[index_weighted$year== i, 7] <- scale(index[index$year== i, 7] * factLoad[["doll_factLoad"]][["2005"]][2])
  index_weighted[index_weighted$year== i, 8] <- scale(index[index$year== i, 8] * factLoad[["doll_factLoad"]][["2005"]][3])
  index_weighted[index_weighted$year== i, 9] <- scale(index[index$year== i, 9] * factLoad[["doll_factLoad"]][["2005"]][4])
  index_weighted[index_weighted$year== i, 10] <- scale(index[index$year== i, 10] * factLoad[["govt_factLoad"]][["2005"]][1])
  index_weighted[index_weighted$year== i, 11] <- scale(index[index$year== i, 11] * factLoad[["govt_factLoad"]][["2005"]][2])
  index_weighted[index_weighted$year== i, 12] <- scale(index[index$year== i, 12] * factLoad[["govt_factLoad"]][["2005"]][3])
  index_weighted[index_weighted$year== i, 13] <- scale(index[index$year== i, 13] * factLoad[["govt_factLoad"]][["2005"]][4])
}

# combine z-scores using Stouffer's method (sum of all the z-scores/sqrt of total number of observations)
# apply 45/45/10 weighting to standardized metrics to calculate arts vibrancy score
# compare all zip codes in 0-100 percentile ranking
art_vibrancy <- index_weighted %>%
  group_by(zip, year) %>%
  summarize(
    provScore = sum(independent_artists,art_firms,arts_organizations)/sqrt(length(art_zips)),
    dollScore = sum(total_revenue,total_compensation,total_expenses,contributed_revenue)/sqrt(length(art_zips)),
    govtScore = sum(federal_awards,federal_dollars,state_awards,state_dollars)/sqrt(length(art_zips)),
    vibrancy = (provScore * 0.45) + (dollScore * 0.45) + (govtScore * 0.10)
  )

# export to csv
write.csv(art_vibrancy, file = "~/Desktop/arts-vibrancy-index/art_vibrancy.csv", row.names = FALSE)
