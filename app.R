# teamname: R-Mateys
# exercise final-project
# date 30-01-2019


###############################################################################################################
## Main.R sources all other scripts and executes the Shiny app                                                #
##    Since this app works with live data, the structure might take some getting used to.                     #
##    We provide an extended explanation in the Readme file.                                                  #
###############################################################################################################

# install libraries that are not yet installed
source("scripts/dependencies.R")
require_install(pkgs)
if (!require('leaflet.extras')) devtools::install_github('bhaskarvk/leaflet.extras')


# load packages
library(devtools)
library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)
library(lwgeom)

# source codes from scripts folder
source("scripts/ui.R")
source("scripts/graphics.R")
source("scripts/API_calls.R")
source("scripts/polygon_operations.R")

###############################################################################################################


# server serves information to the user interface that is constructed in scripts/ui.R file
server <- function(input, output, session) {
  
  # Render background map for shiny app
  output$map <- renderLeaflet({
    
    # Add default OpenStreetMap map tiles
    leaflet() %>% setView(lng = 4.8587, lat = 52.3739, zoom = 9) %>%  #  set view to start extent, area over Schiphol Airport   
      addTiles(options = providerTileOptions(minZoom = 7, maxZoom = 15)) %>% #  set min and max zoom level
      
      # Add search functionality to background map
      addSearchOSM(options = searchOptions(autoCollapse = TRUE,
                                           minLength = 2,
                                           zoom = 10,
                                           position = 'topright',
                                           hideMarkerOnCollapse = TRUE))
    })
  
  # Creates a reactive expression that will render all statements inside itself invalid after the refresh interval.
  # The same happens to all functions that are dependent on invalidata. As such, this is the 'master invalidation reactive expression'
  invalidata <- reactive({
    invalidateLater(as.numeric(input$interval)*1000, session) #  Renders all statements invalid and triggers a refresh after the interval as set in Shiny UI
    })
  
  
  # Calls getPlaneData from scripts/API_calls.R every time invalidata triggers re-execution
  planeData <- reactive({
    invalidata()
    if(is.null(input$map_bounds)) #  Sets initial extent for API plane request
      return(getPlaneData("lamin=51.000&lomin=3.000&lamax=53.000&lomax=7.000"))
    boundaries <- input$map_bounds #  Asks current boundaries from user interface
    
    # calls getPlaneData with the current extent map on the User Interface
    PlaneData <- getPlaneData(sprintf("lamin=%s&lomin=%s&lamax=%s&lomax=%s", 
                                      boundaries$south, boundaries$west, 
                                      boundaries$north, boundaries$east)) 
    })
  
  
  # Creates new polygons. Reactive expression that gets triggered by a parent reactive function (planeData())
  # i.e. if planeData() changes, the create_polygons will be re-executed 
  # polygons are constructed in scripts/polygon_operations.R
  polygonsReactive <- reactive({
    polygons <- create_polygons(planeData(), isoLinesDBvalues) #  polygons are constructed on the bases of plane data and noise levels
  })
  
  
  # The observer fires if one of the reactives becomes invalid and thereby ensures the dynamic elements 
  # on the map are re-drawn based on the new data
  observe({
    data = planeData()
    if (nrow(data) > 1) { #  This ensures we only start drawing polygons if there are planes present in the extent
      polygons <- polygonsReactive() #  load latest polygons in object polygons
      
      # Add dynamic elements to static background map
      leafletProxy("map", data = data) %>%     #  Tell leaflet proxy we are talking about our shiny output map and which data we are using
        registerPlugin(plugin = rotatedMarker ) %>% #  Register a javascript plugin to rotate plane orientation on map
        clearMarkers() %>% #  Removes previous markers
        
        # Adds the airplanes to the map 
        addMarkers( data = data
                    , label = data$callsign  #  Gives a label with the callsign to the plotted planes
                    
                    # Creates a popup with additional information if an airplane is clicked on the map
                    , popup = paste0("<strong>speed: </strong>", round(data$velocity * 3.6)," km/h", "<br/>",  
                                     "&nbsp&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>alt: </strong>", round(data$geo_altitude / 1000, digits = 1), " km" )
                    , icon = planeicon #  Loads icon that is constructed in scripts/graphics.R
                    
                    # Feeds rotation angle to registered plugin. This plugin calls a javascript file to take care of icon rotation
                    # i.e. ensuring that planes are facing the right way
                    , options = markerOptions(rotationAngle = ~true_track) 
                    ) %>%
        clearShapes() %>% #  Clears all the old shapes from the map and prepares for plotting updated planes and polygons
        
        # Adds the polygons that correspond with noise levels to the background map
        addPolygons(
          data = polygons
          , fill = "Noise"
          , stroke = FALSE
          , color = ~factpal(Noise)
          , fillOpacity = 0.5
          , smoothFactor = 0.5)
      }
    })
  
  
  # Construct the table with legend and area size of Noise pollution levels
  output$pollutedAreaTable <- renderUI({
    if (nrow(planeData()) > 1) { #  Don't draw if there are no planes in sight
      polygons <- polygonsReactive() #  load latest polygons in object polygons
      tags$table(class = "table",
                 tags$thead(tags$tr(  #  Define column names
                   tags$th(HTML("&emsp;&emsp;")), #  spacing column in order to improve outline of table
                   tags$th(HTML("<p>Color")),
                   tags$th(HTML("<p align='right'>Noise level")),
                   tags$th(HTML("<p align='right'>Area affected")),
                   tags$th(HTML("&emsp;&emsp;&emsp;&emsp;&emsp;"))
                 )),
                 tags$tbody( # Define rows of dynamic table
                   
                   #### table rows are defined below ####   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")), #  spacing column in order to improve outline of table
                     tags$td(span(style = sprintf( #  creates square icon with color corresponding to noise level on map
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(75)
                     ))),
                     tags$td(HTML("<p align='right'>  >  75 dB")),  #  creates label for noise level
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 75],"</p>")))), #  takes area from polygons data
                   
                   # above lines are repeated for all rows in table
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")), 
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(70)
                     ))),
                     tags$td((HTML("<p align='right'>70-75 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 70],"</p>")))),
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")), 
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(65)
                     ))),
                     tags$td((HTML("<p align='right'>65-70 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 65],"</p>")))),
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")),
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(60)
                     ))),
                     tags$td((HTML("<p align='right'>60-65 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 60],"</p>")))),
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")),
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(55)
                     ))),
                     tags$td((HTML("<p align='right'>55-60 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 55],"</p>")))),
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")),
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(50)
                     ))),
                     tags$td((HTML("<p align='right'>50-55 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 50],"</p>")))),
                   
                   tags$tr(
                     tags$th(HTML("&emsp;&emsp;")),
                     tags$td(span(style = sprintf(
                       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
                       factpal(45)
                     ))),
                     tags$td((HTML("<p align='right'>45-50 dB"))),
                     tags$td(HTML(paste0("<p align='right'>",polygons$area[polygons$Noise == 45],"</p>"))))
                   #### End of row definition ####
                   ))
      }
    })
  }

# Creates Shiny App object, using the above defined server and the user interface that can be found in scripts/ui.R
shinyApp(ui, server)
