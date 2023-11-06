import pandas as pd
import geopandas as gpd
import folium
import folium.plugins
from mapbox import Geocoder

# Geocoding through Mapbox
from mapboxapi import MapboxAPI

# Equilibrated k-means
# The equiKmeans source file is assumed to be in the same directory as this Python script
from equiKmeans import equiKmeans

# Distance and routefinding through r5r
from r5r import R5r

# Region
REGION = "heber"
ROUTES = 4

# Addresses
# We will use the Mapbox API to geolocate the addresses in the CSV

# Read address data from "heber.csv"
# Row 1 is deer creek dam, which is the origin point for the salesmen
addresses = pd.read_csv("data/heber.csv")
addresses['address'] = addresses['address'] + ' ' + addresses['State']
addresses['boxes'] = addresses['boxes']

# Helper functions to get the latitude and longitude from a list into two columns
def first(x):
    return x[0]

def secnd(x):
    return x[1]

# Geocode the addresses using the Mapbox API
geocoder = Geocoder()
addresses['latlon'] = addresses['address'].apply(geocoder.geocode)
addresses['lon'] = addresses['latlon'].apply(lambda x: first(x) if x is not None else None)
addresses['lat'] = addresses['latlon'].apply(lambda x: secnd(x) if x is not None else None)

# Clustering
# Equal-sized k-means cluster assignment
ek = equiKmeans(addresses[['lon', 'lat']], loops=10, centers=ROUTES)
addresses['cluster'] = ek['data']['assigned']
addresses['kcluster'] = ek['kclust']['cluster']

# Create a color palette based on the cluster
address_color_palette = {i: 'Dark2_' + str(i % 8 + 1) for i in range(ROUTES)}
addresses['cluster_color'] = addresses['cluster'].map(address_color_palette)

# Create a map with Folium
m = folium.Map(location=[addresses['lat'].mean(), addresses['lon'].mean()], zoom_start=12)
for _, row in addresses.iterrows():
