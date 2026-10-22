## LandR forest growth with harvest on a BC timber harvesting land base. No fire, no CBM yet.
## By default a 150 x 150 km square in the Southern Interior; or one BC Timber Supply Area or
## Tree Farm Licence.
##
## Run from this folder: Rscript global.R. Set `doRun <- FALSE` first to stop after setupProject().
## The settings are the `defaultDots` below. To change one for a run, define it before sourcing
## this file, e.g.  .unit <- "TSA24"; source("global.R"). experiment.R does that for many runs.
if (!exists("doRun")) doRun <- TRUE

out <- SpaDES.project::setupProject(
  name = "FIIS",
  .unit = .unit,
  .harvestType = .harvestType,
  .rotationAge = .rotationAge,
  .endYear = .endYear,
  .bcLevel = .bcLevel,
  .balanceGrowth = .balanceGrowth,
  .thlbAge = .thlbAge,
  .stage1Only = .stage1Only,
  defaultDots = list(.unit = "",                 # "" = the Southern Interior square; else e.g. "TSA24", "TFL48"
                     .harvestType = "clearcut",  # or "partial" (dominant species only)
                     .rotationAge = 100,         # Hanzlik R; NA uses minAgesToHarvest
                     .endYear = 2125,
                     .bcLevel = "ZONE",          # BEC level for ecoregions: "ZONE" or "SUBZONE"
                     .balanceGrowth = TRUE,      # lets spruce, fir and pine grow side by side
                     .thlbAge = 160L,            # age at which a stand must reach 6000 g/m2 to be loggable
                     .stage1Only = FALSE),       # TRUE: data prep, yield tables and THLB only, no harvest;
                                                 # a later full run picks these up from the cache
  ## Each unit has its own inputs, outputs and scratch folders, so units can run at once
  paths = list(inputPath = file.path("inputs", .unit),
               outputPath = file.path("outputs", .bcLevel, .unit, paste0(.harvestType, "_R", .rotationAge),
                                      if (isTRUE(.balanceGrowth)) "" else "noBalanceGrowth"),
               scratchPath = file.path("scratch", .unit)),
  modules = c("PredictiveEcology/Biomass_speciesData@development"
              , "PredictiveEcology/localEcozones@development"            # ecoregions: BEC zones in BC
              , "PredictiveEcology/Biomass_borealDataPrep@development"
              , "PredictiveEcology/Biomass_speciesFactorial@development" # the factorial table speciesParameters fits to
              , "PredictiveEcology/Biomass_speciesParameters@development" # fits growth curves to permanent sample plots
              , "PredictiveEcology/Biomass_yieldTables@development"      # yield curves (init only)
              , "PredictiveEcology/thlbBC@development"                   # where logging is allowed (THLB)
              , "PredictiveEcology/harvestConstraintsBC@development"     # parks, habitat, scenic areas, watersheds
              , "PredictiveEcology/Biomass_core@development"             # growth
              , "PredictiveEcology/simpleHarvestPlanning@development"    # Hanzlik cut
              , "camillegiuliano/LandRCBM_partialDisturbance@main"),     # removal and replanting; no development branch
  times = list(start = 2025, end = .endYear),
  ## the project's own library; module reqdPkgs are added by setupProject
  packages = c("PredictiveEcology/SpaDES.core@development (>= 3.2.1.9002)" # the `events` barrier used for stage 1
               , "PredictiveEcology/timberSupply@development (>= 0.0.0.9001)" # bcManagementUnit(), for the study area
               , "PredictiveEcology/LandR@development (>= 1.2.0.9064)" # the SCANFI grid below; species list fix (#287)
               , "terra", "sf"),
  options = list(
    "~/googledriveAuthentication.R"
    , reproducible.shapefileRead = "terra::vect"
    , reproducible.destinationPathShared = "data" # downloads shared between projects (may be a link)
  ),
  params = list(
    .globals = list(.studyAreaName = if (nzchar(.unit)) .unit else "SouthernInteriorBC", .plots = NA,
                    ## init too, so a full run after a stage-1 run gets the data prep, yield
                    ## tables and THLB from the cache
                    .useCache = c(".inputObjects", "init")),
    ## Dominique Caron's settings (2026-10-02)
    Biomass_speciesParameters = list(.plots = "png", standAgesForFitting = c(0, 100),
                                     balanceGrowth = .balanceGrowth),
    localEcozones = list(bcLevel = .bcLevel),
    Biomass_yieldTables = list(maxAge = .thlbAge),
    thlbBC = list(age = .thlbAge),
    simpleHarvestPlanning = list(verbose = 1, hanzlik = TRUE, harvestType = .harvestType,
                                 rotationAge = .rotationAge, .plots = "png")
  ),
  ## objects; each may use the ones above it. The area, in longitude/latitude:
  .area = if (nzchar(.unit)) {
    timberSupply::bcManagementUnit(.unit, crs = "EPSG:4326")
  } else {
    terra::as.polygons(terra::ext(-120.67, -118.53, 50.53, 51.87), crs = "EPSG:4326") # ~150 x 150 km around -119.6, 51.2
  },
  ## the model grid: SCANFI 2020 land cover, kept in SCANFI's projection, aggregated 30 m -> 240 m
  rasterToMatch = LandR::prepInputs_SCANFI_LCC_FAO(year = 2020, destinationPath = paths$inputPath,
                                                   cropTo = .area, maskTo = .area, projectTo = NA) |>
    terra::aggregate(fact = 240 / 30),
  studyArea = sf::st_as_sf(terra::project(.area, terra::crs(rasterToMatch))),
  outputs = data.frame(objectName = c("harvestSummary", "harvestStats", "cumulativeHarvestMap", "thlb",
                                      "yieldTablesCumulative", "yieldTablesId"))
)

## Stage 1: every init runs, no harvest does.
if (isTRUE(out$.stage1Only))
  out$events <- list(.stopBefore = list(simpleHarvestPlanning = "harvest"))

if (isTRUE(doRun)) {
  sim <- SpaDES.core::simInitAndSpades2(out)
}
