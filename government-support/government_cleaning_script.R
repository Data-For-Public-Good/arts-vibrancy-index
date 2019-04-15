# set working directory
setwd("~/Desktop/arts-vibrancy-index/government-support/raw")

# load packages
library(tidyr)
library(plyr)
library(dplyr)

# import and merge state funding data
state <- lapply(Sys.glob("NASAA_*.csv"), read.csv)
state <- do.call(rbind.data.frame, state)

# remove grantor and rename columns
state <- state[,-5]
colnames(state) <- c("zip", "year","state_awards","state_dollars")

# convert dollars to numeric and remove dollar and commas
state$state_dollars <- as.numeric(gsub("[\\$,]", "", state$state_dollars))

# sum awards and dollars by year for each zip code
state <- state %>%
  select(zip, year, state_awards, state_dollars) %>%
  group_by(zip, year) %>%
  summarise(state_awards = sum(state_awards), state_dollars = sum(state_dollars))

# import NEA, IMLS, and zip code data
IMLS <- read.csv("IMLS_Awarded_Grants_Search_NY_03-13-2019.csv")
NEA <- read.csv("NEAgrantsearch_1998-2019_30mi_10016.csv")
zip_new <- read.csv("~/Desktop/arts-vibrancy-index/other/zipcodes_new.csv")
colnames(zip_new) <- "zip"

# remove unnecessary columns from NEA and IMLS data sets
IMLS <- IMLS[,c(4,7,8)]
NEA <- NEA[,c(8,10,12)]

# rename columns (must detach dplyr package first)
colnames(IMLS) <- c("zip","year","federal_dollars")
colnames(NEA) <- c("zip","year","federal_dollars")

# convert dollars to numeric and remove dollar and commas 
IMLS$federal_dollars <- as.numeric(gsub("[\\$,]", "", IMLS$federal_dollars))
NEA$federal_dollars <- as.numeric(gsub("[\\$,]", "", NEA$federal_dollars))

# remove rows with NAs
IMLS <- drop_na(IMLS)
NEA <- drop_na(NEA)

# convert NEA zips to 5 digit
NEA$zip <- strtrim(as.character(NEA$zip), 5)
NEA$zip <- as.integer(NEA$zip)

# merge IMLS and NEA data into single file
federal <- rbind(NEA,IMLS)

# sum awards and dollars by year for each zip code
federal <- federal %>%
  select(zip, year, federal_dollars) %>%
  group_by(zip, year) %>%
  summarise(federal_awards = length(federal_dollars), federal_dollars = sum(federal_dollars))

# save only rows with years 2005-2015
federal <- federal[federal$year %in% c(2005:2015),]
state <- state[state$year %in% c(2005:2015),]

# merge state and federal into a single file
gov <- merge(federal, state, all = TRUE)
gov[is.na(gov)] <- 0

# remove rows with non-NYC zip codes
gov <- gov[gov$zip %in% zip_new$zip,]

# export federal data to csv
write.csv(gov, file = "~/Desktop/arts-vibrancy-index/government-support/government_clean.csv", row.names = FALSE)
