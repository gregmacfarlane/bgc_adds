import pandas as pd
import geopandas as gpd
import folium
from folium.plugins import FastMarkerCluster

# Read address data from the CSV file
addresses = pd.read_csv("data/stgeorge.csv")

# Geocode the addresses using Mapbox API
from mapboxapi import MapboxAPI

api_key = "your_mapbox_api_key"
mb = MapboxAPI(api_key)

def geocode_address(address):
    result = mb.geocode(address)
    if result is not None:
        return result['geometry']['coordinates']
    return None

addresses['latlon'] = addresses['address'].apply(geocode_address)
addresses[['lon', 'lat']] = pd.DataFrame(addresses['latlon'].tolist(), columns=['lon', 'lat'])

# Clustering using K-Means
from sklearn.cluster import KMeans

kmeans = KMeans(n_clusters=2)  # Set the desired number of clusters
addresses['cluster'] = kmeans.fit_predict(addresses[['lon', 'lat']])

# Create a GeoDataFrame for visualization
gdf = gpd.GeoDataFrame(addresses, geometry=gpd.points_from_xy(addresses.lon, addresses.lat))

# Create a Folium map with cluster markers
m = folium.Map(location=[gdf['lat'].mean(), gdf['lon'].mean()], zoom_start=12)
marker_cluster = FastMarkerCluster(data=list(zip(gdf['lat'], gdf['lon'])))
marker_cluster.add_to(m)

# Routes
# Define a function to optimize routes using Mapbox API
from mapboxapi import MapboxOptimizedRoute

def optimize_route(coordinates):
    route = MapboxOptimizedRoute(api_key)
    result = route
