#+ presets, echo = FALSE, warning = FALSE, message = FALSE
library(winference)
library(ggthemes)
library(doRNG)
library(tidyr)
registerDoMC(cores = 10)
rm(list = ls())
setmytheme()

set.seed(11)

target <- get_normal()

# number of observations
nobservations <- 100
load(file = "~/Dropbox/ABCD/Results/data/normaldata.RData")
obs <- obs[1:nobservations]

## load results from ABC-SMC
load("~/Dropbox/ABCD/Results/univariatenormal/normaldata.n100.wsmc.RData")
## load results from standard MCMC using the exact likelihood
filename <- paste0("~/Dropbox/ABCD/Results/univariatenormal/normaldata.n", nobservations, ".metropolis.RData")
load(filename)
chainlist_to_dataframe <- function(chains_list){
  nchains <- length(chains_list)
  niterations <- nrow(chains_list[[1]])
  chaindf <- foreach (i = 1:nchains, .combine = rbind) %do% {
    data.frame(ichain = rep(i, niterations), iteration = 1:niterations, X = chains_list[[i]])
  }
  return(chaindf)
}
chaindf <- chainlist_to_dataframe(mh$chains)
# plot
chaindf.melt <- melt(chaindf, id.vars = c("ichain", "iteration"))
mcmc.df <- chaindf.melt %>% filter(iteration > 2000) %>% spread(variable, value)
#############
g <- ggplot(wsmc.df, aes(x = mu, group = step)) + geom_density(aes(y = ..density..), colour = "darkgrey")
g <- g +  theme(legend.position = "none")
g <- g + geom_density(data = mcmc.df, aes(x = X.1, group = NULL, colour = NULL), colour = "black", linetype = 2)
g <- g + xlab(expression(mu))
g

g <- ggplot(wsmc.df, aes(x = sigma, group = step)) + geom_density(aes(y = ..density..), colour = "darkgrey")
g <- g + theme(legend.position = "none")
g <- g + geom_density(data = mcmc.df, aes(x = X.2, group = NULL, colour = NULL), colour = "black", linetype = 2)
g <- g + xlab(expression(sigma))
g

