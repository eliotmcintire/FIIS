## A dashboard of one run: its maps on an OpenStreetMap background, with a time slider for the
## yearly ones (e.g. cumulative harvest), and its figures. Run from this folder after a run.
Require::Install("PredictiveEcology/SpaDES.shiny@development (>= 0.1.0.9007)") # 0 transparent; slider spans yearly outputs only

## The run to show: the `sim` in this R session, or else its output folder
run <- if (exists("sim")) sim else file.path("outputs", "ZONE", "TSA02", "clearcut_R100")

SpaDES.shiny::shine(run, exclude = c("Harvest_year_.*png$",         # yearly map images; the maps show these
                                     "spatialConstraints\\.tif$"))  # NA (no harvest) would be invisible; see spatialConstraintsMap.tif
