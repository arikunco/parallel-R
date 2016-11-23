#library(parallel)
library(caret)
library(mlbench)
library(doParallel)

#Data import
data(Sonar)

# Calculate the number of cores
no_cores <- detectCores() - 1

# Initiate cluster
cl <- makeCluster(no_cores,type = "PSOCK")
registerDoParallel(cl)

# Do training to tune mtry parameter with PARALLEL programming
system.time(result1 <- train(
  tuneGrid=data.frame(mtry=c(2,3,4,5,10,20)),
  Class~.,
  data = Sonar, method = "ranger",
  trControl = trainControl(Sonar, method = "cv", number = 10, verboseIter = TRUE)
))

# Outcome sample
# Selecting tuning parameters
# Fitting mtry = 3 on full training set
# user  system elapsed 
# 2.16    0.06   12.75 

# Function to unreg the registration of parallel
unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}

unregister()

# Function to stop cluster
stopCluster(cl)

# Check how many cluster how many workers foreach is used
getDoParWorkers()

# Do training without parallel programming
system.time(result2<- train(
  tuneGrid=data.frame(mtry=c(2,3,4,5,10,20)),
  Class~.,
  data = Sonar, method = "ranger",
  trControl = trainControl(Sonar, method = "cv", number = 10, verboseIter = TRUE)
))

# Outcome sample
# Selecting tuning parameters
# Fitting mtry = 3 on full training set
# user  system elapsed 
# 35.37    0.71   36.41