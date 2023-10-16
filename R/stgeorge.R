library(tidyverse) # everything
library(magrittr)
library(ggpubr)
library(sf) # everywhere
library(leaflet) # all at once
library(ggspatial)

# geocoding through mapbox
library(mapboxapi)

# equilibrated k-means
source("R/equiKmeans.R")

# distance and routefinding through r5r
options(java.parameters = '-Xmx8G')
library(r5r)


# region
REGION = "st_george"

## Addresses ============
## We will use the Mapbox API to geolocate the addresses in the CSV
## 
## 
# read address data from Kennedy
# Row 1 is deer creek dam, which is the origin point for the salesmen
addresses <- read_csv("data/stgeorge.csv") %>%
  transmute(id = 1:n(), address = address, boxes)


# helper functions to get the lat / long from a list into two columns
first <- function(x){x[[1]]}
secnd <- function(x){x[[2]]}

# geocode the addresses using the mapbox API
addresses <- addresses %>%
  mutate(
    latlon = map(address, mb_geocode),
    lon = map_dbl(latlon, first),
    lat = map_dbl(latlon, secnd),
  ) 

## Clustering ==================
# equal-sized k-means cluster assignment
ek <- equiKmeans(addresses %>% select(c(lon, lat)), loops = 10, centers = 2)
addresses$cluster <- ek$data$assigned
addresses$kcluster <- ek$kclust$cluster


pal <- colorFactor("Dark2", addresses$cluster)

leaflet(addresses) %>%
  addProviderTiles(providers$Esri.WorldGrayCanvas) %>%
  addCircleMarkers(color = ~pal(kcluster))

# Routes =================

# use the optimized-route infrastructure in mapbox
myrouter <- function(df){
  if (nrow(df) <= 1) {
    message("Cannot generate TSP solution for one point")
  } else if (nrow(df) > 12) {
    message("Cannot generate solution for more than 12 points") 
  } else {
    mb_optimized_route(st_as_sf(df), profile = "driving")
  }
}

routes <- addresses %>%
  group_by(cluster) %>%
  nest()  %>%
  mutate(
    data = map(data, st_as_sf, coords = c("lon", "lat"), crs = 4326),
    route = map(data, myrouter)
  )

lapply(1:nrow(routes), function(i){
  
  # cluster id, address list, and route
  c <- routes$cluster[i]
  a <- routes$data[[i]]
  r <- routes$route[[i]]
  
  # order addresses based on route
  a$idx <- 1:nrow(a)
  alist <- a[order(match(a$idx, r$waypoints$waypoint_index)), "address"] %>%
    st_set_geometry(NULL)  %>%
    pull(address)
  # of Boxes
  addr <- paste(str_c(1: length(alist), ": ",  alist, " | ", a$boxes, " boxes"),
                collapse = "\n")
  tg <-   text_grob(addr, just = "left") 
  
  p <- ggplot() +
    annotation_map_tile("cartolight", zoom = 12) +
    geom_sf(data = r$route, color = "red") +
    geom_sf_label(data = r$waypoints, aes(label = waypoint_index ))
  
  
  tgp <- as_ggplot(tg)
  
  all <- grid.arrange(p, tgp)
  
  ggsave(file.path("output", str_c(REGION, "_", c, "_", "map.png")), all,
         width = 8.5, height = 11, units = "in")
})

  
