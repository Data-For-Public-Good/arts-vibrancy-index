# set working directory
setwd("~/Desktop/arts-vibrancy-index/arts-providers/raw")

# load packages
library(tidyr)
library(plyr)
library(dplyr)

# import NYC zip code file
zip <- read.csv("~/Desktop/arts-vibrancy-index/other/zipcodes_new.csv", header = FALSE)

# import all business pattern data files
providers <- lapply(Sys.glob("BP_*.csv"), read.csv)

# merge into single file
providers <- do.call(rbind.data.frame, providers)

# remove rows with non-NYC zip codes and keep only relevant columns
providers <- providers[providers$GEO.id2 %in% zip$V1, c(2,5,6,8,9)]

# convert rows to columns
providers <- spread(providers, EMPSZES.id, ESTAB)

# remove class sizes above 1000 employees (none in NYC that aren't included in 1000 or more)
providers <- providers[,1:13]

# rename columns to NAICS classes
# Class 1 (1-4 employees) 
# Class 2 (5-9 employees) 
# Class 3 (10-19 employees) 
# Class 4 (20-49 employees) 
# Class 5 (50-99 employees)
# Class 6 (100-249 employees)
# Class 7 (250-499 employees) 
# Class 8 (500-999 employees) 
# Class 9 (1000 or more employees) 
colnames(providers) <- c("zip","industry","year","all","class1","class2","class3",
                                 "class4","class5","class6","class7","class8","class9")

# convert all columns except industry to integer
indx <- sapply(providers, is.factor)
indx[2] <- FALSE
providers[indx] <- lapply(providers[indx], function(x) as.numeric(as.character(x)))
str(providers)

# add weighted column which provides an estimate of number of employees (following DataArts multiplication factor below)
# Class 1 orgs by 2
# Class 2 orgs by 7
# Class 3 orgs by 15
# Class 4 orgs by 30
# Class 5 orgs by 70
# Class 6 orgs by 170
# Class 7 orgs by 370
# Class 8 orgs by 740
# Class 9 orgs by 1100
weights <- c(2,7,15,30,70,170,370,740,1100)
weighted_values <- vector()
for (i in 1:9) {
  x <- providers[,i+4] * weights[i]
  weighted_values <- cbind(weighted_values,x)
}
weighted_values <- as.data.frame(weighted_values)
colnames(weighted_values) <- c("weighted_class1","weighted_class2","weighted_class3","weighted_class4","weighted_class5",
                               "weighted_class6","weighted_class7","weighted_class8","weighted_class9")
weighted_all <- rowSums(weighted_values)
weighted_values <- cbind(weighted_all,weighted_values)
providers <- cbind(providers, weighted_values)

# save only rows with years 2005-2015
providers <- providers[providers$year %in% c(2005:2015),]

# export to csv
write.csv(providers, file = "~/Desktop/arts-vibrancy-index/arts-providers/providers_FULL_clean.csv", row.names = FALSE)

# calculate independent_artists in each zip
# save only rows and columns with unweighted number of artists
artists <- providers[providers$industry == "Independent artists, writers, and performers",]
artists <- artists[,c(1,3,4)]
colnames(artists) <- c("zip","year","independent_artists")

# calculate number of arts firms in each zip
# remove independent artists
firms <- providers[providers$industry != "Independent artists, writers, and performers",]
firms <- firms[,c(1,3,14)]
colnames(firms) <- c("zip","year","art_firms")

# sum art firms by year for each zip code
firms <- firms %>%
  select(zip, year, art_firms) %>%
  group_by(zip, year) %>%
  summarise(art_firms = sum(art_firms))

# merge independent artists and art firms into a single file
providers <- merge(artists, firms, all = TRUE)
providers[is.na(providers)] <- 0

# export to csv
write.csv(providers, file = "~/Desktop/arts-vibrancy-index/arts-providers/providers_clean.csv", row.names = FALSE)
