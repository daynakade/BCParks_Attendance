library(tidyr)
library(readr)
library(dplyr)

#Import historical climate data
historicaldata = readRDS("Data/Attendance/Climate/historical-climate-data.rds")

#Import Camping and Day-use data 
# setwd("~/Desktop/bio/440/BCParks_Attendance/Data/bcparks")
camping <- read.csv("Data/Attendance/Park Data/camping.csv", na = "0", check.names = FALSE)
dayuse <- read.csv("Data/Attendance/Park Data/dayuse.csv", na = "0", check.names = FALSE)

# CLEAN ATTENDANCE DATA
#Convert from wide to long format
camping <- gather(camping, date, visitortotal, "2010-01-01":"2019-12-01", factor_key = TRUE)
dayuse <- gather(dayuse, date, visitortotal, "2010-01-01":"2019-12-01", factor_key = TRUE)
#Remove months with no values (NAs)
camping <- na.omit(camping)
dayuse <- na.omit(dayuse)
#Classify type of attendance
camping$attendancetype <- "camping"
dayuse$attendancetype <- "dayuse"
#Merge day use and camping information into one dataset
bcparks <- rbind(camping,dayuse) 


#ADD NEW COLUMNS: MONTH AND YEAR
bcparks <- bcparks %>%
  separate(date, sep="-", into = c("year", "month", "day"))
# Bring back the date column
bcparks$date <- paste(paste(bcparks$year, bcparks$month, sep = "-"), 15, sep = "-")
bcparks$date <- as.POSIXct(bcparks$date, format = "%Y-%m-%d")
bcparks$month <- as.numeric(bcparks$month)
bcparks$park <- as.factor(bcparks$park)
# Remove day column (it's an arbitrary number)
bcparks = subset(bcparks, select = -c(day))

#ADD NEW COLUMN: BC POPULATION
#import historic population data
population_records <- read.csv("Data/Attendance/population/population_records.csv")
#remove unnecessary growth rate column
population_records = subset(population_records, select =-c(3))
#add historic population as a column
bcparks <- merge(bcparks,population_records,by=c("year"))


#ADD NEW COLUMN: ATTENDANCE CORRECTED FOR POPULATION SIZE
bcparks$attendance <- bcparks$visitortotal/bcparks$BCpop*1000


#ADD NEW COLUMNS: LATITUDE AND LONGITUDE COORDINATES
#import park coordinate data
park_coordinates <- read.csv("Data/Attendance/Park Data/park_coordinates.csv")
#add latitude and longitude as columns
bcparks <- merge(bcparks,park_coordinates, by=c("park", "region"))


#ADD NEW COLUMNS: AVG MONTHLY TEMPERATURES/DAILY PRECIPITATION NEAR PARK
#Get rid of unnecessary columns in historical climate dataset
historicaldata = select(historicaldata, -c(dec_date, elevation))
#Merge the datasets
bcparks <- merge(x=bcparks,y=historicaldata, 
             by=c("latitude","longitude", "year", "month"), all.x=TRUE)
bcparks$park <- as.factor(bcparks$park)

#Clean up environment
rm(camping,dayuse,park_coordinates,population_records,historicaldata)

#Save data as rds
saveRDS(bcparks, file = "Data/Attendance/Park Data/bcparks.rds")
