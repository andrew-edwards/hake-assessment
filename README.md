____
# hake-assessment

**Updated January 17, 2018**

A framework which uses latex and knitr code to build the US/Canadian Pacific hake assessment.

_____________________________________________________________


## Prerequisites
* MikTex 2.9 for Windows - the first time you try to run, many packages will be installed automatically.
  This takes some time so make sure you have a fast connection.
* R (version 3.5.1 "Feather Spray")
* R Packages (will be installed automatically if they are not present):
    * caTools
    * coda
    * cowplot
    * date
    * devtools
    * dplyr
    * ggplot2
    * grid
    * gridExtra
    * gtools
    * kableExtra
    * knitr
    * lubridate
    * maps
    * maptools
    * nwfscSurvey
    * nwfscMapping
    * PBSmapping
    * purrr
    * PBSmodelling
    * RColorBrewer
    * r4ss
    * scales
    * stringi
    * xtable

* Rscript.exe must be on your PATH if you want to use
  **Method 1 for building the document** (explained below).

---
## How to create the RData files required for the document to build

* Place all model directories in the **models** directory. The base model must have an **mcmc** subdirectory;
  its main directory holds the MPD run and the mcmc subdirectory holds the mcmc run for the same model. The
  model directory can contain models which aren't used in the assessment, as the ones used are set in the
  **model-setup.r** file.

* Navigate to the doc/r directory and setup the model by editing the three files **model-setup.r**,
  **forecast-catch-levels.r**, and **retrospective-setup.r**:

* ***To build the RData files for the the base model and all other models with mcmc folders,
  run the batch file `build-rdata-files.bat`. This will take a long time as it is running forecasting,
  retrospectives, and extra-mcmc routines. Note that this file needs to be custom-made each year as it
  calls the build() function for individual models.*** If the script does not work then make sure the directory that Rscript resides in is in your PATH (e.g. C:\Pfiles\R\R-3.5.1\bin\).

* Once the batch file above has been run and finished, you need to build the RData files for the the
  models with only MLE runs (they don't have an mcmc folder in them). Run the following:
  ```R
    source(file.path(here::here(), "R/all.r"))
    build()
  ```

  * Once finished, you can see that each model defined in **model-setup.r**
    now has an RData file inside its directory with the same name.

  * If **build()** is called without arguments, any RData files which do not exist
    in their model directories will be built from the model outputs, i.e. no
    forecasting, retrospectives, or extra mcmc output will be run.

  * To delete all existing Rdata files and rebuild them again from the model outputs,
    run the following:
    ```R
      source(file.path(here::here(), "R/all.r"))
      delete.rdata.files()
      build()
    ```

  * To re-run items for a given model (deleting previous ones), do the following:
  ```R
    build(run.fore = TRUE, run.retro = TRUE, run.extra.mcmc = TRUE, model.name = "model-directory-name")
  ```

## How to create hake-assessment.pdf

* **The RData files must have been created using the method above before the document can
  be built.**

* **Method 1 for building the document** (Without an R interpreter):
  This method is simpler to run, and all logs are recorded into logfiles which can be
  viewed and searched when errors occur.

  * Navigate to the doc subdirectory and run the **buildtex.bat** file.
  * To see the output from the knitr part of the process, look at the file **knitrOutput.log**.
  * To see the output from the Latex part of the process, look at the file **latexOutput.log**.
  * If the compilation seems to hang, check the two log files to see where it stopped.

* **Method 2 for building the document** (With an R interpreter):
  This method is faster after the first time, because the models will already be loaded into the
  workspace and won't be reloaded every time you build the document.

  * Run the following:
    ```R
      source(file.path(here::here(), "R/all.r"))
      setwd(file.path(here::here(), "doc"))
      build.doc()
    ```

  * After the first time you do this, the models will be loaded into the R workspace.
    You can then edit hake-assessment.rnw and set the first knitr code chunk up so that it doesn't
    load the models every time you build the document. The value in the if statement should be changed to FALSE (remember to change it back before committing):

    ```R
      if(TRUE){
        load.models.into.parent.env()
      }
    ```
* To clean up the build, including removal of the cached figures and tables, run the **freshtex.bat** batch file,
  or manually delete the **knitr-cache** directory. If you don't do this, figures and tables built previously
  will be used. To keep the cached figures and tables, but remove all other traces of the build including the PDF,
  run **cleantex.bat**.

## If you get unobvious errors that prevent it building

* Try deleting .RData file for the base case. Could be to do with the forecasts.

* The error during **one-page-summary.rnw** that says **object 'catch.limit.quantiles' not found** is because projections haven't built properly. Chris/Ian fixed this on 23-01-2018 (it was building fine on morning of 19-01-2018 before a new **models/2018.18\_temporary\_base/** was uploaded).


## How to delete all model RData files

* Run the following:
  ```R
    source(file.path(here::here(), "R/all.r"))
    delete.rdata.files()
  ```
* Before you try to build the document again, you will need to run the **build()** function again with
  all options set to **FALSE** or no arguments to re-create the RData files.

## How to debug functions used in the knitr chunks in the **.rnw** files

* Open R and use this one-liner so that you can use the R history (up and down-arrows)
  This is important while debugging the R code, because you will need to run this each
  time you make a change in the code and want to test it, or if you insert a **browser()** command somewhere:
  ```R
	source(file.path(here::here(), "R/all.r"));load.models.into.parent.env();source(file.path(here::here(), "R/custom-knitr-variables.r"))
  ```
* Cut-and-paste the figure/table code from the knitr chunk you want to debug into R and the output will be exactly
  what will appear in the document.

## Installation of R packages

* The code will automatically install packages from CRAN or GitHub - see the **install.packages.if.needed()** function
  in **doc/r/r-functions/utilities.r** and the calls to it in **all.r**. Packages won't be updated though. If
  something doesn't work, try to update the **r4ss** package manually as it changes frequently:
  ```R
    devtools::install_github("r4ss/r4ss")
  ```
  Other packages may have issues like this, but we have not come across that situation so far.

---

## How the R environment is set up

* When the document is built, all of the model RData files which were previously built are loaded into the workspace
  that is seen by **knitr**. All the lengthy R processes are done ahead of time from the **build()** function to make the
  document building quick, since RData files are loaded instead of raw model output.

The following depicts the object structure of each model's .RData file:

```R
model$          - All the objects as read in by the SS_output function in the r4ss package
model$retros    - A list of MLE retrospective outputs from SS_output
model$retros[[1]] - Model run with one year removed
model$retros[[2]] - Model run with two years removed
...
model$retros[[N]] - Model run with N years removed (depends on user input when sourcing all.r)

model$forecasts - A list of forecasts, 1 for each year from the mcmc run of the model
model$forecasts[[1]] - A list, one element for each catch level forecasted for the first year forecast
model$forecasts[[1]][[1]] - A list of 4 items (see below) for the first forecast level for the first year forecast
model$forecasts[[1]][[2]] - A list of 4 items (see below) for the second forecast level for the first year forecast
...
model$forecasts[[1]][[N]] - A list of 4 items (see below) for the last forecast level for the first year forecast
  model$forecasts[[1]][[N]]$outputs   - List of mcmc outputs from the forecast models as read in by the SSgetMCMC function
  model$forecasts[[1]][[N]]$mcmccalcs - Calculations done on the mcmc outputs for this forecast model. Same structure as below.
  model$forecasts[[1]][[N]]$biomass   - Forecasts for biomass. The rows are labelled by forecast year.
  model$forecasts[[1]][[N]]$spr       - Forecasts for SPR. The rows are labelled by forecast year.
model$risks     - A list, one element for each forecast year except the last year
  model$risks[[1]] - Holds the risk values for the first year of forecasts
  model$risks[[2]] - Holds the risk values for the second year of forecasts
  ...
  model$risks[[N]] - Holds the risk values for the last year - 1 of forecasts
model$extra.mcmc- Extra MCMC output obtained by running MLE once for each MCMC sample and extracting output
  model$extra.mcmc$agedbase$Exp         - median of posterior for expected value for age comps
  model$extra.mcmc$agedbase$Exp.025     - 2.5% of posterior for expected value for age comps
  model$extra.mcmc$agedbase$Exp.975     - 97.5% of posterior for expected value for age comps
  model$extra.mcmc$agedbase$Pearson     - median of posterior for pearson residuals for age comps
  model$extra.mcmc$agedbase$Pearson.025 - 2.5% of posterior for pearson residuals for age comps
  model$extra.mcmc$agedbase$Pearson.975 - 97.5% of posterior for pearson residuals for age comps
  model$extra.mcmc$cpue.table           - Table of cpue index values for all posteriors (survey)
  model$extra.mcmc$cpue.median          - median of posterior for cpue index values (survey)
  model$extra.mcmc$cpue.025             - 2.5% of posterior for cpue index values (survey)
  model$extra.mcmc$cpue.975             - 97.5% of posterior for cpue index values (survey)
  model$extra.mcmc$like.info            - Likelihood values for all posteriors
model$path      - The path where this model is located
model$ctl.file  - control file name for this model
model$dat.file  - data file name for this model
model$dat       - data file as read in by the SS_readdat function in the r4ss package
model$mcmc      - mcmc output from the model as read in by the SSgetMCMC function or NULL if none for this model
model$mcmcpath  - The path where this mcmc model is located
model$mcmccalcs - calculations done on the mcmc outputs for this model
  model$mcmccalcs$svirg     - SSB virgin biomass, vector of length 3 (2.5%, 50%, 97.5%)
  model$mcmccalcs$sinit     - SSB initial biomass, vector of length 3 (2.5%, 50%, 97.5%)
  model$mcmccalcs$slower    - SSB lower confidence (2.5%)
  model$mcmccalcs$smed      - SSB median (50%)
  model$mcmccalcs$supper    - SSB upper confidence (97.5%)
  model$mcmccalcs$dlower    - Depletion lower confidence (2.5%)
  model$mcmccalcs$dmed      - Depletion median (50%)
  model$mcmccalcs$dupper    - Depletion upper confidence (97.5%)
  model$mcmccalcs$rvirg     - Virgin recruitment, vector of length 3 (2.5%, 50%, 97.5%)
  model$mcmccalcs$rinit     - Initial recruitment, vector of length 3 (2.5%, 50%, 97.5%)
  model$mcmccalcs$runfished - Unfished recruitment, vector of length 3 (2.5%, 50%, 97.5%)
  model$mcmccalcs$rlower    - Recruitment lower confidence (2.5%)
  model$mcmccalcs$rmed      - Recruitment median (50%)
  model$mcmccalcs$rupper    - Recruitment upper confidence (97.5%)
  model$mcmccalcs$devlower  - Recruitment deviations lower confidence (2.5%)
  model$mcmccalcs$devmed    - Recruitment deviations median (50%)
  model$mcmccalcs$devupper  - Recruitment deviations upper confidence (97.5%)
  model$mcmccalcs$plower    - SPR lower confidence (2.5%)
  model$mcmccalcs$pmed      - SPR median (50%)
  model$mcmccalcs$pupper    - SPR upper confidence (97.5%)
  model$mcmccalcs$flower    - Fishing mortality lower confidence (2.5%)
  model$mcmccalcs$fmed      - Fishing mortality median (50%)
  model$mcmccalcs$fupper    - Fishing mortality upper confidence (97.5%)
```

These are the other variables in the global workspace. These can be directly referenced using \Sexpr{} in inline latex code,
or in a knitr code chunk. Here are a few of the obvious ones, there are many more in the **custom-knitr-variables.r** file,
which is where any new ones should be placed.

```R
base.model              - The base model object.
unfished.eq.yr          - Unfished equilibrium year. For hake, this is before the start year.
start.yr                - Start year for the model.
end.yr                  - End year for the model.
survey.start.yr         - First survey year included in the model.
survey.end.yr           - Last survey year included in the model.
assess.yr               - The current assessment year.
last.assess.yr          - The last year in which an assessment was done.
forecast.yrs            - A vector of years to forecast for decision tables (e.g. 2015:2017).
catch.levels            - A list of lists of forecast catch levels and their names and directory names..
catch.default.policy    - A vector of catch limits for the forecast years which corresponds to the default harvest rate.
data.path               - The absolute path to the data folder, which holds catch and tac tables.
models.path             - The absolute path to the models folder, which holds sub-directories for the models which have been run.
```

__Quick look at model output__

Open R within the model's folder and use the R commands:

	require(r4ss)
	SS_plots(SS_output("./"))

This creates figures and an HTML page with tabs for sets of figures. This is useful for quickly
looking at results, especially when MCMCs have not yet been run and so the assessment document
will not build yet.

---

## Survey map

For 2018, Julia Clemons produced the multi-year panel plots from the surveys. Andy converted to .eps using

```
pdf2ps <filename>.pdf <filename>.eps
```

which is a ghostscript command. Seems to be fine in document (may not be a properly encapsulated .eps, but we resize it anyway and it looks good and is zoomable).

## **Everything from here on is from the 2016 assessment period (Nov 2015 - Mar 2016)**

## How Andy is running it (and see Chris's notes above)

- download from Hake JTC Google Drive the model runs, and put in **hake-assessment\models\** (then 'unzip to here', then remove the .zip file so that **models\** just has the required subdirectories).
- **source("all.r")** to reload models and data files and for any changes to R code.
- delete **knitr-cache** directory if any tables or figures need to be updated
- **knit("hake-assessment.rnw")** [or use Chris's batch file - at first I just want to see the warnings]
- **latex hake-assessment.tex** and **dvips** and **bibtex** if necessary
- **ispell hake-assessment.tex** periodically


__GitHub workflow__

- I forked Chris's master repository, and did **git remote add cgrandin https://github.com/cgrandin/hake-assessment** [and he added me to his] so that we can merge each other's commits. **git remote -v** shows that.
- **Allan/Aaron**: to merge my commits (for when Chris isn't on top of it) do:
-
       git remote add aedwards https://github.com/andrew-edwards/hake-assessment

  just once (git will remember this for future sessions).
- Then do **git fetch** and **merge** as described below, but with **aedwards** instead of **cgrandin**. Note that **aedwards** is just what you call my repository on your machine, it doesn't have to match my user name.


- **git com** and **git push** often [I'm using Chris's **git-workshop** shortcuts]
- **git fetch cgrandin** - fetches his latest version
- **git diff cgrandin/master** shows me the differences between his and mine. :
-- + green is on mine not his, red is his not mine [seems like it can look like I've added something but really Chris has removed it; and when merging it should base it on the most recent commits]
- **git merge cgrandin/master** merges our versions.
- remove **knitr-cache** directory, re-run **source("all.r")** and re-run **knitr** to make sure it all still works (I kept forgetting this before pushing).
- Then **git push**.
- When you get a conflict, open the file in an editor and it has <<<<<<   for the start of a conflicting part, and ========= at the end, so manually fix it. Then **git add <filename>** to confirm that's the one you want (not completely obvious), then commit. See <https://help.github.com/articles/resolving-a-merge-conflict-from-the-command-line/>
- We will try and work on different files so that there are no conflicts when we merge.


**Undoing a merge**

Just merged Chris's stuff (27/1/16) in but rebuilding the models doesn't work, I think because he mentioned that he had to change some structure (and he's left for the day). I tried fixing, but I don't think it worked (I'll commit this edit to the readme.md file to double check), so easiest just to ask Chris tomorrow as I need to leave soon anyway. I tried:

From http://stackoverflow.com/questions/2389361/undo-a-git-merge  trying the answer:

"Strange that the simplest command was missing. Most answers work, but undoing the merge you just did, this is the easy and safe way:

git reset --merge ORIG_HEAD

The ref ORIG_HEAD will point to the original commit from before the merge."

So I get ORIG_HEAD from doing  git lg

git reset --merge 33489f0

**Running MCMC in SS**

Copy and paste all model output files into new mcmc/ directory. Change starter file to reduce output to screen using:

        0       # DOS display detail: 0,1,2

***Commands used in 2017:***

        ss3 -mcmc 12000000 -mcsave 10000 -mcseed 36519
        ss3 -mceval

Commands used for "2018.18_temporary_base" and “2018.19_add_2017_tv_select” models just to get some MCMC results:

        ss3 -mcmc 12000 -mcsave 10 -mcseed 36519
        ss3 -mceval

Where that seed is the ADMB default. Allan used -mcseed 5242 but there's no reason why that seed is better than any other.

The 12 million samples saving 1 in every 10 thousand results in 1200 samples saved.

These values are then been combined with starter.ss values of

        201     # MCMC burn-in
        1       # MCMC thinning interval

which will remove the first 201 samples of the 1200 saved (which corresponds to the first 2.01 million in the chain of 12 million) and result in 999 samples reported in the posteriors.sso file.

***Commands for 2018:***

        ss3 -mcmc 24000000 -mcsave 10000 -mcseed 36519
        ss3 -mceval

The 24 million samples saving 1 in every 10 thousand results in 2400 samples saved.
These values are then been combined with starter.ss values of

        400     # MCMC burn-in
        1       # MCMC thinning interval

to get 2000 total samples.

Ran a second chain in 2018 with alternative seed to compare multi-chain convergence diagnostics

        ss3 -mcmc 24000000 -mcsave 10000 -mcseed 89041
        ss3 -mceval

Note: changing value in starter file to "0 # run display detail (0,1,2)" may
speed up the MCMC a tiny bit.

***Commands for 2019:***

        ss3 -mcmc 24000000 -mcsave 10000 -mcseed 36519
        ss3 -mceval

The 24 million samples saving 1 in every 10 thousand results in 2400 samples saved.
These values are then been combined with starter.ss values of

        400     # MCMC burn-in
        1       # MCMC thinning interval

to get 2000 total samples.

Ran a second chain in 2019 with alternative seed to compare multi-chain convergence diagnostics

        ss3 -mcmc 24000000 -mcsave 10000 -mcseed 91438
        ss3 -mceval

Once the MCMC has finished, copy all the files into a new **mcmc/** folder, run **clean.bat** and run **ss3.exe** to generate the MPD results.

__Andy's other notes__

- Network graph - I just [25 Jan 2016, commit number 7e25a5c] merged Chris's, but this doesn't show up on his or my Network graphs, I think because he had merged all my commits earlier, and I hadn't committing anything since. So it's not really merging (and there was no possibility for a conflict because I hadn't changed anything since he merged mine), just updating.

- Use text in main document of last year's, and start converting to .tex.
- Table 1 and 2 of last year's .pdf -- values should be in **catches**, see **make-catches-table.r** in **catches.r** for an earlier table, and modify to make new ones.
- if just editing the placement (and maybe more) of a table that is in, say, executive-summary.rnw, then no need to delete knitr-cache. Probably.

Helpful git commands I didn't know:

**git lg1**   [or lg2] - shows commit numbers (codes)

**git log .\doc\hake-assessment.rnw**  - show revision history for a file (syntax not quite right there)

**git checkout <enough numbers of the commit reference to make it unique> .\doc\[filename.rnw] **  - revert back to that version of that file, I think...

[I can delete this once I know it all automatically] GitHub Colors are explained under The Prompt in the README shown at https://github.com/dahlbyk/posh-git/ . To summarize:

- Cyan means the branch matches its remote
- Green means the branch is ahead of its remote (green light to push)
- Red means the branch is behind its remote
- Yellow means the branch is both ahead of and behind its remote

The +~-! status represents added/modified/removed/conflicted file count in your index (dark green) and/or working directory (dark red).


Steps to create decision and metrics tables for the hake assessment
===================================================================
*Copied from an issue comment made by Allan H., February 2016*

Create folders for
- decision table runs
- next year metrics
- second year metrics

*Decision table runs*
---------------------


Next year metrics
------------------
This is the metrics for a fixed catch in the next year (i.e., for the 2016 assessment, this is the 2016 catch).  In the forecast file, put in the next year's fixed catch. Make sure to enter only next year's catch so that the catch can be determined for the second year and compared to.

Second year metrics
-------------------
This is the metrics for the two year forecast. Enter catch for the next two years in the forecast file.

*Catch Levels*
--------------
A fixed catch level is easy because you simply enter that catch level. There are a few catch levels that are determined based on specific states. These are listed below and how to determine them.

- B~curr~ = B~nextYr~ : This is the catch that results in an equal probability that the biomass in the current year is equal to the biomass in the next year.  You must iteratively modify the catch until the metric for P(BnextYr>Pcurr) is 50%.  Don't forget to run mceval after modifying the forecast file.
- med(B~curr~) = med(B~nextYr~) : This is the catch that results in the median spawning biomass next year to equal the median spawning biomass for this year. Iteratively modify the catch until the median spawning biomasses are approximately equal.  Don't forget to run mceval after modifying the forecast file.
- Stable Catch (Ccurr=CnextYr): This is the catch that results in teh default harvest rule catch for the next being the same. Iteratively enter the catch for the curent year until the median catch next year is the same.  Don't forget to run mceval after modifying the forecast file.
- SPR ratio=100%: This is the catch that results in a median SPR ratio (Fishing Intesity) of 100%. The default harvest rate catch may not have an Fishing Intensity of 100% because of time-varying selectivity, growth (i.e., weight-at-age), etc.  This gives an indication of the current pattern of fishing and how it relates to the benchmark population.  Iteratively search for the catch that results in a median SPR ratio of 1.  Don't forget to run mceval after modifying the forecast file.
- Default harvest rule: The catch determined by the default harvest rule. Simply copy the median ForeCatch caluclated by SS into the forecast file, so that every mceval uses that fixed catch. Don't forget to run mceval after modifying the forecast file.

*NOTE*: for second year metrics, fix the first year to determine the second year (i.e., fix 2015 catch at median default harvest rate catch, to determine the median default harvest catch for 2016).

Decision Tables
---------------
For decision tables, you will need to enter in catches for every year (different than metrics). The R code that will create the directories and forecast files with the catch levels and then run the mceval for each folder is located in **doc/r/load-models.r**

*NOTE*: you can have a zero catch, except for the final forecast year, so I usually enter 0.01 for zero catch.

With the decision tables displaying Bratio and SPR, the final year of forecasted catch is only pertinent for SPR, since Bratio is beginning of the year.
