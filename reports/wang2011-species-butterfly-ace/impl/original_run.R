# Driver for the authors' SPECIES 1.0 package (original attempt, basis: original).
# Calls only the package's own ChaoLee1992 on its bundled butterfly data (the listing on JSS p. 8).
library(SPECIES, lib.loc = "/work/Rlib")
data("butterfly")
str(butterfly)
res <- ChaoLee1992(butterfly, t = 10, method = "all")
print(res)
cat("ACE Nhat:", res$Nhat[1], "\n")
