## Pacific Hake Joint Technical Committee, January 2016
## all.r - Source this file to load all data and functions,
##  and to run the forecasting for the base model,
## then save the R environment to .RData in this directory. This
## will be read in by knitr as a binary file so that multiple
## loads don't happen during the latex/knitr build (they are
## very slow compared to loading the binary once at the beginning).

remove.all.except <- function(vars  = c("models")){
  # Removes every object in the workspace except for what is in the vars list.
  # Upon finishing, the workspace will contain whatever is in the vars list,
  #  plus the objects 'remove.all.except' (this function) and 'models.loaded'.
  # That tells the software that the model has already been loaded.
  vars <- c(vars, "remove.all.except")
  keep <- match(x = vars, table = ls(all = TRUE, envir = .GlobalEnv))
  if(any(is.na(keep))){
    models.loaded <<- FALSE
  }else{
    rm(list=ls(all = TRUE, envir = .GlobalEnv)[-keep], envir = .GlobalEnv)
    models.loaded <<- TRUE
  }
}
remove.all.except()

## Need to source utilities.r before everything because it contains the function
##  install.packages.if.needed
source("utilities.r")
install.packages.if.needed("devtools", "devtools", github=FALSE)
install.packages.if.needed("nwfscSurvey", "nwfsc-assess/nwfscSurvey", github=TRUE)
install.packages.if.needed("nwfscMapping", "nwfsc-assess/nwfscMapping", github=TRUE)
install.packages.if.needed("date", "date", github=FALSE)
install.packages.if.needed("r4ss", "r4ss/r4ss", github=TRUE)
install.packages.if.needed("xtable", "xtable", github=FALSE)
install.packages.if.needed("PBSmapping", "PBSmapping", github=FALSE)
install.packages.if.needed("dplyr", "dplyr", github = FALSE)
## install.packages.if.needed("gtools", "gtools", github = FALSE)

require(nwfscSurvey)
require(nwfscMapping)
require(date)
require(r4ss)
require(xtable)
require(PBSmapping)
require(dplyr)
## require(gtools)

source("catches.r") ## Contains the code to catch/TAC data and figure and table-making code for catch/TAC
source("load-models.r")
source("survey.r") ## Contains the code to load survey history data and table-making code for survey

source("figures-timeseries.r")
source("figures-compare-forecasts.r")
source("figures-mcmc-diagnostics.r")
source("figures-age-comps.r")
source("figures-selex.r")
source("figures-stock-recruitment.r")
source("figures-mle-mcmc.r")

source("tables-timeseries.r")
source("tables-reference-points.r")
source("tables-decisions.r")

## verbose applies to the SS loading functions as well as this project's functions
verbose <- FALSE

data.path <- file.path("..","..","data")
models.path <- file.path("..","..","models")

catch.data.file <- "Hake_Landings_TAC_History.csv"
further.tac.file <- "Further_TAC_details.csv"
data.file.name <- "2015hake_data.ss"
survey.history.file <- "survey_history.csv"

control.file.name <- "2015hake_control.ss"
starter.file.name <- "starter.ss"
forecast.file.name <- "forecast.ss"
weight.at.age.file.name <- "wtatage.ss"

SSversion <- "3.24U"

## Index of the base model as found in the directory.
## i.e. 00_Modelname is index 1, 01_Modelname is index 2, etc.
base.model.ind <- 1

## recruitment deviations start year
recruit.dev.start.yr <- 1946
## Unfished equilibrium year.
unfished.eq.yr  <- 1964
## Start year for the models
start.yr        <- 1966
## The last non-forecast year in the model. This is the year for which the
## mcmc outputs will be used in reference point calculations.
end.yr          <- 2015
## First year in the survey timeseries
survey.start.yr <- 1995
## Last year in the survey timeseries
survey.end.yr   <- 2013
## The last year an assessment was done
last.assess.yr  <- end.yr - 1
## current assessment year
assess.yr       <- end.yr
## Final year of data
last.data.yr    <- end.yr - 1

## The forecasting yrs and probs can be set to whatever is required, the
## latex/knitr code is set up to automatically accomodate changes
forecast.yrs <- end.yr:(end.yr + 2)
forecast.probs <- c(0.05,0.25,0.5,0.75,0.95)

## catch.levels is a list of N catch levels to run forecasts for
## Each element of the list is a vector of length the same as the
## number of elements in forcast.yrs
catch.levels <- list(rep(0.01, 3),
                     rep(180000,3),
                     rep(300000,3),
                     rep(350000,3),
                     rep(400000,3),
                     rep(428000,3),
                     rep(500000,3),
                     rep(710000,3),
                     c(730000,650000,520000),
                     c(804576,682782,547280))

## The catch as calculated using the default harvest policy. Used in forecasting.
catch.default.policy.ind <- length(catch.levels)
catch.default.policy <- catch.levels[[catch.default.policy.ind]]
## Index for the forecasts list, which one above is the TAC case?
## This is used in the one-page summary
catch.tac.ind <- 3

## catch.levels.names is a list of N names for the catch levels given in catch.levels
##  to be used in plots (Pretty names)
catch.levels.names <- c("No Fishing",
                        "180,000 t",
                        "300,000 t",
                        "350,000 t",
                        "400,000 t",
                        "428,000 t",
                        "500,000 t",
                        "stableCatch",
                        "SPR100",
                        paste0("Default: ",fmt0(catch.default.policy[1])," t"))

## catch.levels.dir.names is a list of N names for the catch levels given in catch.levels,
##  to be used as the directory names (OS-naming friendly). Use prefixed numbers so that
## the list order is the same as the directory order.
catch.levels.dir.names <- c("1_0",
                            "2_180000",
                            "3_300000",
                            "4_350000",
                            "5_400000",
                            "6_428000",
                            "7_500000",
                            "8_stableCatch",
                            "9_SPR100",
                            "10_DefaultHR")

reload.models <- readline(prompt = "Reload models (only necessary first time or if you add new models to the models directory)? [y/n] ")
if(reload.models == "y" | reload.models == "Y"){
  smart.load <- readline(prompt = "   Use smart load (will only reload newly-added models, thus keeping any forecasting done previously) ? [y/n] ")
  if(smart.load != "y" & smart.load != "Y"){
    sure <- readline(prompt = "      Are you sure (your entire models list will be deleted and re-populated) ? [y/n] ")
    if(sure != "y" & sure != "Y"){
      stop("I'm stopping because you aren't sure. Re-source to try again.\n\n")
    }
  }
}
run.forecasts <- readline(prompt = "Run forecasting for base model (only necessary first time or if you add answered 'y' to the previous question [takes 10 minutes])? [y/n] ")
run.partest <- readline(prompt = "Run partest for base model (only necessary first time or if you add answered 'y' to the first question [takes 15 minutes])? [y/n] ")

cat("\nLoading all data tables (csv files) from ", data.path,"\n")
catches <- load.catches(file.path(data.path, catch.data.file))
landings.vs.tac <- catches[[2]]
catches <- catches[[1]]
survey.history <- load.survey.history(file.path(data.path, survey.history.file))
further.tac <- further.tac.details(file.path(data.path, further.tac.file))
cat("All data tables have been loaded ", data.path,"\n")

if(reload.models == "y" | reload.models == "Y"){
  cat("\n\nLoading models...\n\n")
  if(!exists("models")){
    models <- NULL
  }
  if(smart.load == "y" | smart.load == "Y"){
    smart.load <- TRUE
  }else{
    smart.load <- FALSE
  }
  models <- load.models(models.path, yr = end.yr, smart.load = smart.load, model.list = models)
  cat("\n\nAll models have been loaded.\n\n")
}else{
  cat("\n\nModels have NOT been loaded.\n\n")
}

if(run.forecasts == "y" | run.forecasts == "Y"){
  cat("\n\nRunning forecasts for model located in ",models[[base.model.ind]]$path,"...\n\n")
  forecasts.path <- file.path(models[[base.model.ind]]$path, "mcmc", "forecasts")

  forecasts <- calc.forecast(models[[base.model.ind]]$mcmc,
                             models[[base.model.ind]]$path,
                             forecast.yrs,
                             catch.levels,
                             catch.levels.dir.names,
                             probs = forecast.probs)

  models[[base.model.ind]]$forecasts$biomass <- forecasts[[1]]
  models[[base.model.ind]]$forecasts$spr <- forecasts[[2]]
  models[[base.model.ind]]$forecasts$mcmccalcs <- forecasts[[3]]
  models[[base.model.ind]]$forecasts$outputs <- forecasts[[4]]

  ## calc.risk assumes the forecasting step was done correctly
  risks <- calc.risk(models[[base.model.ind]]$forecasts$outputs,
                     forecast.yrs,
                     catch.levels,
                     catch.levels.dir.names)

  models[[base.model.ind]]$risks <- risks

  cat("\n\nForecast calculations completed.\n\n")
}

if(run.partest == "y" | run.partest == "Y"){
  run.partest.model(models[[base.model.ind]], output.file = "model-partest.RData")
}

## A simpler variable for the base model
base.model <- models[[base.model.ind]]
cat("Base model is ",base.model$path,"\n\n")

## Bridge model indices are used to tell knitr which elements of the models list are to
## be plotted together.
bridge.model.inds <- 1:7
## For the 4-panel plot showing details of only two, the old base and the updated data
bridge.model.detail.inds <- c(1,7)

## Bridge model names will be used to make the bridge model plot and its caption.
## Make sure this is the same length as bridge.model.inds
bridge.model.names <- c(paste0("Hake ", end.yr-1),
                        paste0("Update pre-",end.yr-1," catch"),
                        paste0("Update pre-",end.yr-1," fish comps"),
                        paste0("Update pre-",end.yr-1," wt-age"),
                        paste0("Update pre-",end.yr-1," survey"),
                        paste0("Add ",end.yr-1," catch and age"),
                        paste0("Add ",end.yr-1," survey"))
## For the 4-panel plot showing details of only two, the old base and the updated data
bridge.model.detail.names <- c(paste0("Hake ", last.assess.yr),
                               paste0("Add ",end.yr-1," data"))


## Attainment, used in the management performance section
usa.last.5.years.attainment <- fmt0(mean(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-5):(end.yr-1),8]), 1)
can.last.5.years.attainment <- fmt0(mean(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-5):(end.yr-1),9]), 1)
tot.last.5.years.attainment <- fmt0(mean(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-5):(end.yr-1),10]), 1)
tot.last.10.years.attainment <- fmt0(mean(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-10):(end.yr-1),10]), 1)

## last year's values (mostly for the one-page-summary and introduction)
last.year.landings <- fmt0(as.numeric(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$TOTAL), 1)
last.year.tac <- fmt0(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$TAC)
last.year.attained <- fmt0(as.numeric(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$ATTAIN), 1)

last.year.us.attained <- fmt0(as.numeric(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$USATTAIN), 1)
last.year.us.not.attained <- fmt0(as.numeric(100 - landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$USATTAIN), 1)
last.year.us.not.attained.tonnes <- filter(landings.vs.tac, Year == last.data.yr)$TACUSA - filter(landings.vs.tac, Year == last.data.yr)$Ustotal
last.year.us.tac <- landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$TACUS
   # Not doing fmt0 here since want to do further calculations
last.year.us.non.tribal <- last.year.us.tac * (1-0.175) - 1500
last.year.us.tribal.quota.reallocated <- filter(further.tac, Year == last.data.yr)$us.tribal.quota.reallocated
last.year.us.tribal.reallocate.dates <- filter(further.tac, Year == last.data.yr)$us.tribal.reallocate.dates
last.year.us.tribal.max.landed <- filter(further.tac, Year == last.data.yr)$us.tribal.max.landed

last.year.can.attained <- fmt0(as.numeric(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$CANATTAIN), 1)   # the percentage
last.year.can.landings <- fmt0(as.numeric(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$CANtotal))
last.year.can.tac <- fmt0(landings.vs.tac[landings.vs.tac$Year %in% (end.yr-1),]$TACCAN)
latest.year.can.jv <- max(filter(catches, CAN_JV > 0)$Year)  # latest year of JV in Canada
last.year.can.shore <- fmt0(filter(catches, Year == last.data.yr)$CAN_Shoreside)
last.year.can.freezer <- fmt0(filter(catches, Year == last.data.yr)$CAN_FreezeTrawl)
years.Can.JV.catch.eq.0.recent = years.Can.JV.catch.eq.0(catches)





## New depletion and spawning biomass estimates
curr.depl.lower <- fmt0(base.model$mcmccalcs$dlower[names(base.model$mcmccalcs$dlower) %in% end.yr] * 100, 1)
curr.depl.median <- fmt0(base.model$mcmccalcs$dmed[names(base.model$mcmccalcs$dmed) %in% end.yr] * 100, 1)
curr.depl.upper <- fmt0(base.model$mcmccalcs$dupper[names(base.model$mcmccalcs$dupper) %in% end.yr] * 100, 1)

curr.bio.lower <- fmt0(base.model$mcmccalcs$slower[names(base.model$mcmccalcs$slower) %in% end.yr], 3)
curr.bio.median <- fmt0(base.model$mcmccalcs$smed[names(base.model$mcmccalcs$smed) %in% end.yr], 3)
curr.bio.upper <- fmt0(base.model$mcmccalcs$supper[names(base.model$mcmccalcs$supper) %in% end.yr], 3)

## First forecast year depletion and spawning biomass estimates
fore.tac.mcmc <- base.model$forecasts$mcmccalcs[[catch.tac.ind]]
next.depl.lower.tac.based <- fmt0(fore.tac.mcmc$dlower[names(fore.tac.mcmc$dlower) %in% (end.yr + 1)] * 100, 1)
next.depl.median.tac.based <- fmt0(fore.tac.mcmc$dmed[names(fore.tac.mcmc$dmed) %in% (end.yr + 1)] * 100, 1)
next.depl.upper.tac.based <- fmt0(fore.tac.mcmc$dupper[names(fore.tac.mcmc$dupper) %in% (end.yr + 1)] * 100, 1)

next.bio.lower.tac.based <- fmt0(fore.tac.mcmc$slower[names(fore.tac.mcmc$slower) %in% (end.yr + 1)] * 100, 1)
next.bio.median.tac.based <- fmt0(fore.tac.mcmc$smed[names(fore.tac.mcmc$smed) %in% (end.yr + 1)] * 100, 1)
next.bio.upper.tac.based <- fmt0(fore.tac.mcmc$supper[names(fore.tac.mcmc$supper) %in% (end.yr + 1)] * 100, 1)

## Second forecast year depletion and spawning biomass estimates
next2.depl.lower.tac.based <- fmt0(fore.tac.mcmc$dlower[names(fore.tac.mcmc$dlower) %in% (end.yr + 2)] * 100, 1)
next2.depl.median.tac.based <- fmt0(fore.tac.mcmc$dmed[names(fore.tac.mcmc$dmed) %in% (end.yr + 2)] * 100, 1)
next2.depl.upper.tac.based <- fmt0(fore.tac.mcmc$dupper[names(fore.tac.mcmc$dupper) %in% (end.yr + 2)] * 100, 1)

next2.bio.lower.tac.based <- fmt0(fore.tac.mcmc$slower[names(fore.tac.mcmc$slower) %in% (end.yr + 2)] * 100, 1)
next2.bio.median.tac.based <- fmt0(fore.tac.mcmc$smed[names(fore.tac.mcmc$smed) %in% (end.yr + 2)] * 100, 1)
next2.bio.upper.tac.based <- fmt0(fore.tac.mcmc$supper[names(fore.tac.mcmc$supper) %in% (end.yr + 2)] * 100, 1)

## Vector of 1-10 in words, to use in the command afterwards in introduction.rnw
numbers.as.words <- c("one", "two", "three", "four", "five", "six", "seven",
    "eight", "nine", "ten")
low.catches.since.1996 <- numbers.as.words[length(filter(catches, TOTAL <= 200000, Year > 1986)$Year)]

## Age composition data for data section
survey.age.years <- base.model$dat$agecomp[base.model$dat$agecomp$FltSvy == 2,]$Yr
max.survey.age.prop <- make.age.comp.bubble.plot(base.model,
                                                 subplot = 2,
                                                 show.key = TRUE,
                                                 start.yr = 1975,
                                                 key.yrs = c(1990, 1994, 1998, 2002),
                                                 do.plot = FALSE)
max.fishery.age.prop <- make.age.comp.bubble.plot(base.model,
                                                  subplot = 1,
                                                  do.plot = FALSE)
