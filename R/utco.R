library(tidyverse) # everything
library(magrittr)
library(ggpubr)
library(gridExtra)
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
REGION = "utco"
ROUTES = 15

## Addresses ============
## We will use the Mapbox API to geolocate the addresses in the CSV
## 
## 
# read address data from Kennedy
addresses <- read_csv("data/utco.csv") %>%
  transmute(id = 1:n(), address = Address, boxes, notes)


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
ek <- equiKmeans(addresses %>% select(c(lon, lat)), 
                 loops = 10, centers = ROUTES)
addresses$cluster <- ek$data$assigned
addresses$kcluster <- ek$kclust$cluster


pal <- colorFactor("Dark2", addresses$cluster)

leaflet(addresses) %>%
  addProviderTiles(providers$Esri.WorldGrayCanvas) %>%
  addCircleMarkers(color = ~pal(cluster), label = ~as.character(address))

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
  
  if(!is.null(r)){
    
    
    # order addresses based on route
    a$idx <- 1:nrow(a)
    alist <- a[order(match(a$idx, r$waypoints$waypoint_index)), "address"] %>%
      st_set_geometry(NULL)  %>%
      pull(address)
    
    addr <- paste(str_c(1: length(alist), ": ",  alist, "| ", a$boxes, " boxes"),
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
    
  }
})


leaflet(routes$data[[3]]) %>%
  addProviderTiles(providers$Esri.WorldGrayCanvas) %>%
  addCircleMarkers()


try_again <- routes$data[[3]] %>%
  mutate(
    lon = map_dbl(latlon, first),
    lat = map_dbl(latlon, secnd),
  ) 

ek2 <- equiKmeans(try_again %>% st_set_geometry(NULL) %>% select(c(lon, lat)), 
                 loops = 10, centers = 3)
try_again$cluster <- ek2$data$assigned
try_again$kcluster <- ek2$kclust$cluster


pal <- colorFactor("Dark2", addresses$cluster)

leaflet(try_again) %>%
  addProviderTiles(providers$Esri.WorldGrayCanvas) %>%
  addCircleMarkers(color = ~pal(cluster), label = ~as.character(address))

routes2 <- try_again %>%
  group_by(cluster) %>%
  nest()  %>%
  mutate(
    data = map(data, st_as_sf, coords = c("lon", "lat"), crs = 4326),
    route = map(data, myrouter)
  )

lapply(1:nrow(routes2), function(i){
  
  # cluster id, address list, and route
  c <- routes2$cluster[i]
  a <- routes2$data[[i]]
  r <- routes2$route[[i]]
  
  if(!is.null(r)){
    
    
    # order addresses based on route
    a$idx <- 1:nrow(a)
    alist <- a[order(match(a$idx, r$waypoints$waypoint_index)), "address"] %>%
      st_set_geometry(NULL)  %>%
      pull(address)
    
    addr <- paste(str_c(1: length(alist), ": ",  alist, "| ", a$boxes, " boxes"),
                  collapse = "\n")
    tg <-   text_grob(addr, just = "left") 
    
    p <- ggplot() +
      annotation_map_tile("cartolight", zoom = 12) +
      geom_sf(data = r$route, color = "red") +
      geom_sf_label(data = r$waypoints, aes(label = waypoint_index ))
    
    
    tgp <- as_ggplot(tg)
    
    all <- grid.arrange(p, tgp)
    
    ggsave(file.path("output", str_c(REGION, "_2_", c, "_", "map.png")), all,
           width = 8.5, height = 11, units = "in")
    
  }
})

