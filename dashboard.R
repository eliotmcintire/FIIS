## A dashboard of one run: its maps on an OpenStreetMap background, with a time slider for the
## yearly ones (e.g. cumulative harvest), and its figures. Run from this folder.
Require::Install("PredictiveEcology/SpaDES.shiny@development (>= 0.1.0.9008)") # 0 transparent; slider spans yearly outputs only

## The run to show: the `sim` in this R session; else the output folder of `.unit`;
## else run `.unit` first (global.R uses `.unit`; slow: ~20 min for TSA02, hours for TSA24)
.unit <- "TSA02" # a southern interior TSA. To see every TSA and TFL, and pick one by name:
## Require::Install("PredictiveEcology/timberSupply@development (>= 0.0.0.9004)")
## fmus <- timberSupply::bcManagementUnits() |> reproducible::Cache(cachePath = "cache")
## terra::plet(fmus)
outFolder <- file.path("outputs", "ZONE", .unit, "clearcut_R100")
if (!exists("sim") && !dir.exists(outFolder)) source("global.R") # creates sim
run <- if (exists("sim")) sim else outFolder

SpaDES.shiny::shine(run, exclude = c("Harvest_year_.*png$",         # yearly map images; the maps show these
                                     "spatialConstraints\\.tif$"))  # NA (no harvest) would be invisible; see spatialConstraintsMap.tif
