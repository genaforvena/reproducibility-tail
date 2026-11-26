# The paper's listing (JSS p. 29): the example1 data typed in the paper, then icfit's NPMLE.
library(interval, lib.loc = "/work/Rlib")
L <- c(2, 5, 1, 1, 9, 8, 10)
R <- c(3, 6, 7, 7, 12, 10, 13)
group <- c(0, 0, 1, 1, 0, 1, 0)
example1 <- data.frame(L, R, group)
fit <- icfit(L, R)
print(summary(fit, digits = 12))
p23 <- fit$intmap
cat("interval package version:", as.character(packageVersion("interval", lib.loc = "/work/Rlib")), "\n")
