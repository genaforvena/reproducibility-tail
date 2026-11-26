# Driver for punzo2016-wine-cnm-bic (basis: original).
# Calls the authors' CNmixt() from the unmodified ContaminatedMixt 1.0 package on the
# wine data bundled with it, over G in {1,2,3,4} and all 14 parsimonious structures,
# seed 1 (registered by the scout). Labels (column Type) are dropped: 178 x 13.
#
# Why one call per (G, structure): the single call CNmixt(X, G=1:4) halts at
# (G=4, EVE) inside mixture::gpcm (get_best_model: "no models estimated"), which escapes
# the package's own per-job error handling; that run is kept in evidence/original-attempt.log.
# Here each fit is the authors' CNmixt() unchanged, wrapped in tryCatch so a failed fit is
# logged as a failure and excluded, as the package does for its own failed jobs.
# Selection uses the package's own whichBest() (BIC) over the successful fits; nothing is tuned.
suppressPackageStartupMessages(library(ContaminatedMixt))
data("wine", package = "ContaminatedMixt")
X <- as.matrix(wine[, -1])
cat("data dim:", dim(X), "\n")
set.seed(1)  # registered seed; the default initialization ("mixt") is deterministic given it
structures <- c("EII", "VII", "EEI", "VEI", "EVI", "VVI", "EEE", "VEE", "EVE", "EEV", "VVE", "VEV", "EVV", "VVV")
ok <- list()
failed <- character(0)
for (g in 1:4) {
  for (s in structures) {
    r <- NULL
    fit <- tryCatch(
      { r <- suppressWarnings(CNmixt(X, G = g, model = s, seed = NULL)); "ok" },
      error = function(e) e)
    if (inherits(fit, "error") || is.null(r) || length(r$models) == 0) {
      msg <- if (inherits(fit, "error")) conditionMessage(fit) else "no models estimated"
      failed <- c(failed, sprintf("FAILED G=%d structure=%s: %s", g, s, msg))
      cat(tail(failed, 1), "\n")
    } else {
      for (m in r$models) ok[[length(ok) + 1]] <- m
    }
  }
}
res <- structure(list(call = NULL, models = ok), class = "ContaminatedMixt")
cat("\n== successful fits:", length(ok), " failed fits:", length(failed), "\n")
for (f in failed) cat(f, "\n")
for (m in ok) {
  bic <- tryCatch(m$IC$BIC, error = function(e) NA)
  cat(sprintf("MODEL G=%s structure=%s BIC=%s\n", m$G, m$model, format(bic, digits = 12)))
}
best <- ContaminatedMixt:::whichBest(res)   # named by criterion; BIC is the registered one
sel <- res$models[[best[["BIC"]]]]
cat(sprintf("SELECTED G=%s structure=%s (package whichBest, BIC)\n", sel$G, sel$model))
bics <- sapply(ok, function(m) m$IC$BIC)
top <- ok[[which.max(bics)]]
cat(sprintf("CHECK argmax BIC over successful fits: G=%s structure=%s BIC=%s\n", top$G, top$model, format(max(bics), digits = 12)))
cat(sprintf("SELECTED_G %s\n", sel$G))
cat(sprintf("SELECTED_STRUCTURE_INDEX %d\n", match(sel$model, structures)))
for (p in c("ContaminatedMixt", "mixture", "mnormt", "mclust")) cat(sprintf("PKG %s %s\n", p, as.character(packageVersion(p))))
