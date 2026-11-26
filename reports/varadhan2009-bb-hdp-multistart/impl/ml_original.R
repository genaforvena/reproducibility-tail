# The paper's listing (JSS p. 10-11; the authors' vignette BBvignetteJSS.Stex, lines 'hdp <- function').
# hdp is not exported by the installed BB package, so the driver sources the authors' definition
# from the vignette source (extracted in the sandbox by recipe.sh to /work/hdp.R).
library(BB, lib.loc = "/work/Rlib")
library(setRNG)
source("/work/hdp.R")
test.rng <- list(kind = "Mersenne-Twister", normal.kind = "Inversion", seed = 1234)
old.seed <- setRNG(test.rng)
p0 <- matrix(runif(900), 300, 3)
ans <- multiStart(par = p0, fn = hdp, action = "solve")
cat(sprintf("sum(ans$conv) = %d\n", as.integer(sum(ans$conv))))
cat(sprintf("sum(ans$converged) = %d\n", as.integer(sum(ans$converged))))
