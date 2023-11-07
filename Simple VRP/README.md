[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gist/hollemawoolpert/612b51f5a489d276a4240f298a3cc9ed/master)

## Simple VRP with Google Developer Resources¶
Demonstrates a solution for the simple multi-vehicle routing problem (VRP) using a combination of Google libraries and services.
Sample depot and shipment locations randomly chosen in the San Antonio, TX metro area.  Distances and times are based on Google's road network.

### Getting Started
You will need a [Google Maps Platform API Key.](https://developers.google.com/maps/gmp-get-started)

#### Run on binder
- [Binder notebook](https://mybinder.org/v2/gist/hollemawoolpert/612b51f5a489d276a4240f298a3cc9ed/master)

#### Run locally
- [Git fork/clone or download gist](https://help.github.com/en/articles/forking-and-cloning-gists)

##### Prerequisites
* Python 3 environment
* JupyterLab
```
pip install jupyterlab
```

##### Installation
```
pip install -r requirements.txt
jupyter nbextension enable --py --sys-prefix gmaps
```
##### Run notebook
```
jupyter notebook
```

### Libraries and Services

* [Google OR-Tools](https://developers.google.com/optimization/routing/vrp)
* [Google Maps Platform Distance Matrix API](https://developers.google.com/maps/documentation/distance-matrix/start)