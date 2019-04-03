# set working directory
setwd("~/Desktop/arts-vibrancy-index/census")

# load packages
library(tidyr)
library(plyr)

# import NYC zip code file
zip <- read.csv("~/Desktop/arts-vibrancy-index/zipcodes.csv", header = FALSE)

# import all business pattern data files
census <- read.csv("2010_census.csv")

# remove rows with non-NYC zip codes and keep only population column
census <- census[census$GEO.id2 %in% zip$V1,c(2,4)]

# rename columns
colnames(census) <- c("zip","population")

# export to csv
write.csv(census, file = "~/Desktop/arts-vibrancy-index/census/census_clean.csv", row.names = FALSE)
