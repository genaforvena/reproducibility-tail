library(betareg, lib.loc = "/work/Rlib")
data("GasolineYield", package = "betareg")
fit <- betareg(yield ~ batch + temp, data = GasolineYield, type = "ML")
cat(sprintf("logLik ML = %.8f\n", as.numeric(logLik(fit))))
