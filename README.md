# FIIS

LandR forest growth with timber harvest on a British Columbia timber harvesting land base, as a SpaDES project.

- `global.R` sets up and runs one simulation. Its settings are the `defaultDots` near the top; change one for a run by defining it before sourcing, e.g. `.unit <- "TSA24"; source("global.R")`.
- `experiment.R` runs `global.R` once per row of a table of settings.
- `dashboard.R` shows a run's maps (yearly ones with a time slider) and figures in a browser, with `SpaDES.shiny::shine()`.

Run from this folder. The first run installs packages and downloads data into `inputs/` (and `data/`, if it exists, for downloads shared with other projects).
