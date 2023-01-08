library(maptools)
library(ggplot2)
library(rgdal)
library(sf)
library(terra)
library(raster)
library(broom)
library(RColorBrewer)
library(rgeos)
library(dplyr)

###
# Read in Information
###
dta <- read.csv("../data/student_zip_census.csv")

# Create overall, WHT, and POC ratios
dta$UO_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$POP_YOUTH_TOTAL + 1)
dta$UO_WHT_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$WHT_YOUTH_TOTAL + 1)
dta$UO_POC_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$POC_YOUTH_TOTAL + 1)

dta$WHT_YOUTH_RATIO <- dta$WHT_YOUTH_TOTAL / (dta$POP_YOUTH_TOTAL + 1)
dta$POC_YOUTH_RATIO <- dta$POC_YOUTH_TOTAL / (dta$POP_YOUTH_TOTAL + 1)

dta$UO_STUDENTS_QUARTILES <- cut(dta$UO_STUDENTS,quantile(dta[dta$POP_YOUTH_TOTAL > 0,]$UO_STUDENTS),include.lowest=T,labels=F)
dta$UO_YOUTH_RATIO_QUARTILES <- cut(dta$UO_YOUTH_RATIO,quantile(dta[dta$POP_YOUTH_TOTAL > 0,]$UO_YOUTH_RATIO),include.lowest=T,labels=F)


###
# Set up map information
###

#state.map <- readShapeSpatial("maps/tl_2020_41_all/tl_2020_41_state20.shp")
#zip.map <- readShapeSpatial("maps/tl_2010_41_zcta510/tl_2010_41_zcta510.shp")
state.map <- readOGR("maps/tl_2020_41_all/tl_2020_41_state20.shp")
county.map <- readOGR("maps/tl_2020_41_all/tl_2020_41_county20.shp")
zip.map <- readOGR("maps/tl_2010_41_zcta510/tl_2010_41_zcta510.shp") # Confirmed on Nat'l map that 2010 boundries are same as 2020 boundries, but this file is smaller in memory.
road.map <- readOGR("maps/tl_2020_41_all/tl_2020_41_prisecroads.shp")

# convert spatial object to a ggplot ready data frame
state.map.df <- tidy(state.map)
county.map.df <- tidy(county.map)
road.map.df <- tidy(road.map)

zip.map@data$id <- rownames(zip.map@data)
dta$ZCTA <- as.character(dta$ZCTA)
zip.map@data <- left_join(zip.map@data, dta, by=c("ZCTA5CE10"="ZCTA"))
zip.map.df <- tidy(zip.map)
# join the attribute table from the spatial object to the new data frame
zip.map.df <- left_join(zip.map.df,zip.map@data,by = "id")


###
# Plot the maps
###

# Blank ZCTA Map
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df, aes(long, lat, group = group, fill = T), colour = alpha("#007030", 1/2), linewidth = 0.1) 
p <- p + scale_fill_manual(values = c("#FEE11A")) 
p <- p + theme(legend.position="none")
p <- p + coord_sf()
p


# Blank ZCTA Map w/ Counties
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df, aes(long, lat, group = group, fill = T), colour = alpha("#007030", 1/2), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual(values = c("#FEE11A")) 
p <- p + theme(legend.position="none")
p <- p + coord_sf()
p

# Blank ZCTA Map w/ Counties where POP_YOUTH_TOTAL > 0
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 0,], aes(long, lat, group = group, fill = T), colour = alpha("#007030", 1/2), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual(values = c("#FEE11A")) 
p <- p + theme(legend.position="none")
p <- p + coord_sf()
p
gc()
p


# Population Map
gc()
p <- ggplot()
p <- p + theme_bw()
p <- p + geom_polygon(data=zip.map.df, aes(long, lat, group = group, fill = UO_YOUTH_RATIO > median(dta$UO_YOUTH_RATIO)), colour = alpha("darkred", 1/2), linewidth = 0.1) 
p <- p + geom_polygon(data=state.map.df, aes(long, lat, group = group), colour = alpha("black", 1/2), linewidth = 0.5, fill=NA) 
#p <- p + scale_fill_manual(values = c("skyblue", "white")) 
p <- p+ theme(legend.position="none")
p <- p + coord_sf()
p

# UO Youth Ratio Quartiles 
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 0,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Quartile (1=Green=Bad; 4=Yellow=Good)", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt



# UO Youth Ratio Quartiles - Willammette
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 0,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
#p <- p + geom_path(data=road.map.df, aes(long, lat, group = group), colour = alpha("#0070FF", 0.75), linewidth = 0.05) 
p <- p + scale_fill_manual("Quartile (1=Green=Bad; 4=Yellow=Good)", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf(xlim = c(-124.25, -122.0), ylim=c(43.5, 46.5))
p
gc()
Sys.time() - tt

# UO Youth Ratio Quartiles - Portland Metro
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 0,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 0.75), linewidth = 0.25, fill=NA) 
p <- p + geom_path(data=road.map.df, aes(long, lat, group = group), colour = alpha("#555555", 0.75), linewidth = 0.05) 
p <- p + scale_fill_manual("Quartile (1=Green=Bad; 4=Yellow=Good)", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf(xlim = c(-123.5, -122.2), ylim=c(45, 45.8))
p
gc()
Sys.time() - tt

# 

# UO Youth Ratio Quartiles -- More than 100 Youth in ZCTA 
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Quartile (1=Green=Bad; 4=Yellow=Good)", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt

# UO Youth Ratio Quartiles -- More than 100 Youth in ZCTA -- Bottom two quartiles
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES <= 2,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Lowest Two Quartiles", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt

# UO Youth Ratio Quartiles -- More than 100 Youth in ZCTA -- Bottom two quartiles -- Willammette
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES <= 2,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Lowest Two Quartiles", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf(xlim = c(-124.25, -122.0), ylim=c(43.5, 46.5))
p
gc()
Sys.time() - tt

# UO Youth Ratio Quartiles -- More than 100 Youth in ZCTA -- Bottom two quartiles -- Portland
tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES <= 2,], aes(long, lat, group = group, fill = as.factor(UO_YOUTH_RATIO_QUARTILES)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Lowest Two Quartiles", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + theme(legend.position="bottom")
p <- p + coord_sf(xlim = c(-123.5, -122.2), ylim=c(45, 45.8))
p
gc()
Sys.time() - tt




# UO Youth Ratio Quartiles -- More than 100 Youth in ZCTA
## Race Dynamics
top_zips <- dta[dta$POP_YOUTH_TOTAL>100 & dta$UO_YOUTH_RATIO_QUARTILES >= 3,]
btm_zips <- dta[dta$POP_YOUTH_TOTAL>100 & dta$UO_YOUTH_RATIO_QUARTILES < 3,]
sum(top_zips$WHT_YOUTH_TOTAL) / sum(top_zips$POP_YOUTH_TOTAL)
sum(btm_zips$WHT_YOUTH_TOTAL) / sum(btm_zips$POP_YOUTH_TOTAL)


tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES <= 2,], aes(long, lat, group = group, fill = POC_YOUTH_RATIO), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
#p <- p + scale_fill_manual("Quartile (1=Green=Bad; 4=Yellow=Good)", values = c(alpha("#007030", 1), alpha("#007030", 0.5), alpha("#FEE11A", 0.5), alpha("#FEE11A", 1))) 
p <- p + scale_fill_viridis_c("Youth of color (as a % of all youth) in 2020",labels = scales::percent_format(accuracy=1))
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt


# Very Few Dean's List Student 

tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES <= 1,], aes(long, lat, group = group, fill = as.factor(UO_STUDENTS)), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
p <- p + scale_fill_manual("Number of students on Dean's List in last decade", values = c(alpha("#007030", 1), alpha("#7FA925", 1), alpha("#FEE11A", 1))) 
#p <- p + scale_fill_viridis_c("Teens (15-17) of Color in 2020",labels = scales::percent_format(accuracy=1))
p <- p + geom_text(data=zip.map@data[zip.map@data$POP_YOUTH_TOTAL > 100 & zip.map@data$UO_YOUTH_RATIO_QUARTILES <= 1,], aes(label = CITY, x = as.numeric(INTPTLON10), y = as.numeric(INTPTLAT10)), position = position_dodge(width = 1), vjust = -0.7, hjust= -0.25, size = 2)
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt


write.csv(dta[dta$POP_YOUTH_TOTAL > 100 & dta$UO_YOUTH_RATIO_QUARTILES<=1, c(1,2,15,4,18)], "clipboard")




# Lots of Dean's List Student 

tt <- Sys.time()
gc()
p <- ggplot()
p <- p + theme_void()
p <- p + geom_polygon(data=zip.map.df[zip.map.df$POP_YOUTH_TOTAL > 100 & zip.map.df$UO_YOUTH_RATIO_QUARTILES >= 4 & zip.map.df$CITY != "Eugene",], aes(long, lat, group = group, fill = UO_YOUTH_RATIO), colour = alpha("#007030", 1/4), linewidth = 0.1) 
p <- p + geom_polygon(data=county.map.df, aes(long, lat, group = group), colour = alpha("#007030", 1/3), linewidth = 0.25, fill=NA) 
#p <- p + scale_fill_manual("Number of students on Dean's List in last decade", values = c(alpha("#007030", 1), alpha("#7FA925", 1), alpha("#FEE11A", 1))) 
#p <- p + scale_fill_viridis_c("Teens (15-17) of Color in 2020",labels = scales::percent_format(accuracy=1))
#p <- p + geom_text(data=zip.map@data[zip.map@data$POP_YOUTH_TOTAL > 100 & zip.map@data$UO_YOUTH_RATIO_QUARTILES <= 1,], aes(label = CITY, x = as.numeric(INTPTLON10), y = as.numeric(INTPTLAT10)), position = position_dodge(width = 1), vjust = -0.7, hjust= -0.25, size = 2)
p <- p + theme(legend.position="bottom")
p <- p + coord_sf()
p
gc()
Sys.time() - tt


write.csv(dta[dta$POP_YOUTH_TOTAL > 100 & dta$UO_YOUTH_RATIO_QUARTILES<=1, c(1,2,15,4,18)], "clipboard")
