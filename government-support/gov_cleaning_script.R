# set working directory
setwd("~/Desktop/arts-vibrancy-index/government-support/raw")

# load packages
library(tidyr)
library(plyr)

# import and merge state funding data
state <- lapply(Sys.glob("NASAA_*.csv"), read.csv)
state <- do.call(rbind.data.frame, state)

# remove grantor and rename columns
state <- state[,-5]
state <- rename(state, c("Zip.Code"="zip","Fiscal.Year"="year","No..of.Awards"="awards","Grant.Dollars"="dollars"))

# convert dollars to numeric and remove dollar and commas
state$dollars <- as.numeric(gsub("[\\$,]", "", state$dollars))

# sum awards and dollars by year for each zip code
library(dplyr)
state <- state %>%
  select(zip, year, awards, dollars) %>%
  group_by(zip, year) %>%
  summarise(awards = sum(awards), dollars = sum(dollars))

# export state data to csv
write.csv(state, file = "~/Desktop/arts-vibrancy-index/government-support/state_clean.csv", row.names = FALSE)

# import NEA and IMLS data
IMLS <- read.csv("IMLS_Awarded_Grants_Search_NY_03-13-2019.csv")
NEA <- read.csv("NEAgrantsearch_1998-2019_30mi_10016.csv")

# remove unnecessary columns from NEA and IMLS data sets
IMLS <- IMLS[,c(4,7,8)]
NEA <- NEA[,c(8,10,12)]

# rename columns (must detach dplyr package first)
detach("package:dplyr", unload=TRUE)
IMLS <- rename(IMLS, c("zip_added"="zip","Fiscal.Year"="year","Award"="dollars"))
NEA <- rename(NEA, c("Zip"="zip","Fiscal.Year"="year","Grant.Amount"="dollars"))

# convert dollars to numeric and remove dollar and commas 
IMLS$dollars <- as.numeric(gsub("[\\$,]", "", IMLS$dollars))
NEA$dollars <- as.numeric(gsub("[\\$,]", "", NEA$dollars))

# remove rows with NAs
IMLS <- drop_na(IMLS)
NEA <- drop_na(NEA)

# convert NEA zips to 5 digit
NEA$zip <- strtrim(as.character(NEA$zip), 5)
NEA$zip <- as.integer(NEA$zip)

# merge IMLS and NEA data into single file
federal <- rbind(NEA,IMLS)

# sum awards and dollars by year for each zip code
library(dplyr)
federal <- federal %>%
  select(zip, year, dollars) %>%
  group_by(zip, year) %>%
  summarise(awards = length(dollars), dollars = sum(dollars))

# export federal data to csv
write.csv(federal, file = "~/Desktop/arts-vibrancy-index/government-support/federal_clean.csv", row.names = FALSE)
