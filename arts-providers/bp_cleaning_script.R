# set working directory
setwd("~/Desktop/arts-vibrancy-index/arts-providers/raw")

# load packages
library(tidyr)
library(plyr)

# import NYC zip code file
zip <- read.csv("zipcodes.csv", header = FALSE)

# import all business pattern data files
df <- lapply(Sys.glob("BP_*.csv"), read.csv)

# merge into single file
df <- do.call(rbind.data.frame, df)

# remove rows with non-NYC zip codes and keep only relevant columns
df <- df[df$GEO.id2 %in% zip$V1, c(2,5,6,8,9)]

# convert rows to columns
df <- spread(df, EMPSZES.id, ESTAB)

# rename columns
df <- rename(df, c("GEO.id2"="zip","NAICS.display.label"="industry","YEAR.id"="year",
                           "001"="all","212"="1_4","220"="5_9","230"="10_19","241"="20_49",
                           "242"="50_99","251"="100_249","252"="250_499","254"="500_999",
                           "260"="1000_more","262"="1000_1499","263"="1500_2499",
                           "271"="2500_4999","273"="5000_more"))

# replace NAs with 0
df[is.na(df)] <- 0

# export to csv
write.csv(df, file = "~/Desktop/arts-vibrancy-index/arts-providers/BP_clean.csv", row.names = FALSE)
