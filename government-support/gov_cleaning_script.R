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
