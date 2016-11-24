# Parallel Code for foreach 
# Source Coude: https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf
# Comparing the parallel and non parallel programming elapsed time
# Tested in Windows 10 Desktop OS, R verison 3.2.3 
# It is also tested in Mac OSX Yosemite version


# First, we need to make sure that all required packages are installed 
# install packages: parallel, doParallel
install.packages("parallel")
install.packages("doParallel")

library(doParallel)
library(parallel)

# Detect 
no_cores <- detectCores() - 1
# For Windows, use this:
# cl <- makeCluster(3, type = "PSOCK")

# For UNIX (Ubuntu, MAC), use this command
cl <- makeCluster(3, type = "FORK")

# Register the parallel backend with the foreach package.
registerDoParallel(cl)

# Loading your data (Please check compatibility how to read data from Amazon EC2)
# iris <- read.csv("iris.csv")

# Assume iris has been loaded 

# 1 Using parallel programming to run glm training of iris dataset 
x <- iris[which(iris[,5] != "setosa"), c(1,5)]

# Set trial, we can play with this! If we want to have longer test, make it 1000000
trials <- 10000
ptime <- system.time({
  r <- foreach(icount(trials), .combine=cbind) %dopar% {
  ind <- sample(100, 100, replace=TRUE)
  result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
  coefficients(result1)
  }
  })[3]

# Function to stop cluster
stopCluster(cl)
ptime

# In Windows, the elapsed time  
# 23.25

# In Mac, the elapsed time
# 19.713

# Function to unreg the registration of parallel
unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
# optional command to unreg parallel backend with foreach package,
# because we want to run unparallel command. 
unregister()

# 2 Using non parallel programming to run glm training of iris dataset 
ptime_non <- system.time({
  r <- foreach(icount(trials), .combine=cbind) %do% {
    ind <- sample(100, 100, replace=TRUE)
    result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
    coefficients(result1)
  }
})[3]
ptime_non

# elapsed time in Windows
# 92.74 

# elapsed time in MAC, if getparworker still 3
# 36.661 

# elapsed time in MAC, if getparworker is 1
# 37.647 

# Conclusion: parallel programming will make the elapsed time faster than non parallel programming. 
# For bootstraping 