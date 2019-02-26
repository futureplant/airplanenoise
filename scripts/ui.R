# teamname: R-Mateys
# exercise final-project
# date 30-01-2019

###############################################################################################################
## UI module that sets up user interface for Shiny app                                                        #
###############################################################################################################

library(shinydashboard)
library(shiny)

###############################################################################################################


# Construct the UI argument for the call to the Shiny App in the main.R script
ui <- dashboardPage(
  dashboardHeader(title = "Noise Pollution"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    fluidRow(column(width = 9,
                    box(width = NULL, solidHeader = TRUE,      #  This constructs a space for the map 
                        leafletOutput("map", height = 500)),
                    box(width = NULL,                          #  This constructs a space for the table
                        uiOutput("pollutedAreaTable")
                    )
              ),
             
             column(width = 3,
                    
                    # Construct box with image and introductory text for the app
                    box(HTML("<img src='https://cdn1.iconfinder.com/data/icons/pollution-solid/100/Pollution_solid-15-512.png' alt='Pollution image' width='100%' height='100%'>
                            <br/ ><br/ ><strong>Live aviation noise pollution</strong><br/>
                            <p align='justify'>Welcome to this live map. To the left you can see a live
                             rendering of airplanes that are currently in the air.
                             Underneath this map, a dynamic table shows the size 
                             of the areas which are currently affected by the different
                             noise levels. Hover over airplane icons to see their callsign,
                             click on airplanes in order to see their current velocity
                             and altitude.<br/ ><br/ ></p>"), width = NULL, solidHeader = TRUE
                        ),
                    
                    # Construct box with input section that allows user to set refresh interval
                    box(width = NULL, status = "warning",
                        selectInput("interval", "Refresh interval",
                                    choices = c(
                                      "5 seconds" = 6,
                                      "10 seconds" = 10,
                                      "30 seconds" = 30
                                    ),
                                    selected = "10"
                        ))
                    )
             )
    )
  )


