# set working directory
setwd("~/Desktop/arts-vibrancy-index/other/")

# load libraries
library(utils)
library(rgdal)
library(dplyr)

# import relevant files
zip <- read.csv("~/Desktop/arts-vibrancy-index/other/zipcodes.csv", header = FALSE)
index_raw <- read.csv("~/Desktop/arts-vibrancy-index/index_raw.csv", header = TRUE)

# save population data from NYC Open Data zip code boundaries file
zipmap <- readOGR(dsn = "~/Desktop/arts-vibrancy-index/other/zip_boundaries", layer = "ZIP_CODE_040114" )
population<-as.data.frame(zipmap)
population <- population[,c(1,4)]
colnames(population) <- c("zip","population")
population$zip <- as.numeric(as.character(population$zip))

# clean index data
# if columns 3-13 == 0, then delete row
rows2rm <- data.frame()
for (i in 1:nrow(index_raw)) {
  if(sum(index_raw[i,c(3:13)]) == 0) {
    rows2rm <- rbind(rows2rm,i)
  }
}
colnames(rows2rm) <- "no"
index <- index_raw[-rows2rm$no,]

# identify ZIPs in index that do not have population data
'%ni%' <- Negate('%in%')
a <- as.data.frame(unique(index[index$zip %ni% population$zip, 1]))
colnames(a) <- "zip"

# identify ZIPs in index that were not part of the original ZIP file
b <- as.data.frame(unique(index[index$zip %ni% zip$V1,1]))
colnames(b) <- "zip"

# merge into single file of ZIPs to check
x <- union(a,b)

# export to csv
# write.csv(x, file = "~/Desktop/arts-vibrancy-index/other/zip_check.csv", row.names = FALSE)

# drop retired zip code (10015)
rows2rm <- which(index$zip == 10015)
index <- index[-rows2rm,]

# identify zip codes without population data
zip_change <- as.data.frame(unique(index[index$zip %ni% population$zip, 1]))
colnames(zip_change) <- "oldzip"

# provide zip replacement values for zips without population data
zip_change$newzip <- c("10007","10019","10036","10011","10001","10022","10018","10022","10016","10010","10017","10020",
                       "10038","10003","11201","11201","11217","11201","11216","11355","11375","11366","11691")

# zip codes identified by Steve R. that are very small (maybe just one building) and have population less than 10
oldzip <- c("10165","10170","10173","10167","10174","10168","10169","10177","10172","10171","10020","10112","10103","10162",
            "10153","10152","10154","10110","10199","10119","10278","10279","10271","10111","10115","10311","11351","11359","11371")
newzip <- c("10017","10017","10017","10017","10017","10017","10017","10017","10017","10017","10019","10019","10019","10075",
            "10022","10022","10022","10036","10001","10001","10007","10007","10005","10019","10027","10314","11356","11360","11369")
zip_change <- rbind(zip_change,cbind(oldzip,newzip))
zip_change <- zip_change %>%
  mutate_at(vars(oldzip, newzip), list(as.numeric))

# clean index data
# if zip matches oldzip, then replace with newzip
rows2change <- which(index$zip %in% zip_change$oldzip)
for (i in rows2change) {
  x <- index[i,1]
  y <- which(x == zip_change$oldzip)
  index[i,1] <- zip_change[y,2]
}

# sum art firms by year for each zip code
index <- index %>%
  group_by(zip, year) %>%
  summarise(
    independent_artists = sum(independent_artists),
    art_firms = sum(art_firms),
    arts_organizations = sum(arts_organizations),
    total_revenue = sum(total_revenue),
    total_compensation = sum(total_compensation),
    total_expenses = sum(total_expenses),
    contributed_revenue = sum(contributed_revenue),
    federal_awards = sum(federal_awards),
    federal_dollars = sum(federal_dollars),
    state_awards = sum(state_awards),
    state_dollars = sum(state_dollars)
  )

# export to csv
write.csv(index, file = "~/Desktop/arts-vibrancy-index/other/index_clean_raw.csv", row.names = FALSE)
write.csv(population, file = "~/Desktop/arts-vibrancy-index/other/population_zipmap.csv", row.names = FALSE)
