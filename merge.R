# set working directory
setwd("~/Desktop/arts-vibrancy-index/")

# load packages
library(tidyr)
library(plyr)

# import relevant files
providers <- read.csv("~/Desktop/arts-vibrancy-index/arts-providers/providers_clean.csv", header = TRUE)
dollars <- read.csv("~/Desktop/arts-vibrancy-index/arts-dollars/dollars_clean.csv", header = TRUE)
government <- read.csv("~/Desktop/arts-vibrancy-index/government-support/government_clean.csv", header = TRUE)

# merge files
arts_vibrancy <- merge(providers, dollars, all = TRUE)
arts_vibrancy <- merge(arts_vibrancy, government, all = TRUE)
arts_vibrancy[is.na(arts_vibrancy)] <- 0

# clean index data
# if columns 3-13 == 0, then delete row
rows2rm <- data.frame()
for (i in 1:nrow(arts_vibrancy)) {
  if(sum(arts_vibrancy[i,c(3:13)]) == 0) {
    rows2rm <- rbind(rows2rm,i)
  }
}
colnames(rows2rm) <- "row"
index <- arts_vibrancy[-rows2rm$row,]

# export raw arts vibrancy data to csv
write.csv(arts_vibrancy, file = "~/Desktop/arts-vibrancy-index/index_raw.csv", row.names = FALSE)
