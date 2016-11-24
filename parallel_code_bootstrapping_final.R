# Parallel Code for foreach 
# Source Coude: https://cran.r-project.org/web/packages/doParallel/vignettes/gettingstartedParallel.pdf
# Comparing the parallel and non parallel programming elapsed time
# Tested in Windows 10 Desktop OS, R verison 3.2.3 

# 1 Using parallel programming to run glm training of iris dataset 
library(doParallel)
cl <- makeCluster(3, type = "PSOCK")
registerDoParallel(cl)

x <- iris[which(iris[,5] != "setosa"), c(1,5)]
trials <- 10000
ptime <- system.time({
  r <- foreach(icount(trials), .combine=cbind) %dopar% {
  ind <- sample(100, 100, replace=TRUE)
  result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
  coefficients(result1)
  }
  })[3]
stopCluster(cl)
ptime

# elapsed 
# 23.25

# Function to unreg the registration of parallel
unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
unregister()

# Function to stop cluster
stopCluster(cl)


# 2 Using non parallel programming to run glm training of iris dataset 
ptime_non <- system.time({
  r <- foreach(icount(trials), .combine=cbind) %do% {
    ind <- sample(100, 100, replace=TRUE)
    result1 <- glm(x[ind,2]~x[ind,1], family=binomial(logit))
    coefficients(result1)
  }
})[3]
ptime_non

# elapsed 
# 92.74 

# Conclusion: parallel programming will make the elapsed time faster than non parallel programming. 
# For bootstraping 