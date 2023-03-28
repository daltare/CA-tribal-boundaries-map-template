# Template for a Shiny application that contains a map showing Tribal 
# boundaries in California, from the Bureau of Indian Affairs' Land Area 
# Representations (LAR) dataset

## To deploy to shinyapps.io, include:
##      - this script 
##      - all of the files in the 'data_processed' folder 
## (no other files need to be published - e.g., don't need to publish the 
## 'data_raw' folder)


# load packages -----------------------------------------------------------
library(shiny)
library(shinyjs)
library(shinycssloaders)
library(shinyWidgets)
library(tidyverse)
library(sf)
library(leaflegend)
library(leaflet)
library(glue)
library(janitor)
library(here)
library(FedData)

## conflicts ----
library(conflicted)
conflicts_prefer(dplyr::filter)



# setup -------------------------------------------------------------------

## coordinate systems for transformations
projected_crs <- 3310 # see: https://epsg.io/3310 
# other options: 26910 see: https://epsg.io/26910
# resources: 
# https://nrm.dfg.ca.gov/FileHandler.ashx?DocumentID=109326&inline
# 
geographic_crs <- 4269 # see: https://epsg.io/4269
# see: https://epsg.io/4326



# load data ----------------------------------------------------------------

## tribal boundaries ----
tribal_bounds_bia <- st_read(here('data_processed', 
                                  'ca_tribal_boundaries_bia.gpkg'))

## CA boundary ----
ca_boundary <- st_read(here('data_processed', 
                            'ca_boundary.gpkg'))



# define UI ---------------------------------------------------------------
ui <- fillPage(
    leafletOutput('tribal_boundaries_map_render', height = "100%") %>% 
        # withSpinner(color="#0dc5c1") %>% # not working
        addSpinner(color = '#0dc5c1', 
                   spin = 'double-bounce' # 'fading-circle' 'rotating-plane'
        ) %>% 
        {.}
)



# Define server logic -----------------------------------------------------
server <- function(input, output) {
    
    ## create leaflet map ----
    output$tribal_boundaries_map_render <- renderLeaflet({
        
        ### create empty map ----
        tribal_boundaries_map <- leaflet()
        
        ### set initial zoom ----
        tribal_boundaries_map <- tribal_boundaries_map %>% 
            setView(lng = -119.5, # CA centroid: -119.5266
                    lat = 37.5, # CA centroid: 37.15246
                    zoom = 6) 
        
        ### add basemap options ----
        basemap_options <- c( # NOTE: use 'providers$' to see more options
            #'Stamen.TonerLite',
            'CartoDB.Positron',
            'Esri.WorldTopoMap', 
            # 'Esri.WorldGrayCanvas',
            'Esri.WorldImagery'#,
            # 'Esri.WorldStreetMap'
        ) 
        
        for (provider in basemap_options) {
            tribal_boundaries_map <- tribal_boundaries_map %>% 
                addProviderTiles(provider, 
                                 group = provider, 
                                 options = providerTileOptions(noWrap = TRUE))
        }
        
        ### add panes ----
        #### (sets the order in which layers are drawn/stacked -- higher 
        #### numbers appear on top)
        tribal_boundaries_map <- tribal_boundaries_map %>% 
            addMapPane('tribal_boundaries_pane', zIndex = 500) %>%
            addMapPane('ca_boundary_pane', zIndex = 510) %>% 
            {.}
        
        
        ### add legend for tribal boundaries ----
        tribal_boundaries_map <- tribal_boundaries_map %>% 
            addLegend(position = 'bottomright', 
                      colors = 'blueviolet',
                      labels = 'Tribal Area',
                      opacity = 1, 
                      layerId = 'tribal_areas_legend', 
                      group = 'Tribal Areas')
        
        
        ### add tribal boundaries ----
        tribal_boundaries_map <- tribal_boundaries_map %>%
            addPolygons(data = tribal_bounds_bia %>%
                            st_transform(crs = geographic_crs),
                        options = pathOptions(pane = "tribal_boundaries_pane"),
                        color = 'darkgrey', 
                        weight = 0.5,
                        smoothFactor = 1.0,
                        opacity = 0.8,
                        fillOpacity = 0.8, 
                        fillColor = 'blueviolet', 
                        highlightOptions = highlightOptions(color = "white", weight = 2), # fill = TRUE, fillColor = "white"),#,bringToFront = TRUE
                        popup = ~paste0('<b>', '<u>','Tribal Area', '</u>','</b>','<br/>',
                                        '<b>', 'Name: ', '</b>',  larname, '<br/>'#,
                                        # '<b>', 'Agency: ', '</b>', agency, '<br/>',
                        ),
                        group = 'Tribal Areas',
                        label = ~glue('Tribal Area ({larname})')
            )
        
        ### add CA boundary ----
        tribal_boundaries_map <- tribal_boundaries_map %>%
            addPolylines(data = ca_boundary %>% 
                             st_transform(crs = geographic_crs), # have to convert to geographic coordinate system for leaflet)
                         options = pathOptions(pane = 'ca_boundary_pane'),
                         color = 'black', 
                         weight = 1.0,
                         smoothFactor = 1.0,
                         opacity = 0.7,
                         group = 'CA Boundary',
                         label = 'CA Boundary') %>% 
            hideGroup('CA Boundary')
        
        
        ### add layer controls ----
        tribal_boundaries_map <- tribal_boundaries_map %>%
            addLayersControl(baseGroups = basemap_options,
                             overlayGroups = c(
                                 'Tribal Areas',
                                 'CA Boundary'
                             ),
                             options = layersControlOptions(collapsed = TRUE,
                                                            autoZIndex = TRUE))
    })
}


# run application  --------------------------------------------------------
shinyApp(ui = ui, server = server)
