library(tidyverse)

#' Equal-sized k-means
#' 
#' 
#' @param x numeric matrix of data, or an object that can be coerced to such a
#'   matrix (such as a numeric vector or a data frame with all numeric columns).
#' @param iterations Number of iterations to alternate
#' @param k number of groups to create
#' @param ... further arguments to kmeans()
#' 
#' @details This is an implementation of the equal-sized k-means algorithm published
#'   at https://rviews.rstudio.com/2019/06/13/equal-size-kmeans/
equiKmeans <- function(x, loops, centers) {
  
  NewCenters <- NULL 
  
  for (l in 1:loops) {
    
    # initial kmeans
    if (is.null(NewCenters)) {
      x %>% kmeans(centers = centers, iter.max = 10) -> kclust
      centers = NULL
    } else {
      x %>% kmeans(centers = NewCenters, iter.max = 10)
    }
    
    # compute distance between each center and all points
    kc <- kclust$centers 
    k <- nrow(kc)
    distances <- lapply(1:k, function(i){
      as.matrix(dist(rbind(kc[i, ], x)))[, 1][-1]
    }) %>%
      set_names(str_c("D", 1:k)) %>%
      bind_cols()
    
    # append distances to dataframe
    working <- x %>% bind_cols(distances) %>%
      mutate(assigned = 0, index = 1:n())
    
    kdat <- x %>%
      mutate(assigned = 0, index = 1:n())
    
    FirstRound = nrow(kdat) - (nrow(kdat) %% k) 
    
    # Greedy cluster assignment
    # loop through the points an even number of times
    for(i in 1:FirstRound){ 
      
      #cluster counts can be off by 1 due to uneven multiples of k. 
      j = if(i %% k == 0) k else (i %% k)
      
      # identify the row of the working dataset with the smallest distance
      itemloc = working$index[ 
        which(working[,(paste0("D", j))] == 
                min(working[,(paste0("D",j))]))[1]]
      
      kdat$assigned[kdat$index == itemloc] = j
      
      # remove that row from the working table
      working %<>% filter(!index == itemloc)
      ##The sorting hat says... GRYFFINDOR!!! 
    }
    
    # allocate leftover points to clusters
    if(nrow(working) >= 1){
      for(i in 1:nrow(working)){
        #these leftover points get assigned to whoever's closest, without regard to k
        kdat$assigned[kdat$index ==
                        working$index[i]] = 
          which(working[i,3:5] == min(working[i, 3:5])) 
      }
    }
    
    # Create new centers as means of adjusted cluster memberships
    NewCenters <- kdat %>%
      select(-index)  %>%
      group_by(assigned) %>%
      summarise(across(.cols = everything(), mean)) %>%
      select(-assigned) %>% as.matrix()
  }
  
  list("data" = kdat, "centers" = NewCenters, "kclust" = kclust)
  
}



