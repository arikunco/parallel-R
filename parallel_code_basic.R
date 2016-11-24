# This code is curated from this blog link: https://www.r-bloggers.com/how-to-go-parallel-in-r-basics-tips/
# Title       : How-to go parallel in R - basics + tips
# Objective   : To Practice parallel programming in R (basic) with code samples 
# Background  : The common motivation behind parallel computing is that something is taking too long time. 
#               Long time means any computation that takes more than 3 minutes - this because 
#               parallelization is incredibly simple and most tasks that take time


# Learn the concept of lapply
a <- lapply(1:3, function(x) c(x, x^2, x^3))
b <- lapply(1:3/3, round, digits=3)

library(parallel) 

# Calculate the number of cores
no_cores <- detectCores() - 1

# using parLapply
# Initiate cluster
cl <- makeCluster(no_cores,type = "FORK") # type = "FORK" is for UNIX
cl <- makeCluster(no_cores,type= "PSOCK") # default type is PSOCK for Windows.
parLapply(cl, 2:4,
          function(exponent)
            2^exponent)
stopCluster(cl)
# system.time(parLapply(cl, 2:10000000,
#                         +           function(exponent)
#                           +             2^exponent))

# user  system elapsed 
# 25.45    2.17   38.08 



# system.time(lapply(2:10000000,function(exponent)2^exponent))

# user  system elapsed 
# 44.80    0.22   45.29 

# stop cluster
stopCluster(cl)


#using parSapply 
# Initiate cluster
cl <- makeCluster(no_cores,type = "PSOCK")
base <- 2
clusterExport(cl, "base")
parSapply(cl, 2:4, 
          function(exponent) 
            base^exponent)

parSapply(cl, as.character(2:4), 
          function(exponent){
            x <- as.numeric(exponent)
            c(base = base^x, self = x^x)
          })
# Stop Cluster
stopCluster(cl)

#using foreach
library(foreach)
library(doParallel)

cl<-makeCluster(no_cores)
registerDoParallel(cl)

# We can change two lines above to: 
# registerDoParallel(no_cores)
# stopImplicitCluster() ##instead of stopCluster(), do stopImplicitCluster() command 

# The foreach function can be viewed as being a more controlled version of the parSapply 
# that allows combining the results into a suitable format. 
# By specifying the .combine argument we can choose how to combine our results, 
# below is a vector, matrix, and a list example:

foreach(exponent = 2:4, 
        .combine = c)  %dopar%  
  base^exponent

foreach(exponent = 2:4, 
        .combine = rbind)  %dopar%  
  base^exponent

foreach(exponent = 2:4, 
        .combine = list,
        .multicombine = TRUE)  %dopar%  
  base^exponent

foreach(exponent = 2:4, 
        .combine = list)  %dopar%  
  base^exponent


stopCluster(cl)

# Function to unreg the registration of parallel
unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
unregister()


#Variable scope
#The variable scope constraints are slightly different for the foreach package. 
#Variable within the same local environment are by default available:

base <- 2
cl<-makeCluster(2)
registerDoParallel(cl)
foreach(exponent = 2:4, 
        .combine = c)  %dopar%  
  base^exponent

#While variables from a parent environment will not be available, i.e. the following will throw an error:

test <- function (exponent) {
  foreach(exponent = 2:4, 
          .combine = c)  %dopar%  
    base^exponent
}
test()

#> test()
# Error in base^exponent : task 1 failed - "object 'base' not found"
# Called from: e$fun(obj, substitute(ex), parent.frame(), e$data)

# A nice feature is that you can use the .export option instead of the clusterExport. 
# Note that as it is part of the parallel call it will have the latest version of the 
# variable, i.e. the following change in "base" will work:

base <- 2
cl<-makeCluster(2)
registerDoParallel(cl)

base <- 4
test <- function (exponent) {
  foreach(exponent = 2:4, 
          .combine = c,
          .export = "base")  %dopar%  
    base^exponent
}
test()


# Fork or sock?
# The writer mostly analyses on Windows and has therefore gotten used to the PSOCK system. 
# For those of you on other systems you should be aware of some important differences between 
# the two main alternatives:
#   
# FORK: "to divide in branches and go separate ways"
# Systems: Unix/Mac (not Windows)
# Environment: Link all
# 
# PSOCK: Parallel Socket Cluster
# Systems: All (including Windows)

library(pryr) # Used for memory analyses
cl<-makeCluster(no_cores)
clusterExport(cl, "a")
clusterEvalQ(cl, library(pryr))

# Below you can see that the memory address space for variables exported to 
# PSOCK are not the same as the original:
parSapply(cl, X = 1:10, function(x) {address(a)}) == address(a)
# [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE


# if FORK (MAC/UNIX)
# cl<-makeCluster(no_cores, type="FORK")
# parSapply(cl, X = 1:10, function(x) address(a)) == address(a)
# [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE

cl<-makeCluster(no_cores, outfile = "debug.txt")
registerDoParallel(cl)
foreach(x=list(1, 2, "a"))  %dopar%  
{
  print(x)
}
stopCluster(cl)

####
rm(list=ls())
library(pryr)
library(magrittr)
a <- matrix(1, ncol=10^4*2, nrow=10^4)
object_size(a)

system.time(mean(a))
# user  system elapsed 
# 0.5     0.0     0.5

system.time(mean(a + 1))
# user  system elapsed 
# 0.84    0.40    1.30 

library(parallel)

cl <- makeCluster(3, type = "PSOCK")

#important: to export 'a' object 
system.time(clusterExport(cl,"a"))

# user  system elapsed 
# 6.73   15.71   22.61

system.time(parSapply(cl, 1:3, 
                      function(x) mean(a + 1)))

stopCluster()

# Memory tips
#1 Frequently use rm() in order to avoid having unused variables around
#2 Frequently call the garbage collector gc(). Although this should be implemented automatically in R, 
## I've found that while it may releases the memory locally it may not return it to the operating system (OS). This makes sense when running at a single instance as this is an time expensive procedure but if you have multiple processes this may not be a good strategy. Each process needs to get their memory from the OS and it is therefore vital that each process returns memory once they no longer need it.
#3 Although it is often better to parallelize at a large scale due to initialization costs it may in 
## memory situations be better to parallelize at a small scale, i.e. in subroutines.
#4 I sometimes run code in parallel, cache the results, and once I reach the limit I change to sequential.
#5 You can also manually limit the number of cores, using all the cores is of no use if the memory 
## isn't large enough. A simple way to think of it is: memory.limit()/memory.size() = max cores
## memory.limit()/memory.size()

# Other tips
#1 A general core detector function that I often use is:
max(1, detectCores() - 1)
#2 Never use 
set.seed()
## use 
clusterSetRNGStream() 
#instead, to set the cluster seed if you want reproducible results
#3 If you have a Nvidia GPU-card, you can get huge gains from micro-parallelization through the 
## gputools package (Warning though, the installation can be rather difficult.).
## When using mice in parallel remember to use ibind() for combining the imputations.


#To find out how many workers foreach is going to use, you can use the getDoParWorkers function:
getDoParWorkers()
