import pandas as pd
import geopandas as gpd
import folium
from folium import plugins
import os
from geopy.geocoders import MapBox
import matplotlib.pyplot as plt
from r5r import MapboxRouter

# Set up the Mapbox geocoder
mapbox_api_key = "YOUR_MAPBOX_API_KEY"
geolocator = MapBox(api_key=mapbox_api_key)

# Load address data from CSV
addresses = pd.read_csv("data/utco.csv")
addresses = addresses.rename(columns={"Address": "address", "boxes": "boxes", "notes": "notes"})

# Geocode the addresses using the Mapbox API
def geocode_address(row):
    location = geolocator.geocode(row["address"])
    return pd.Series({"lat": location.latitude, "lon": location.longitude})

addresses[["lat", "lon"]] = addresses.apply(geocode_address, axis=1)

# Clustering
# You can use the sklearn library for clustering in Python, e.g., KMeans.

# Routes
# Create a function to calculate the optimized route
def myrouter(df):
    if len(df) <= 1:
        print("Cannot generate TSP solution for one point")
    elif len(df) > 12:
        print("Cannot generate solution for more than 12 points")
    else:
        router = MapboxRouter(api_key=mapbox_api_key)
        route = router.optimize_route(df, profile="driving")
        return route

# Group addresses by cluster and calculate routes
clusters = addresses.groupby("cluster")
routes = []

for cluster_id, group in clusters:
    route = myrouter(group[["lat", "lon"]])
    if route is not None:
        routes.append(route)

# You can save routes or visualize them as needed.

# Visualize routes using folium
m = folium.Map(location=[addresses["lat"].mean(), addresses["lon"].mean()], zoom_start=12)
for route in routes:
    waypoints = route["waypoints"]
    for i, waypoint in enumerate(waypoints):
        folium.CircleMarker(
            location=[waypoint["location"][1], waypoint["location"][0]],
            radius=5,
            color="red",
            fill=True,
            fill_color="red",
            fill_opacity=1,
            popup=f"Waypoint {i+1}"
        ).add_to(m)

# You can also add additional features and customize the map as needed.
m.save(os.path.join("output", f"{REGION}_map.html"))
