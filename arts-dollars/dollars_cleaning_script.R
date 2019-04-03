# set working directory
setwd("~/Desktop/arts-vibrancy-index/arts-dollars/by_zip")

# load packages
library(tidyr)
library(plyr)

# import all business pattern data files
dollars = ldply(list.files(pattern = "csv"), function(filename) {
  x = read.csv(filename)
  x$filename = filename
  return(x)
})

# remove X and program revenue columns
dollars <- dollars[,c(2:7,9)]

# rename columns
colnames(dollars) <- c("zip","arts_organizations","total_revenue","total_compensation","total_expenses",
                       "contributed_revenue","year")

# trim year column
dollars$year <- gsub("[\\.by_zip.csv]", "", dollars$year)

# sort data by zip code
dollars <- dollars[order(dollars$zip),] 

# move year column to second position
dollars <- dollars[,c(1,7,2:6)]

#write to csv
write.csv(dollars, file = "~/Desktop/arts-vibrancy-index/arts-dollars/dollars_clean.csv", row.names = FALSE)
