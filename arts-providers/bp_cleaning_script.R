# set working directory
setwd("~/Desktop/arts-vibrancy-index/arts-providers/raw")

# load packages
library(tidyr)
library(plyr)

# import NYC zip code file
zip <- read.csv("~/Desktop/arts-vibrancy-index/zipcodes.csv", header = FALSE)

# import all business pattern data files
bp <- lapply(Sys.glob("BP_*.csv"), read.csv)

# merge into single file
bp <- do.call(rbind.data.frame, bp)

# remove rows with non-NYC zip codes and keep only relevant columns
bp <- bp[bp$GEO.id2 %in% zip$V1, c(2,5,6,8,9)]

# convert rows to columns
bp <- spread(bp, EMPSZES.id, ESTAB)

# remove class sizes above 1000 employees (none in NYC that aren't included in 1000 or more)
bp <- bp[,1:13]

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
bp <- rename(bp, c("GEO.id2"="zip","NAICS.display.label"="industry","YEAR.id"="year","001"="all",
                   "212"="class1","220"="class2","230"="class3","241"="class4","242"="class5",
                   "251"="class6","252"="class7","254"="class8","260"="class9"))

# convert all columns except industry to integer
indx <- sapply(bp, is.factor)
indx[2] <- FALSE
bp[indx] <- lapply(bp[indx], function(x) as.numeric(as.character(x)))
str(bp)

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
  x <- bp[,i+4] * weights[i]
  weighted_values <- cbind(weighted_values,x)
}
weighted_values <- as.data.frame(weighted_values)
colnames(weighted_values) <- c("weighted_class1","weighted_class2","weighted_class3","weighted_class4","weighted_class5",
                               "weighted_class6","weighted_class7","weighted_class8","weighted_class9")
weighted_all <- rowSums(weighted_values)
weighted_values <- cbind(weighted_all,weighted_values)
bp <- cbind(bp, weighted_values)

# export to csv
write.csv(bp, file = "~/Desktop/arts-vibrancy-index/arts-providers/BP_clean.csv", row.names = FALSE)
