import pandas as pd
import numpy as np
from sklearn.cluster import KMeans

def equiKmeans(x, loops, centers, **kwargs):
    """
    This is an implementation of the equal-sized k-means algorithm    
    Parameters:
        x (matrix): such as a numeric vector or a data frame with all numeric columns
        loops (int): Number of iterations to alternate
        center (int): number of groups to create

    Returns:
        : 
    """
    NewCenters = None
    
    for l in range(1, loops + 1):
        # Initial k-means
        if NewCenters is None:
            kclust = KMeans(n_clusters=centers, max_iter=10, **kwargs).fit(x)
            centers = None
        else:
            kclust = KMeans(n_clusters=NewCenters.shape[0], init=NewCenters, max_iter=10, **kwargs).fit(x)
        
        # Compute distance between each center and all points
        kc = kclust.cluster_centers_
        k = kc.shape[0]
        distances = np.zeros((x.shape[0], k))
        
        for i in range(k):
            distances[:, i] = np.linalg.norm(x - kc[i], axis=1)[1:]
        
        distances_df = pd.DataFrame(distances, columns=[f'D{i+1}' for i in range(k)])
        x_with_distances = pd.concat([pd.DataFrame(x), distances_df], axis=1)
        x_with_distances['assigned'] = 0
        x_with_distances['index'] = range(1, x.shape[0] + 1)
        kdat = x_with_distances.copy()
        FirstRound = x.shape[0] - (x.shape[0] % k)
        
        # Greedy cluster assignment
        for i in range(1, FirstRound + 1):
            j = k if i % k == 0 else i % k
            itemloc = x_with_distances['index'][
                x_with_distances[f'D{j}'] == x_with_distances[f'D{j}'].min()].iloc[0]
            kdat.loc[kdat['index'] == itemloc, 'assigned'] = j
            x_with_distances = x_with_distances[x_with_distances['index'] != itemloc]
        
        # Allocate leftover points to clusters
        if len(x_with_distances) >= 1:
            for i in range(len(x_with_distances)):
                k = np.argmin(x_with_distances.iloc[i, 2:2+k])
                kdat.loc[kdat['index'] == x_with_distances.iloc[i, 1], 'assigned'] = k
        
        # Create new centers as means of adjusted cluster memberships
        NewCenters = kdat.drop(columns=['index', 'assigned']).groupby('assigned').mean().values

    return {"data": kdat, "centers": NewCenters, "kclust": kclust}
