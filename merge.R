# set working directory
setwd("~/Desktop/arts-vibrancy-index/")

# load packages
library(tidyr)
library(plyr)

# import relevant files
zip <- read.csv("~/Desktop/arts-vibrancy-index/other/zipcodes.csv", header = FALSE)
census <- read.csv("~/Desktop/arts-vibrancy-index/other/census_clean.csv", header = TRUE)
providers <- read.csv("~/Desktop/arts-vibrancy-index/arts-providers/providers_clean.csv", header = TRUE)
dollars <- read.csv("~/Desktop/arts-vibrancy-index/arts-dollars/dollars_clean.csv", header = TRUE)
government <- read.csv("~/Desktop/arts-vibrancy-index/government-support/government_clean.csv", header = TRUE)

# merge files
arts_vibrancy <- merge(providers, dollars, all = TRUE)
arts_vibrancy <- merge(arts_vibrancy, government, all = TRUE)
arts_vibrancy[is.na(arts_vibrancy)] <- 0

# export raw arts vibrancy data to csv
write.csv(gov, file = "~/Desktop/arts-vibrancy-index/index_raw.csv", row.names = FALSE)
