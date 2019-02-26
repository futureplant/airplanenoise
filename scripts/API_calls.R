# teamname: R-Mateys
# exercise final-project
# date 30-01-2019

##########################################################################################################
## API_calls module loads airplane data from public API, checks data for completeness and casts to right #
## data types and column names.                                                                          #
##########################################################################################################

library(curl)
library(sf)

##########################################################################################################

PlaneDataColnames <- c('icao24','callsign','origin_country',
                       'time_position', 'last_contact', 'longitude',
                       'latitude', 'baro_altitude', 'on_ground',
                       'velocity', 'true_track', 'vertical_rate',
                       'sensors', 'geo_altitude', 'squawk',
                       'spi', 'position_source')


factor_to_numeric <- function(df, colname){
  # Changes column values from factor to numeric
  # Args:
  #       df:         Dataframe of wich column 'colname' is of class 'factor'
  #       colname:    Name of the column to be switched from 'factor' to 'numeric'
  # Returns:
  #       col         Dataframe column
  
  col <- as.numeric(levels(df[[colname]]))[df[[colname]]]
  return(col)
}

getPlaneData <- function(extent) {
  # Downloads plane data for extent and returns dataframe
  # Args:
  #       extent:     url specifying current bounding box formated according to: https://opensky-network.org/apidoc/rest.html
  # Returns:
  #       PlaneData:   data.frame containing all plane data of current extent. 
  #                       - Returns empty data.frame if no planes in sight (0 rows, 0 columns)
  #                       - Returns empty data.frame if no planes in air (0 rows, 17 columns)
  
  # Create URL by pasting credentials to extent
  url <- paste0("https://R-mateys:Microsoft-flightsim@opensky-network.org/api/states/all?", extent) 
  # Download data from REST API 
  PlaneData <- as.data.frame(jsonlite::fromJSON(url)$states)
  if (nrow(PlaneData) > 1){ #  Don't mutate data if data.frame is empty
    # Set column names as defined at: https://opensky-network.org/apidoc/rest.html
    colnames(PlaneData) <- PlaneDataColnames
    # Cast values from factor to numeric
    PlaneData$longitude <- factor_to_numeric(PlaneData, "longitude")
    PlaneData$latitude <- factor_to_numeric(PlaneData, "latitude")
    PlaneData$baro_altitude <- factor_to_numeric(PlaneData, "baro_altitude")
    PlaneData$geo_altitude <- factor_to_numeric(PlaneData, "geo_altitude")
    PlaneData$velocity <- factor_to_numeric(PlaneData, "velocity")
    # Filter airplanes that are on the ground
    PlaneData <- PlaneData[PlaneData$on_ground == FALSE,]
    PlaneData <- PlaneData[PlaneData$velocity > 15,]
    # Convert df to sf_df
    PlaneData <- st_as_sf(PlaneData, coords =c("longitude","latitude"), crs = 4326)
  }
  return(PlaneData)
}


