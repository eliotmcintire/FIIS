## Runs global.R once per row of `runs`. Each column is one of global.R's `defaultDots`
## (.unit, .harvestType, .rotationAge, .endYear, .bcLevel, .balanceGrowth, .stage1Only); a setting
## left out keeps global.R's default. Each run is its own R session, as `Rscript global.R` would be,
## and writes its own log in logs/.
##   Rscript experiment.R

runs <- data.frame(.unit = c("TSA24", "TFL48"),
                   .harvestType = "clearcut",
                   .rotationAge = c(100, 80))
nAtOnce <- 2  # runs at the same time; each needs a lot of memory

runOne <- function(i) {
  settings <- vapply(names(runs), function(nm) paste0(nm, " <- ", deparse(runs[[nm]][i])), "")
  code <- paste(c(settings, 'source("global.R")'), collapse = "; ")
  log <- file.path("logs", paste0("run", i, "_", paste(runs[i, ], collapse = "_"), ".log"))
  system2("Rscript", c("-e", shQuote(code)), stdout = log, stderr = log)
  ## the first run in a new project installs packages, then asks for a fresh R session
  if (any(grepl("Please restart R", readLines(log))))
    system2("Rscript", c("-e", shQuote(code)), stdout = log, stderr = log)
  log
}

dir.create("logs", showWarnings = FALSE)
## the first run alone, so the others do not install packages at the same time
runOne(1)
if (nrow(runs) > 1)
  parallel::mclapply(seq_len(nrow(runs))[-1], runOne, mc.cores = nAtOnce)
