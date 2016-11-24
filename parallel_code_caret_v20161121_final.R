# First, we need to make sure that all required packages are installed 
# install packages: parallel, doParallel, ranger
install.packages("parallel")
install.packages("doParallel")
install.packages("ranger")
install.packages("mlbench") #optional, because data Sonar will be provided
install.packages("caret")
install.packages("e1071")

library(parallel)
library(caret)
library(ranger)
library(mlbench)
library(doParallel)

# Data import
data(Sonar)

# In AWS Testing, please coordinate with Amir providing the data in csv format 
# Sonar <- read.csv("Sonar.csv")

# Calculate the number of cores
no_cores <- detectCores() - 1

# Initiate cluster
# cl <- makeCluster(no_cores,type = "PSOCK") # this is for WINDOWS
cl <- makeCluster(no_cores,type="FORK") # this is for UNIX
registerDoParallel(cl)

# Do training to tune mtry parameter with PARALLEL programming
system.time(result1 <- train(
  tuneGrid=data.frame(mtry=c(2:50)),
  Class~.,
  data = Sonar, method = "ranger",
  trControl = trainControl(Sonar, method = "cv", number = 10)
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

# Do training without parallel programming, 
system.time(result2<- train(
  tuneGrid=data.frame(mtry=c(2:50)),
  Class~.,
  data = Sonar, method = "ranger",
  trControl = trainControl(Sonar, method = "cv", number = 10, allowParallel = FALSE)
))

# Outcome sample
# Selecting tuning parameters
# Fitting mtry = 3 on full training set
# user  system elapsed 
# 35.37    0.71   36.41