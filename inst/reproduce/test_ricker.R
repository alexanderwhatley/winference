library(winference)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(foreach)
library(doMC)
library(doRNG)
library(reshape2)
registerDoMC(cores = 6)
rm(list = ls())
setmytheme()

set.seed(11)

get_ricker <- function(){
  rprior <- function(nparticles, ...){
    theta1 <- runif(nparticles, min = 0, max = 10)
    theta2 <- runif(nparticles, min = 0, max = 20)
    theta3 <- runif(nparticles, min = 0, max = 2)
    return(cbind(theta1, theta2, theta3))
  }
  dprior <- function(thetas, ...){
    if (is.null(dim(thetas))) thetas <- matrix(thetas, nrow = 1)
    density_evals <- dunif(thetas[,1], min = 0, max = 10, log = TRUE)
    density_evals <- density_evals + dunif(thetas[,2], min = 0, max = 20, log = TRUE)
    density_evals <- density_evals + dunif(thetas[,3], min = 0, max = 2, log = TRUE)
    return(density_evals)
  }
  #
  generate_randomness <- function(nobservations){
    return(list())
  }
  robservation <- function(nobservations, theta, parameters, randomness){
    obs <- rep(0, nobservations)
    r <- exp(theta[1])
    phi <- theta[2]
    sigma_e <- theta[3]
    state <- 1
    for (t in 1:nobservations){
      state = r * state * exp(-state + sigma_e * rnorm(1))
      obs[t] <- rpois(1, phi*state)
    }
    return(obs)
  }
  #
  model <- list(rprior = rprior,
                dprior = dprior,
                generate_randomness = generate_randomness,
                robservation = robservation,
                parameter_names = c("logr", "phi", "sigma_e"),
                thetadim = 3, ydim = 1)
  return(model)
}

target <- get_ricker()

# number of observations
nobservations <- 100
# parameter of data-generating process
true_theta <- c(3.8, 10, 0.3)
obs <- target$robservation(nobservations, true_theta,
                           target$parameters, target$generate_randomness(nobservations))
plot(obs, type = "l")

lagvalue <- 3

lag_obs <- create_lagmatrix(matrix(obs, nrow = 1), lagvalue)
lag_obs <- lag_obs[,(lagvalue+1):ncol(lag_obs)]
order_obs <- hilbert_order(lag_obs)
orderded_obs <- lag_obs[,order_obs]

compute_d_hilbert <- function(theta){
  fake_rand <- target$generate_randomness(nobservations)
  fake_obs <- target$robservation(nobservations, theta, target$parameters, fake_rand)
  fake_obs <- create_lagmatrix(matrix(fake_obs, nrow = 1), lagvalue)
  fake_obs <- fake_obs[,(lagvalue+1):ncol(fake_obs)]
  order_fake <- hilbert_order(fake_obs)
  distance <- nrow(fake_obs) * mean(abs(orderded_obs - fake_obs[,order_fake]))
  return(distance)
}


# obs_sorted <- sort(obs)
# function to compute distance between observed data and data generated given theta
# compute_d <- function(theta, metric = metricL2){
#   fake_rand <- target$generate_randomness(nobservations)
#   fake_obs <- target$robservation(nobservations, theta, target$parameters, fake_rand)
#   fake_obs_sorted <- sort(fake_obs)
#   return(metric(obs_sorted, fake_obs_sorted))
# }

proposal <- mixture_proposal()

param_algo <- list(nthetas = 2048, nmoves = 1, proposal = proposal,
                   nsteps = 40, minimum_diversity = 0.5, R = 2, maxtrials = 1000)

filename <- paste0("~/Dropbox/ABCD/Results/ricker/ricker.n",
                   nobservations, ".L", lagvalue, ".wsmc_rhit-hilbert.RData")
# results <- wsmc_rhit(compute_d_hilbert, target, param_algo, savefile = filename)
# wsmc.df <- wsmc_to_dataframe(results, target$parameter_names)
# nsteps <- max(wsmc.df$step)
# save(wsmc.df, results, nsteps, file = filename)

load(filename)
wsmc.df <- wsmc_to_dataframe(results, target$parameter_names)
nsteps <- max(wsmc.df$step)
#
target$parameter_names

g <- ggplot(wsmc.df %>% filter(step > 0), aes(x = logr, group = step, colour = step)) + geom_density(aes(y = ..density..))
g <- g +  theme(legend.position = "none")
g <- g + xlab(expression(log(r))) + geom_vline(xintercept = true_theta[1])
g
#
# g <- ggplot(wsmc.df, aes(x = phi, group = step)) + geom_density(aes(y = ..density..), colour = "darkgrey")
# g <- g +  theme(legend.position = "none")
# g <- g + xlab(expression(phi))
# g

g <- ggplot(wsmc.df, aes(x = logr, y = phi, colour = step, group = step))
g <- g + geom_point(alpha = 0.5)
g <- g + scale_colour_gradient2(midpoint = floor(nsteps/2)) + theme(legend.position = "none")
g <- g + xlab(expression(log(r))) + ylab(expression(phi))
g <- g + geom_vline(xintercept = true_theta[1]) + geom_hline(yintercept = true_theta[2])
g

g <- ggplot(wsmc.df, aes(x = phi, y = sigma_e, colour = step, group = step))
g <- g + geom_point(alpha = 0.5)
g <- g + scale_colour_gradient2(midpoint = floor(nsteps/2)) + theme(legend.position = "none")
g <- g + xlab(expression(log(r))) + ylab(expression(sigma[e]))
g <- g + geom_vline(xintercept = true_theta[2]) + geom_hline(yintercept = true_theta[3])
g

#
# g <- ggplot(wsmc.df, aes(x = c, y = e, colour = step, group = step))
# g <- g + geom_point(alpha = 0.5)
# g <- g + scale_colour_gradient2(midpoint = floor(nsteps/2)) + theme(legend.position = "none")
# g <- g + xlab(expression(c)) + ylab(expression(e))
# g


