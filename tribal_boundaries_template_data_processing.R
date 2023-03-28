# Pre-process data for use in Shiny app

# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(here)
# library(mapview)
# library(readxl)
library(janitor)
library(httr)
library(esri2sf) # install using remotes::install_github("yonghah/esri2sf"); for more info see: https://github.com/yonghah/esri2sf 
library(tigris)

## conflicts ----
library(conflicted)
conflicts_prefer(dplyr::filter)



# CA boundary -------------------------------------------------------------
## get CA boundary ----
ca_boundary <- states(year = 2020, 
                      cb = TRUE) %>% # use cb = TRUE to get the cartographic boundary file
    filter(STUSPS == 'CA') %>%
    st_transform(3310)

## write CA boundary ----
st_write(ca_boundary, 
         here('data_processed', 
              'ca_boundary.gpkg'), 
         append = FALSE)



# tribal boundaries -------------------------------------------------------
## from Bureau of Indian Affairs - see: https://biamaps.doi.gov/bogs/datadownload.html

## get boundaries (all US) ----
tribal_bounds_bia <- esri2sf(
    url = 'https://biamaps.doi.gov/server/rest/services/DivLTR/BIA_AIAN_National_LAR/MapServer/0',
    crs = NULL) %>%
    rename(geom = geoms) %>% 
    clean_names()
st_crs(tribal_bounds_bia)
tribal_bounds_bia <- tribal_bounds_bia %>% 
    st_transform(3310)

## filter for tribal areas in CA ----
tribal_bounds_bia <- tribal_bounds_bia %>%
    st_filter(ca_boundary)

## write tribal boundaries ----
st_write(tribal_bounds_bia,
         here('data_processed', 
              'ca_tribal_boundaries_bia.gpkg'), 
         append = FALSE)

