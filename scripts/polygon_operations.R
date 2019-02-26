# teamname: R-Mateys
# exercise final-project
# date 30-01-2019

##########################################################################################################
## polygon_operations module creates polygons from airplane data in which the level of noise pollution   #
## is within a certain decibel range. (README.md for more documentation)                                 #
##########################################################################################################

library(sf)
library(dplyr)

##########################################################################################################

calc_bufferwidth <- function(height, planedB, isodB){
  # calculate buffer width of isometric dB circles
  # args:
  #       height:   Altitude of the plane
  #       planedB:  Decibel level produced by this plane (currently hardcoded)
  #       isodB:    Isometric decibel line value; the value of the circle where the decibel level = the value
  # Returns:
  #       integer:  radius of the circle representing the isometric decibel line 
  
  # Check for planes for which height data is missing
  if (is.na(height)){
    return(NA)
  }
  else {
    diag_d <- 10^((planedB - isodB - 11) / 20) # shortest distance to isometric dB line
  }
  
  if (diag_d < height){
    return(NA)
  }
  else {
    return(sqrt(diag_d^2 - height^2)) # radius of isometric dB circle
  }
}

get_bufferwidths <- function(buffer_data, isoDBvalues){
  # Loops over the isometric dB values to get bufferwidth for every plane, for all the isometric dB values
  # Args:
  #       buffer_data:    sf_df containing point geoms for planes + baro_altitude
  #       isoDBvalues:     vector containing the values for the isometric dB lines
  # Returns:
  #       buffers:        sf_df containing point geoms, baro_altitude, isometric dB values (Noise), and Bufferwidth
  
  planeDBvalue <- 144 # Estimated dB of a typical plane: https://sciencing.com/decibel-level-jet-plane-5375252.html
  for (i in 1:length(isoDBvalues)){
    buffer_data$Noise <- isoDBvalues[i]
    buffer_data$Bufferwidth <- mapply(calc_bufferwidth, buffer_data$baro_altitude, planeDBvalue, buffer_data$Noise)
    if (i == 1){
      df <- buffer_data
    }
    else{
      df <- rbind(df, buffer_data)  
    }
  }
  df$Bufferwidth <- units::set_units(df$Bufferwidth, m) # Set bufferwidth units to meters
  return(df)
}

make_buffers <- function(bufferwidth_df){
  # Create buffer polygons from bufferwidhts
  # Args:
  #       bufferwidth_df: sf_df containing a.o. points and width of the buffer around the point
  # Returns:
  #        buffers:        sf_df containing buffer polygons
  bufferwidth_RDnew <- st_transform(bufferwidth_df, 28992) # Transform to use bufferwidth specified in meters
  buffers_RDnew <- st_buffer(bufferwidth_RDnew, dist = bufferwidth_RDnew$Bufferwidth)
  buffers <- st_transform(buffers_RDnew, 4326)
  return(buffers_RDnew)
}


group_buffers <- function(buffers){
  # Dissolve buffers based on noise level
  # Args:
  #       buffers: sf_df containing buffer polygons and associated data
  # Output:
  #       grouped_buffers: sf_df with all buffers with same isoDB level dissolved
  grouped_buffers <- buffers %>%
    group_by(Noise) %>%
    summarize() # Dissolves buffers grouped by Noise
  return(grouped_buffers)
}

clip_buffers <- function(orderedbuffers, sf_df){
  # Recursively subtracts polygons from ordered sf_df containing k buffers in order: 
  # (1:(k-1) - k), (1:(k-2) - (k-1)), ... etc.
  # Args:
  #       orderedbuffers: sf_df containing ordered buffers; order should be increasing (top -> bottom)
  #       sf_df:          empty sf_df
  # Returns:
  #       sf_df:          sf_df containing non-overlapping multipolygons + Noise level attribute
  
  # Exit-clause for recursive function
  lastrow_i <- nrow(orderedbuffers)
  if (lastrow_i == 1){
    sf_df <- rbind(orderedbuffers, sf_df)
    return(sf_df)
  }
  # Recursively subtract high Noise polygons from low Noise polygons
  else{
    # Move last row from input sf_df to output sf_df
    lastrow <- orderedbuffers[lastrow_i,]
    orderedbuffers <- orderedbuffers[-lastrow_i,]
    sf_df <- rbind(lastrow, sf_df)
    # Clip lastrow polygon from all lower Noise value polygons
    st_agr(orderedbuffers) = "constant" # Suppress warning that attributes should be spaitally constant
    orderedbuffers <- st_difference(orderedbuffers, st_geometry(lastrow))
    clip_buffers(orderedbuffers, sf_df)
  }
}

completeFun <- function(data, desiredCols) {
  ## Function to remove NA rows when 1 of desiredCols ha NA
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}

create_polygons <- function(PlaneData, isoDBvalues){
  # Bundles all polygon operations in one function
  # Args:
  #       PlaneData:      sf_df containing points for plane location + all attributes from API
  #       isoDBvalues:    vector containing the dB levels at which the isometric dB lines should be drawn
  # Return:
  #       buffers:        sf_df containing 1 buffer per noise level + Noise attribute + area
  
  buffer_data <- PlaneData[c('geometry',
                        'baro_altitude',
                        'on_ground')]
  bufferwidth_df_NAs <- get_bufferwidths(buffer_data, isoDBvalues)
  bufferwidth_df <- bufferwidth_df_NAs[!is.na(bufferwidth_df_NAs$Bufferwidth),]
  buffers <- make_buffers(bufferwidth_df)
  grouped_buffers <- group_buffers(buffers)
  ordered_grouped_buffers <- grouped_buffers[order(grouped_buffers$Noise),]
  sf_df <- st_sf(st_sfc())
  st_crs(sf_df) <- 28992
  clipped_grouped_buffers <- clip_buffers(ordered_grouped_buffers, sf_df)
  clipped_grouped_buffers$area <- paste0(round(st_area(clipped_grouped_buffers)/1000000),"&ensp;km", tags$sup(2))
  buffers <- st_transform(clipped_grouped_buffers, 4326)
  return(buffers)
}
