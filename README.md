# Geoscripting2019-FinalProject-R-mateys

## Reproducability
If you do not have the libcurl4-openssl-dev libraries installed on Linux, you need to install this from the cmdline:
```
sudo apt-get update
sudo apt-get install curl
sudo apt-get install libcurl4-openssl-dev
```
For optimal visualization: 
After clicking runn app in Rstudio, if top right corner 'pollution image' doesn't load, press 'open in browser'.

## Live action map of noise pollution by airplanes
Running main.R launches a shiny app that:
- Displays airplanes around which a buffer denotes a certain dB level
- Displays the area within the current extent affected by a certain level of noise pollution
- Allows for scrolling to other locations
- Allows for jumping to other locations using a geolocation search bar

## Code structure
The three core packages making up the code are Shiny (for implementing interaction and live updating), Leaflet (for displaying interactive maps), and sf (for calculating buffers)
The code is structured accoring to the MVC framework
- Main.R handles the control through the server side of the shiny app
- scripts/ui.R handles the view through the ui side of the shiny app
- scripts/* handle the model; these .R and .js files are thematically categorized and contain the functions and variables needed in the server (main.R) and ui (scripts/ui.R) to calculate and represent the geographic information.

### polygon_operations.R
Creates polygons in which the level of noise pollution is in a certain decibel range. The polygon is formed by first calculating the shortest distance to some cut-off decibel value using the formula (1):
```
r = 10^((Lsource - Lcut_off - 11) / 20)    (meters)
```
r being the distance to the cut-off point
Lsource being the loudness (dB) at the source (airplane, currently set at 144dB)
Lcut_off being the cut-off loudness (dB) at the isometric loudness line.

Second, bufffers with radius 'r' are formed around the points.
Since addition of two equal decibel levels increases the total decibel level by only 3dB, polygons are not added; instead, if polygons overlap, the highest dB polygon is displayed. This is the best approximation since the dB attribute is distributed with an exponential decrease from one to another isometric dB line, thus the mean will be closer to the lower- than the higher isometric value. Thus adding up the means of the buffers in between the lines will never exceed the range of the buffer (this range is 5 dB).
Finally all buffers of the same dB value are aggregated to be displayed on the map as multipolygons

## References
1: Lamancusa, J. S. (2000). Noise control. *Penn State*, 12(4).
