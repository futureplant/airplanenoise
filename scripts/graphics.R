# teamname: R-Mateys
# exercise final-project
# date 30-01-2019

###############################################################################################################
## graphics module sets color values for the isometric decibel polygons & creates a rotatable airplane marker #
###############################################################################################################

library(htmltools)
library(htmlwidgets)
library(RColorBrewer)

###############################################################################################################

# Values for isometric lines that define the decibel levels around planes
isoLinesDBvalues <- c(45,50,55,60,65,70,75)

# Mapping of colors to isometric DB values
factpal <- colorFactor(brewer.pal(length(isoLinesDBvalues), "YlOrRd"), isoLinesDBvalues)

# Loads .js script into object
rotatedMarker <- htmlDependency(
  "Leaflet.rotatedMarker",
  "0.1.2",
  src = normalizePath("."),
  script = "./scripts/leaflet.rotatedMarker.js"
)

# Makes .js script known to leaflet map
registerPlugin <- function(map, plugin) {
  map$dependencies <- c(map$dependencies, list(plugin))
  map
}

# Icon source: https://gist.github.com/jcheng5/c084a59717f18e947a17955007dc5f92
planeicon <- icons(
  iconUrl =  "./icons/airplane.svg",
  iconWidth = 19, iconHeight = 52, 
  iconAnchorX = 9.5, iconAnchorY = 26
)
