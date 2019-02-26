# teamname: R-Mateys
# exercise final-project
# date 31-01-2019


###############################################################################################################
## Dependencies.R lists packages to install and provides functionality to check whether packages are installed#                                                 #
##    And installs + loads them.                                                                              #
###############################################################################################################
pkgs <- c('leaflet', 'RColorBrewer', 'lwgeom', 'sf', 'dplyr', 'curl', 'htmlwidgets',
          'htmltools', 'devtools', 'shinydashboard', 'shiny')

require_install <- function(pkgs){
  # Update packages to prevent conflicts, install unavailable packages and load packages
  update.packages(pkgs, character.only=TRUE)
  for (pkg in pkgs){
    if (!require(pkg, character.only=TRUE)){
      install.packages(pkg, character.only=TRUE)
      library(pkg, character.only = TRUE)
  update.packages(pkgs, character.only=TRUE)
    }
  }
}

