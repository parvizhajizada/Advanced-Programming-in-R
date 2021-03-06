# Load necessary packages
library(readxl)
library(readr)
library(dplyr)
library(ggplot2)
library(dtwclust)
library(TSclust)
library(rgl)
library(dplyr)
library(knitr)
library(gclus)
library(fpc)
library(cluster)
library(vegan)
library(mclust)
library(clue)
library(lpSolve)
library(knitr)
library(factoextra)
library(NbClust)
library(testit)
library(purrr)

## Function 1
clusterr <- function(origin, destination) {

  # upload the data
  data <- read_excel("Seasonality - Data sample (tidied).xlsx") 
  
  # Check class of variables 
  if (!is.numeric(data$Total_Revenue) || data$Total_Revenue < 1) 
    stop("Total_Revenue should be a positive number!")
  
  if (!is.numeric(data$Traffic) || data$Traffic < 1) 
    stop("Traffic should be a positive number!")
 
  if (!is.numeric(data$Average_Revenue) || data$Average_Revenue < 1) 
    stop("Average_Renenue should be a positive number!")
  
  if (!is.numeric(data$Capacity) || data$Capacity < 1) 
    stop("Capacity should be a positive number!")
  
  # make a list of categorical variables
  facts <- c("Date", "Origin", "Destination")
  
  # factorize the categorical variables
  data[facts] <- lapply(data[facts], factor)
  
  # make a list of continuous variables
  nums <- c('Traffic', 'Total_Revenue' ,'Average_Revenue', 'Capacity')
  
  # make integer out of continuous variables
  data[nums] <- lapply(data[nums], as.integer)
  
  # choose the origin and destination
  data <- data %>% 
    filter(Origin == origin, Destination == destination)
  
  # EDA 
  str(data[nums]) %>%
    print()
  summary(data[nums]) %>% 
    print()
  
  # Visualizations
  # Print the plot to a pdf and a png file
  pdf("plot1.pdf")
  plot1 <- ggplot(data, aes(Date, Traffic)) + 
    geom_bar(stat = "identity")
  print(plot1)
  dev.off()
  
  png("plot1.png")
  plot1 <- ggplot(data, aes(Date, Traffic)) + 
    geom_bar(stat = "identity")
  print(plot1)
  dev.off()
  
  # scale the numerical variables
  scaled <- data[nums] %>% scale() 
  
  # Hopkins statistic (to check how clusterable a dataset is)
  hopkins_stat <- get_clust_tendency(data[nums], n = 51)$hopkins_stat
  paste('Hopkins statistic is equal to', hopkins_stat, ', if the value of Hopkins statistic is close to 1 (far above 0.5), then we can conclude that the dataset is significantly clusterable') %>% 
    print()

  # calculate gap statistics (for finding optimal number clusters)
  # PAM
  gap <- clusGap(scaled, FUNcluster = pam, K.max = 10, B = 50) 
  # CLARA
  gap2 <- clusGap(scaled, FUNcluster = clara, K.max = 10, B = 50) 
  # KMEANS 
  gap3 <- clusGap(scaled, FUNcluster = kmeans, K.max = 10, B = 50) 
  
  # calculate number of clusters
  # PAM
  K <- maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method="globalmax")
  invisible(K)
  # CLARA
  K2 <- maxSE(gap2$Tab[, "gap"], gap2$Tab[, "SE.sim"], method="globalmax")
  # KMEANS
  K3 <- maxSE(gap3$Tab[, "gap"], gap3$Tab[, "SE.sim"], method="globalmax")
  
  
  # find season of each week
  # PAM
  d <- pam(scaled, k = K, diss = FALSE, metric = 'euclidean', cluster.only = TRUE) %>%
    data.frame()
  # CLARA
  d2 <- clara(scaled, k = K2, metric = 'euclidean')$clustering %>%
    data.frame()
  # KMEANS
  d3 <- kmeans(scaled, centers = K3)$cluster %>%
    data.frame()
  
  # rename the columns
  # PAM
  names(d) <- "PAM"
  # CLARA
  names(d2) <- "CLARA"
  # KMEANS
  names(d3) <- "KMEANS"
  # assign the seasons to each week 
  cbind(data, d, d2, d3) %>% 
    print()
  
  # number of unique seasons
  # PAM
  nunique_pam <- d %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_pam, 'according to PAM method') %>%
    print()
  # CLARA
  nunique_clara <- d2 %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_clara, 'according to CLARA method') %>%
    print()
  # KMEANS
  nunique_kmeans <- d3 %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_kmeans, 'according to KMEANS method') %>%
    print()
  
  # number of unique seasons must be two or more 
  if (nunique_pam < 2 || nunique_clara < 2 || nunique_kmeans < 2) 
    message(paste("Number of unique seasons must be equal to two at least"))
}


# Example
clusterr(origin = 'LAX', destination = 'EWR')


# Function 2
`%clusterr%` <- function(origin, destination) {
  
  # upload the data
  data <- read_excel("Seasonality - Data sample (tidied).xlsx") 
  
  # Check class of variables 
  stopifnot(is.numeric(data$Total_Revenue) || data$Total_Revenue > 1) 
  message("Total_Revenue should be a positive number!")
  
  stopifnot(is.numeric(data$Traffic) || data$Traffic > 1) 
  message("Traffic should be a positive number!")
  
  stopifnot(is.numeric(data$Average_Revenue) || data$Average_Revenue > 1) 
  message("Average_Renenue should be a positive number!")
  
  stopifnot(is.numeric(data$Capacity) || data$Capacity > 1) 
  message("Capacity should be a positive number!")
  
  # make a list of categorical variables
  facts <- c("Date", "Origin", "Destination")
  
  # factorize the categorical variables
  data[facts] <- map(data[facts], factor)
  
  # make a list of continuous variables
  nums <- c('Traffic', 'Total_Revenue' ,'Average_Revenue', 'Capacity')
  
  # make integer out of continuous variables
  data[nums] <- map(data[nums], as.integer)
  
  # choose the origin and destination
  data <- data %>% 
    filter(Origin == origin, Destination == destination)
  
  # EDA 
  str(data[nums]) %>%
    print()
  summary(data[nums]) %>% 
    print()
  
  # Visualizations
  # Print the plot to a pdf and a png file
  ggplot(data, aes(x = Date, y = Traffic)) +
    geom_bar(stat = "identity")
  
  ggsave("plot2.pdf")
  ggsave("plot2.png")
  
  # scale the numerical variables
  scaled <- data[nums] %>% scale() 
  
  # Hopkins statistic (to check how clusterable a dataset is)
  hopkins_stat <- get_clust_tendency(data[nums], n = 51)$hopkins_stat
  paste('Hopkins statistic is equal to', hopkins_stat, ', if the value of Hopkins statistic is close to 1 (far above 0.5), then we can conclude that the dataset is significantly clusterable') %>% 
    print()
  
  # calculate gap statistics (for finding optimal number clusters)
  # PAM
  gap <- clusGap(scaled, FUNcluster = pam, K.max = 10, B = 50) 
  # CLARA
  gap2 <- clusGap(scaled, FUNcluster = clara, K.max = 10, B = 50) 
  # KMEANS 
  gap3 <- clusGap(scaled, FUNcluster = kmeans, K.max = 10, B = 50) 
  
  # calculate number of clusters
  # PAM
  K <- maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method="globalmax")
  invisible(K)
  # CLARA
  K2 <- maxSE(gap2$Tab[, "gap"], gap2$Tab[, "SE.sim"], method="globalmax")
  # KMEANS
  K3 <- maxSE(gap3$Tab[, "gap"], gap3$Tab[, "SE.sim"], method="globalmax")
  
  
  # find season of each week
  # PAM
  d <- pam(scaled, k = K, diss = FALSE, metric = 'euclidean', cluster.only = TRUE) %>%
    data.frame()
  # CLARA
  d2 <- clara(scaled, k = K2, metric = 'euclidean')$clustering %>%
    data.frame()
  # KMEANS
  d3 <- kmeans(scaled, centers = K3)$cluster %>%
    data.frame()
  
  # rename the columns
  # PAM
  names(d) <- "PAM"
  # CLARA
  names(d2) <- "CLARA"
  # KMEANS
  names(d3) <- "KMEANS"
  # assign the seasons to each week 
  cbind(data, d, d2, d3) %>% 
    print()
  
  # number of unique seasons
  # PAM
  nunique_pam <- d %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_pam, 'according to PAM method') %>%
    print()
  # CLARA
  nunique_clara <- d2 %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_clara, 'according to CLARA method') %>%
    print()
  # KMEANS
  nunique_kmeans <- d3 %>% table() %>% dim()
  paste('number of unique seasons is equal to', nunique_kmeans, 'according to KMEANS method') %>%
    print()
  
  # number of unique seasons must be two or more 
  assert("Number of unique seasons must be equal to two at least",
         (nunique_pam > 1 || nunique_clara > 1 || nunique_kmeans > 1)) 
}

# Example
'LAX' %clusterr% 'EWR'

