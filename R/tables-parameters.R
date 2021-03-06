make.parameters.estimated.summary.table <- function(model,
                                                    start.rec.dev.yr,
                                                    end.rec.dev.yr,
                                                    digits = 3,
                                                    xcaption = "default",
                                                    xlabel   = "default",
                                                    font.size = 9,
                                                    space.size = 10,
                                                    return.xtable = TRUE){
  ## Returns an xtable for the parameters estimated summary
  ##
  ## model - an mcmc run, output of the r4ss package's function SSgetMCMC()
  ## start.rec.dev.yr - first year of estimated recruitment devs
  ## end.rec.dev.yr - last year of estimated recruitment devs
  ## digits - number of decimal points for the estimates
  ## xcaption - caption to appear in the calling document
  ## xlabel - the label used to reference the table in latex
  ## font.size - size of the font for the table
  ## space.size - size of the vertical spaces for the table
  ## return.xtable - if TRUE, return an xtable, if FALSE return R data frame

  ## Column indices for the values as found in the control file
  lo <- 1
  hi <- 2
  init <- 3
  p.mean <- 4 ## prior mean
  p.sd <- 5   ## prior sd
  p.type <- 6 ## prior type
  phase <- 7
  start.yr.sel <- 10
  end.yr.sel <- 11
  sel.dev.sd <- 12

  prior.type <- c("0" = "Uniform",
                  "-1" = "Uniform",
                  "2" = "Beta",
                  "3" = "Lognormal")

  fetch.and.split <- function(ctl, x){
    ## Fetch the line x from the vector ctl and split it up, removing spaces.
    ## Also remove any leading spaces
    ## Return the vector of values
    j <- ctl[x]
    ## Remove inter-number spaces
    j <- strsplit(j," +")[[1]]
    ## Remove leading spaces
    j <- j[j != ""]
    return(j)
  }

  fetch.prior.info <- function(vals,
                               digits = 2){
    ## Looks at the prior type p.type and phase, and if uniform will return
    ##  "Uniform"
    ## If not uniform, it will parse the vals and build a string defining
    ##  the prior info.
    ## If Fixed, it will return the initial value
    ## If Lognormal, it will parse the vals and build a string defining the
    ##  prior info, with the exp function applied
    if(vals[p.type] < 0 & vals[phase] > 0){
      ## Uniform prior on estimated parameter
      return("Uniform")
    }
    if(vals[p.type] < 0 & vals[phase] < 0){
      ## Fixed parameter
      return(vals[init])
    }
    if(prior.type[vals[p.type]] == "Lognormal"){
      return(paste0(prior.type[vals[p.type]], "(",
                    f(exp(as.numeric(vals[p.mean])), digits), ",",
                    f(exp(as.numeric(vals[p.sd])), digits), ")"))
    }
    return(paste0(prior.type[vals[p.type]], "(",
                  f(as.numeric(vals[p.mean]), digits), ",",
                  f(as.numeric(vals[p.sd]), digits), ")"))
  }

  ctl <- model$ctl
  # Remove preceeding and trailing whitespace on all elements,
  #  but not 'between' whitespace.
  ctl <- gsub("^[[:blank:]]+", "", ctl)
  ctl <- gsub("[[:blank:]]+$", "", ctl)
  ## Remove all lines that start with a comment
  ctl <- ctl[-grep("^#.*", ctl)]

  ## R0 is at line 46 of comment-stripped dataframe. Get it's values which can
  ##  be indexed by the variables defined above
  r0 <- fetch.and.split(ctl, 46)
  r0.vals <- c(paste0("Log(",
                      latex.subscr(latex.italics("R"),
                                   "0"),
                      ")"),
               1,
               paste0("(", r0[lo], ",", r0[hi], ")"),
               prior.type[r0[p.type]])

  ## Steepness is at line 47 of comment-stripped dataframe
  h <- fetch.and.split(ctl, 47)
  h.vals <- c(paste0("Steepness (",
                     latex.italics("h"),
                     ")"),
              1,
              paste0("(", h[lo], ",", h[hi], ")"),
              fetch.prior.info(h, digits))

  ## Recruitment variability (sigma_r) is at line 48 of comment-stripped dataframe
  sig.r <- fetch.and.split(ctl, 48)
  sig.r.vals <- c(paste0("Recruitment variability (",
                         latex.italics("$\\sigma_r$"),
                         ")"),
                  if(sig.r[p.type] < 0 & sig.r[phase] > 0)
                    1
                  else
                    "--",
                  if(sig.r[p.type] < 0 & sig.r[phase] > 0)
                    paste0("(", sig.r[lo], ",", sig.r[hi], ")")
                  else
                    "--",
                  sig.r[3])
                  ##fetch.prior.info(sig.r, digits))

  ## Recruitment devs, lower and upper bound found on lines 66 and 67 of
  ##  comment-stripped dataframe
  ## The number of them comes from the arguments to this function (for now)
  rec.dev.lb <- fetch.and.split(ctl, 66)[1]
  rec.dev.ub <- fetch.and.split(ctl, 67)[1]
  rec.dev.vals <- c(paste0("Log recruitment deviations: ",
                           start.rec.dev.yr,
                           "--",
                           end.rec.dev.yr),
                    end.rec.dev.yr - start.rec.dev.yr + 1,
                    paste0("(",
                           rec.dev.lb,
                           ",",
                           rec.dev.ub,
                           ")"),
                    paste0("Lognormal(0,",
                           latex.italics("$\\sigma_r$"),
                           ")"))

  ## Natural mortality is at line 25 of comment-stripped dataframe
  m <- fetch.and.split(ctl, 25)
  m.vals <- c(paste0("Natural mortality (",
                     latex.italics("M"),
                     ")"),
              if(prior.type[m[p.type]] == "Fixed")
                "--"
              else
                1,
              paste0("(", m[lo], ",", m[hi], ")"),
              fetch.prior.info(m, digits))

  q.vals <- c(paste0("Catchability (",
                     latex.italics("q"),
                     ")"),
              1,
              "--",
              "Analytic solution")

  ## Survey additional value for SE is at line 77 of comment-stripped dataframe
  se <- fetch.and.split(ctl, 77)
  se.vals <- c("Additional value for survey log(SE)",
               if(prior.type[se[p.type]] == "Fixed")
                 1
               else
                 "--",
               paste0("(", se[lo], ",", se[hi], ")"),
               "Uniform")
               ##fetch.prior.info(se, digits))

  ## Number of survey selectivities is on line 81 of comment-stripped dataframe
  num.sel <- fetch.and.split(ctl, 81)
  grep.num.sel <- grep("#", num.sel)
  if(length(grep.num.sel) > 0){
    num.sel <- num.sel[1:(grep.num.sel - 1)]
  }
  num.sel <- as.numeric(num.sel[length(num.sel)])
  ## num.sel is the number of selectivity entries in the file for survey
  ## Age-0 starts on line 104 of comment-stripped dataframe
  line.num <- 104
  ages.estimated <- NULL
  for(i in line.num:(line.num + num.sel - 1)){
    age.sel <- fetch.and.split(ctl, i)
    if(age.sel[phase] > 0){
      ## This age plus one is being estimated
      ages.estimated <- c(ages.estimated, i - line.num + 1)
      ## Use the last line to get the values
      est.sel <- age.sel
    }
  }
  age.sel.vals <- c(paste0("Non-parametric age-based selectivity: ages ",
                           min(ages.estimated),
                           "--",
                           max(ages.estimated)),
                    length(ages.estimated),
                    paste0("(", est.sel[lo], ",", est.sel[hi], ")"),
                    "Uniform")
                    ##fetch.prior.info(est.sel, digits))

  ## Number of fishery selectivities is on line 80 of comment-stripped dataframe
  num.sel <- fetch.and.split(ctl, 80)
  grep.num.sel <- grep("#", num.sel)
  if(length(grep.num.sel) > 0){
    num.sel <- num.sel[1:(grep.num.sel - 1)]
  }
  num.sel <- as.numeric(num.sel[length(num.sel)])
  ## num.sel is the number of selectivity entries in the file for survey
  ## Age-0 starts on line 82 of comment-stripped dataframe
  line.num <- 82
  ages.estimated <- NULL
  for(i in line.num:(line.num + num.sel)){
    age.sel <- fetch.and.split(ctl, i)
    if(age.sel[phase] > 0){
      ## This age plus one is being estimated
      ages.estimated <- c(ages.estimated, i - line.num)
      ## Use the last line to get the values
      est.sel <- age.sel
    }
  }
  f.age.sel.vals <- c(paste0("Non-parametric age-based selectivity: ages ",
                             min(ages.estimated),
                             "--",
                             max(ages.estimated)),
                      length(ages.estimated),
                      paste0("(", est.sel[lo], ",", est.sel[hi], ")"),
                      "Uniform")
                      ##fetch.prior.info(est.sel, digits))

  ## Selectivity deviations for fishery. Uses last line to get values, assumes
  ##  all are the same
  f.age.sel.dev.vals <-
    c(paste0("Selectivity deviations (",
             est.sel[start.yr.sel],
             "--",
             est.sel[end.yr.sel],
             ", ages ",
             min(ages.estimated),
             "--",
             max(ages.estimated),
             ")"),
      length(ages.estimated) * length(est.sel[start.yr.sel]:est.sel[end.yr.sel]),
      "--",
      paste0("Normal(0,",
             ##est.sel[sel.dev.sd],
             model$parameters["AgeSel_P3_Fishery(1)_dev_se", "Value"],
             ")"))

  ## Dirichlet-Multinomial likelihood parameters
  dm <- fetch.and.split(ctl, 124)
  dm.vals <- c(paste0("Dirichlet-Multinomial likelihood (",
                       latex.italics("$\\log(\\theta)$"),
                      ")"),
               2,
               paste0("(", dm[lo], ",", dm[hi], ")"),
               "Uniform")
               ##fetch.prior.info(dm, digits))

  tab <- rbind(r0.vals,
               h.vals,
               sig.r.vals,
               rec.dev.vals,
               m.vals,
               q.vals,
               se.vals,
               age.sel.vals,
               f.age.sel.vals,
               f.age.sel.dev.vals,
               dm.vals)

  if(!return.xtable){
    return(tab)
  }

  ## Make first row empty to make the Stock Dynamics header appear below the
  ##  horizontal line
  tab <- rbind(c("", "", "", ""), tab)

  colnames(tab) <- c(latex.bold("Parameter"),
                     latex.mlc(c("Number",
                                 "estimated")),
                     latex.mlc(c("Bounds",
                                 "(low, high)")),
                     latex.mlc(c("Prior (Mean, SD)",
                                 "single value = fixed")))

  addtorow <- list()
  addtorow$pos <- list()
  addtorow$pos[[1]] <- 1
  addtorow$pos[[2]] <- 6
  addtorow$pos[[3]] <- 6
  addtorow$pos[[4]] <- 9
  addtorow$pos[[5]] <- 11
  addtorow$command <-
    c(paste0(latex.bold(latex.under("Stock Dynamics")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Catchability and selectivity")),
             latex.nline),
      paste0(latex.bold(latex.italics("Acoustic Survey")),
             latex.nline),
      paste0(latex.bold(latex.italics("Fishery")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Data weighting")),
             latex.nline))

  ## Make the size string for font and space size
  size.string <- latex.size.str(font.size, space.size)
  print(xtable(tab,
               caption = xcaption,
               label = xlabel,
               align = get.align(ncol(tab),
                                 just = "c")),
        caption.placement = "top",
        include.rownames = FALSE,
        sanitize.text.function = function(x){x},
        size = size.string,
        add.to.row = addtorow,
        table.placement = "H")
}

make.short.parameter.estimates.sens.table <- function(models,
                                                      model.names,
                                                      posterior.regex,
                                                      end.yr,
                                                      age.1 = FALSE,
                                                      digits = 3,
                                                      xcaption = "default",
                                                      xlabel   = "default",
                                                      font.size = 9,
                                                      space.size = 10,
                                                      getrecs = c(2008, 2010, 2014),
                                                      show.likelihoods = TRUE){
  ## Returns an xtable in the proper format for the MLE parameter estimates for
  ##  all the models, one for each column
  ##
  ## models - a list of models which contain the MLE output from SS_output()
  ## model.names - a vector of names of the same length as the number of
  ##  models in the models list
  ## posterior.regex - a vector of the posterior names to search for
  ##  (partial names will be matched)
  ## end.yr - the last year to include
  ## age.1 - if TRUE, add the age-1 index parameter to the table
  ## digits - number of decimal points for the estimates
  ## xcaption - caption to appear in the calling document
  ## xlabel - the label used to reference the table in latex
  ## font.size - size of the font for the table
  ## space.size - size of the vertical spaces for the table
  ## getrecs - a vector of integers supplying the years for which you want
  ##   estimates of recruitment. Must be of length three.
  ## show.likelihoods - if TRUE, return the negative log-likelihoods (FALSE for presentations)
  if (length(getrecs) != 3) stop("The make short function only works",
    "with three years of recruitments I think.")

  tab <- NULL
  for(model in models){
    parms <- model$estimated_non_dev_parameters

    p.names <- rownames(parms)
    mle.grep <- unique(grep(paste(posterior.regex, collapse="|"), p.names))

    mle.par <- parms[mle.grep,]$Value
    mle.par[2] <- exp(mle.par[2]) / 1000 ## To make R millions

    ## Add
    for (reci in getrecs) {
      mle.par <- c(mle.par,
        model$recruit[model$recruit$Yr == reci,]$pred_recr / 1000)
    }

    ## Add B0
    b0 <- model$SBzero
    b0 <- b0 / 1000 ## To make B0 in the thousands
    mle.par <- c(mle.par, b0)

    ## Add depletion for 2009
    d <- 100 * model$derived_quants[paste("Bratio", 2009, sep = "_"), "Value"]
    mle.par <- c(mle.par, d)

    ## Add depletion for end.yr
    d <- 100 * model$derived_quants[paste("Bratio", end.yr, sep = "_"), "Value"]
    mle.par <- c(mle.par, d)

    ## Add fishing intensity for last year
    fi <- model$derived_quants[paste("SPRratio", end.yr-1, sep = "_"), "Value"]
    fi <- fi * 100
    mle.par <- c(mle.par, fi)

    ## Add Female spawning biomass B_f40%
    ## Always divide SSB by 2 in single sex model, unless you grab model$SBzero
    ##  divide by 1000 to be consistent with showing biomass in thousands of tons
    b <-  model$derived_quants["SSB_SPR", "Value"] / 2 / 1000
    mle.par <- c(mle.par, b)

    ## Add SPR MSY-proxy
    mle.par <- c(mle.par, 40)

    ## Add Exploitation fraction corresponding to SPR
    f1 <- model$derived_quants["Fstd_SPR", "Value"]
    f1 <- f1 * 100
    mle.par <- c(mle.par, f1)

    ## Add Yield at Bf_40%
    y <- model$derived_quants["Dead_Catch_SPR", "Value"] / 1000
    mle.par <- c(mle.par, y)

    ## Add Likelihoods - there are 8 to 10 of them
    j <- model$likelihoods_used
    like <- model$likelihoods_used$value
    like.flt <- model$likelihoods_by_fleet
    ## Add Total and Survey likelihoods
    mle.par <- c(mle.par, like[c(1,4)])
    mle.par <- c(mle.par, as.numeric(like.flt[nrow(like.flt), c(4,3)]))
    mle.par <- c(mle.par, like[c(6,8,9)])
    ## Special case - if the sensitivity does not include steepness as
    ##  an estimated parameter, insert an NA.
    if(length(mle.par) == 21){
      mle.par <- c(mle.par[1:2],
                   NA,
                   mle.par[-(1:2)])
    }
    ## If the sensitivity does not include the age 1 index as
    ##  an estimated parameter, insert an NA.
    if(age.1 & length(mle.par) == 22){
      mle.par <- c(mle.par[1:4],
                   NA,
                   mle.par[-(1:4)])
    }

    if(is.null(tab)){
      tab <- as.data.frame(mle.par)
    }else{
      tab <- cbind(tab, mle.par)
    }
  }

  ## Format the tables rows depending on what they are
  ## Decimal values
  if(age.1){
    tab[c(1, 3, 4, 5),] <- f(tab[c(1, 3, 4, 5),], 3)
  }else{
    tab[c(1, 3, 4),] <- f(tab[c(1, 3, 4),], 3)
  }

  ## Large numbers with no decimal points but probably commas
  tab[c(2,
        ifelse(age.1, 6, 5),
        ifelse(age.1, 7, 6),
        ifelse(age.1, 8, 7),
        ifelse(age.1, 9, 8),
        ifelse(age.1, 13, 12),
        ifelse(age.1, 16, 15)),] <-
    f(apply(tab[c(2,
                  ifelse(age.1, 6, 5),
                  ifelse(age.1, 7, 6),
                  ifelse(age.1, 8, 7),
                  ifelse(age.1, 9, 8),
                  ifelse(age.1, 13, 12),
                  ifelse(age.1, 16, 15)),],
                c(1, 2), as.numeric))
  ## Percentages
  tab[c(ifelse(age.1, 10, 9),
        ifelse(age.1, 11, 10),
        ifelse(age.1, 12, 11),
        ifelse(age.1, 15, 14)),] <-
    paste0(f(apply(tab[c(ifelse(age.1, 10, 9),
                         ifelse(age.1, 11, 10),
                         ifelse(age.1, 12, 11),
                         ifelse(age.1, 15, 14)),],
                   c(1, 2), as.numeric), 1), "\\%")
  ## SPR Percentages row (some may be NA). This is really ugly but works
  tab[ifelse(age.1, 14, 13),
      !is.na(tab[ifelse(age.1, 14, 13),])] <-
    paste0(f(as.numeric(tab[ifelse(age.1, 14, 13),
                            !is.na(tab[ifelse(age.1, 14, 13),])]), 1), "\\%")

  ## Likelihoods - Possibly commas and 2 decimal points
  if(age.1){
    tab[17:23,] <-
      f(apply(tab[17:23,],
              c(1, 2), as.numeric), 2)
  }else{
    tab[16:22,] <-
      f(apply(tab[16:22,],
              c(1, 2), as.numeric), 2)
  }

  ## Make first row empty to make the Parameter header appear below the
  ##  horizontal line
  tab <- rbind(rep("", length(models)), tab)

  ## replace "   NA" with dashes
  tab <- as.data.frame(lapply(tab,
                              function(x){
                                gsub(" +NA",
                                     paste0("\\", latex.bold("--")),
                                     x)
                              }))

  ## Set the first column to be the names
  ## The first empty string is necessary because of the
  ##  rbind(rep("", length(models)), tab) call above
  if(age.1){
    tab <- cbind(c("",
                   paste0("Natural mortality (",
                          latex.italics("M"),
                          ")"),
                   paste0(latex.subscr(latex.italics("R"), "0"),
                          " (millions)"),
                   paste0("Steepness (",
                          latex.italics("h"),
                          ")"),
                   "Additional acoustic survey SD",
                   "Additional age-1 index SD",
                   paste(getrecs, "recruitment (millions)"),
                   paste0(latex.subscr(latex.italics("B"), "0"),
                          " (thousand t)"),
                   "2009 relative spawning biomass",
                   paste0(end.yr,
                          " relative spawning biomass"),
                   paste0(end.yr - 1,
                          " rel. fishing intensity: (1-SPR)/(1-",
                          latex.subscr("SPR", "40\\%"),
                          ")"),
                   paste0("Female spawning biomass (",
                          latex.italics("$B_{F_{40_{\\%}}}$"),
                          "; thousand t)"),
                   latex.subscr("SPR", "MSY-proxy"),
                   "Exploitation fraction corresponding to SPR",
                   paste0("Yield at ",
                          latex.italics("$B_{F_{40_{\\%}}}$"),
                          " (thousand t)"),
                   "Total",
                   "Survey",
                   "Survey age compositions",
                   "Fishery age compositions",
                   "Recruitment",
                   "Parameter priors",
                   "Parameter deviations"),
                 tab)
  }else{
    tab <- cbind(c("",
                   paste0("Natural mortality (",
                          latex.italics("M"),
                          ")"),
                   paste0(latex.subscr(latex.italics("R"), "0"),
                          " (millions)"),
                   paste0("Steepness (",
                          latex.italics("h"),
                          ")"),
                   "Additional acoustic survey SD",
                   paste(getrecs, "recruitment (millions)"),
                   paste0(latex.subscr(latex.italics("B"), "0"),
                          " (thousand t)"),
                   "2009 relative spawning biomass",
                   paste0(end.yr,
                          " relative spawning biomass"),
                   paste0(end.yr - 1,
                          " rel. fishing intensity: (1-SPR)/(1-",
                          latex.subscr("SPR", "40\\%"),
                          ")"),
                   paste0("Female spawning biomass (",
                          latex.italics("$B_{F_{40_{\\%}}}$"),
                          "; thousand t)"),
                   latex.subscr("SPR", "MSY-proxy"),
                   "Exploitation fraction corresponding to SPR",
                   paste0("Yield at ",
                          latex.italics("$B_{F_{40_{\\%}}}$"),
                          " (thousand t)"),
                   "Total",
                   "Survey",
                   "Survey age compositions",
                   "Fishery age compositions",
                   "Recruitment",
                   "Parameter priors",
                   "Parameter deviations"),
                 tab)
  }
  ## Need to split up the headers (model names) by words and let them stack on
  ##  top of each other
  model.names.str <- unlist(lapply(gsub(" ",
                                        "\\\\\\\\",
                                        model.names),
                                   latex.mlc,
                                   make.bold = FALSE))
  colnames(tab) <- c("", model.names.str)

  addtorow <- list()
  addtorow$pos <- list()
  addtorow$pos[[1]] <- 1
  addtorow$pos[[2]] <- ifelse(age.1, 6, 5)
  addtorow$pos[[3]] <- ifelse(age.1, 12, 11)
  addtorow$pos[[4]] <- ifelse(age.1, 17, 16)
  addtorow$command <-
    c(paste0(latex.bold(latex.under("Parameters")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Derived Quantities")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Reference Points based on $\\Fforty$")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Negative log likelihoods")),
             latex.nline))
  ## Remove likelihood rows (use for beamer to fit on slides)
  if(!show.likelihoods){
    tab <- tab[1:(grep("Total", tab[,1])-1),]
    addtorow$pos[[4]] <- NULL
    addtorow$command <- addtorow$command[-4]
  }

  ## Make the size string for font and space size
  size.string <- latex.size.str(font.size, space.size)
  print(xtable(tab,
               caption = xcaption,
               label = xlabel,
               align = get.align(ncol(tab),
                                 just = "c")),
        caption.placement = "top",
        include.rownames = FALSE,
        sanitize.text.function = function(x){x},
        size = size.string,
        add.to.row = addtorow,
        table.placement = "H")
}

make.short.parameter.estimates.table <- function(model,
                                                 last.yr.model,
                                                 posterior.regex,
                                                 end.yr,
                                                 digits = 3,
                                                 xcaption = "default",
                                                 xlabel   = "default",
                                                 font.size = 9,
                                                 space.size = 10){
  ## Returns an xtable in the proper format for the parameter estimates
  ##  for MLE vs median vs median of the last year
  ##
  ## model - an mcmc run, output of the r4ss package's function SSgetMCMC()
  ## last.yr.model - last year's base model for comparison
  ## posterior.regex - a vector of the posterior names to search for
  ##  (partial names will be matched)
  ## end.yr - the last year to include (req'd for spawning biomass)
  ## digits - number of decimal points for the estimates
  ## xcaption - caption to appear in the calling document
  ## xlabel - the label used to reference the table in latex
  ## font.size - size of the font for the table
  ## space.size - size of the vertical spaces for the table

  ## This year's model MLE
  parms <- model$estimated_non_dev_parameters
  p.names <- rownames(parms)
  mle.grep <- unique(grep(paste(posterior.regex, collapse="|"), p.names))
  mle.names <- p.names[mle.grep]

  mle.par <- parms[mle.grep,]$Value
  mle.par[2] <- exp(mle.par[2]) / 1000 ### To make R millions

  ## Add Q for MLE
  mle.q <- round(model$cpue$Calc_Q[1],3)
  mle.par <- c(mle.par, mle.q)

  ## Add 2008 recruitment
  rec <- model$recruit[model$recruit$Yr == 2008,]$pred_recr
  rec <- rec / 1000
  mle.par <- c(mle.par, rec)

  ## Add 2010 recruitment
  rec <- model$recruit[model$recruit$Yr == 2010,]$pred_recr
  rec <- rec / 1000
  mle.par <- c(mle.par, rec)

  ## Add 2014 recruitment
  rec <- model$recruit[model$recruit$Yr == 2014,]$pred_recr
  rec <- rec / 1000
  mle.par <- c(mle.par, rec)

  ## Add B0
  b0 <- model$SBzero ## Note that this is divided by 2 in a single sex model
  b0 <- b0 / 1000    ## To make B0 in the thousands
  mle.par <- c(mle.par, b0)

  ## Add depletion for 2009
  d <- 100 * model$derived_quants[paste("Bratio", 2009, sep = "_"), "Value"]
  mle.par <- c(mle.par, d)

  ## Add depletion for end.yr
  d <- 100 * model$derived_quants[paste("Bratio", end.yr, sep = "_"), "Value"]
  mle.par <- c(mle.par, d)

  ## Add fishing intensity for last year
  fi <- model$derived_quants[paste("SPRratio", end.yr - 1, sep = "_"), "Value"]
  fi <- fi * 100.0
  mle.par <- c(mle.par, fi)

  ## Add Female spawning biomass B_f40%
  ## Always divide SSB by 2 in single sex model, unless you grab model$SBzero
  ##  divide by 1000 to be consistent with showing biomass in thousands of tons
  b <- model$derived_quants["SSB_SPR", "Value"] / 2 / 1000
  mle.par <- c(mle.par, b)

  ## Add SPR MSY-proxy
  mle.par <- c(mle.par, 40)

  ## Add Exploitation fraction corresponding to SPR
  f1 <- model$derived_quants["Fstd_SPR", "Value"]
  f1 <- 100 * f1 ## make a percentage
  mle.par <- c(mle.par, f1)

  ## Add Yield at Bf_40%
  y <- model$derived_quants["Dead_Catch_SPR", "Value"] / 1000
  mle.par <- c(mle.par, y)

  calc.mcmc <- function(x,
                        q.choice = 1 ## q == 1 is this year, q == 2 is last year
                        ){
    ss.version <- x$SS_versionNumeric
    mcmc.grep <-
      unique(grep(paste(posterior.regex, collapse="|"), names(x$mcmc)))
    mcmc.names <- names(x$mcmc)[mcmc.grep]
    mcmc.par <- x$mcmc[,mcmc.grep]
    mcmc.meds <- apply(mcmc.par, 2, median)
    mcmc.meds[2] <- exp(mcmc.meds[2]) / 1000 # To make R0 in the millions
    names(mcmc.meds) <- NULL

    if(q.choice == 1){
      q <- round(median(base.model$extra.mcmc$Q_vector), 3)
    }else{
      q <- round(median(last.yr.base.model$extra.mcmc$Q_vector), 3)
    }
    mcmc.meds <- c(mcmc.meds, q)

    ## Add 2008 recruitment
    rec <- median(x$mcmc$Recr_2008)
    rec <- rec / 1000
    mcmc.meds <- c(mcmc.meds, rec)

    ## Add 2010 recruitment
    rec <- median(x$mcmc$Recr_2010)
    rec <- rec / 1000
    mcmc.meds <- c(mcmc.meds, rec)

    ## Add 2014 recruitment
    rec <- median(x$mcmc$Recr_2014)
    rec <- rec / 1000
    mcmc.meds <- c(mcmc.meds, rec)

    ## Add B0
    b0 <- median(x$mcmc$SSB_Initial / 2) ## divide by 2 for females
    b0 <- b0 / 1000 ## To make B0 in the thousands
    mcmc.meds <- c(mcmc.meds, b0)

    ## Add depletion for 2009
    d <- median(x$mcmc$Bratio_2009)
    d <- d * 100  ## To make a percentage
    mcmc.meds <- c(mcmc.meds, d)

    ## Add depletion for 2015
    d <- median(x$mcmc[,paste0("Bratio_", end.yr)])
    d <- d * 100  ## To make a percentage
    mcmc.meds <- c(mcmc.meds, d)

    ## Add fishing intensity for end.yr - 1
    d <- median(x$mcmc[,paste0("SPRratio_", end.yr - 1)])
    d <- d * 100  ## To make a percentage
    mcmc.meds <- c(mcmc.meds, d)

    ## Add Female spawning biomass B_f40%
    if(ss.version == 3.3){
      b <- median(x$mcmc[,"SSB_SPR"]) / 2 /1000
    }else{
      b <- median(x$mcmc[,"SSB_SPRtgt"]) / 2 /1000
    }
    mcmc.meds <- c(mcmc.meds, b)

    ## Add SPR MSY-proxy
    mcmc.meds <- c(mcmc.meds, 40)

    ## Add Exploitation fraction corresponding to SPR
    if(ss.version == 3.3){
      f <- median(x$mcmc[,"Fstd_SPR"])
    }else{
      f <- median(x$mcmc[,"Fstd_SPRtgt"])
    }
    f <- 100 * f
    mcmc.meds <- c(mcmc.meds, f)

    ## Add Yield at Bf_40%
    if(ss.version == 3.3){
      y <- median(x$mcmc[,"Dead_Catch_SPR"]) / 1000
    }else{
      y <- median(x$mcmc[,"TotYield_SPRtgt"]) / 1000
    }
    mcmc.meds <- c(mcmc.meds, y)
    return(mcmc.meds)
  }

  ## This year's model MCMC
  mcmc.meds <- calc.mcmc(model, q = 1)

  ## Last year's model MCMC
  last.yr.mcmc.meds <- calc.mcmc(last.yr.model, q = 2)

  last.yr.mcmc.meds[11] <- last.yr.mcmc.meds[12] <- NA
  tab <- as.data.frame(cbind(mle.par, mcmc.meds, last.yr.mcmc.meds))
  colnames(tab) <- NULL

  ## Format the tables rows depending on what they are.
  ## Decimal values
  tab[c(1, 3, 4, 5),] <- f(tab[c(1, 3, 4, 5),], 3)
  ## Large numbers with no decimal points but probably commas
  tab[c(2, 6, 7, 8, 9, 13, 16),] <-
    f(apply(tab[c(2, 6, 7, 8, 9, 13, 16),], c(1,2), as.numeric))
  ## Percentages on non-NA elements
  paste.perc <- function(vec){
    ## Paste percentages on to all elements of vec that are not NA
    vec[!is.na(vec)] <- paste0(f(as.numeric(vec[!is.na(vec)]), 1), "\\%")
    return(vec)
  }
  tab[10,] <- paste.perc(tab[10,])
  tab[11,] <- paste.perc(tab[11,])
  tab[12,] <- paste.perc(tab[12,])
  tab[15,] <- paste.perc(tab[15,])
  ## SPR Percentages row (some may be NA). This is really ugly but works
  tab[14, !is.na(tab[14,])] <-
    paste0(f(apply(tab[14, !is.na(tab[14,])], 1, as.numeric), 1), "\\%")

  ## Make first row empty to make the Parameter header appear below the
  ##  horizontal line
  tab <- rbind(c("", "", ""), tab)

  ## Replace NAs with dashes
  tab[is.na(tab)] <- latex.bold("--")

  ## Set the first column to be the names
  ## Empty string below is necessary because of the rbind(c("","",""), tab)
  ##  call above
  tab <- cbind(c("",
                 paste0("Natural mortality (",
                        latex.italics("M"),
                        ")"),
                 paste0("Unfished recruitment (",
                        latex.subscr(latex.italics("R"), "0"),
                        ", millions)"),
                 paste0("Steepness (",
                        latex.italics("h"),
                        ")"),
                 "Additional acoustic survey SD",
                 paste0("Catchability (",
                        latex.italics("q"),
                        ")"),
                 "2008 recruitment (millions)",
                 "2010 recruitment (millions)",
                 "2014 recruitment (millions)",
                 paste0("Unfished female spawning biomass (",
                        latex.subscr(latex.italics("B"), "0"),
                        ", thousand~t)"),
                 "2009 relative spawning biomass",
                 paste0(end.yr,
                        " relative spawning biomass"),
                 paste0(end.yr - 1,
                        " relative fishing intensity: (1-SPR)/(1-",
                        latex.subscr("SPR", "40\\%"),
                        ")"),
                 paste0("Female spawning biomass at ",
                        latex.subscr(latex.italics("F"), "SPR=40\\%"),
                        "(",
                        latex.subscr(latex.italics("B"), "SPR=40\\%"),
                        ", thousand t)"),
                 paste0("SPR at ",
                        latex.subscr(latex.italics("F"), "SPR=40\\%")),
                 "Exploitation fraction corresponding to SPR",
                 paste0("Yield at ",
                        latex.subscr(latex.italics("B"), "SPR=40\\%"),
                        " (thousand~t)")),
               tab)
  colnames(tab) <- c("",
                     latex.bold("MLE"),
                     latex.mlc(c("Posterior",
                                 "median")),
                     latex.mlc(c("Posterior",
                                 "median from",
                                 paste(end.yr - 1, " base"),
                                 "model")))

  addtorow <- list()
  addtorow$pos <- list()
  addtorow$pos[[1]] <- 1
  addtorow$pos[[2]] <- 6
  addtorow$pos[[3]] <- 14
  addtorow$command <-
    c(paste0(latex.bold(latex.under("Parameters")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Derived Quantities")),
             latex.nline),
      paste0(latex.nline,
             latex.bold(latex.under("Reference Points (equilibrium) based on ")),
             latex.subscr(latex.italics("F"), "SPR=40\\%"),
             latex.nline))
  ## Make the size string for font and space size
  size.string <- latex.size.str(font.size, space.size)
  print(xtable(tab,
               caption = xcaption,
               label = xlabel,
               align = get.align(ncol(tab),
                                 just="c")),
        caption.placement = "top",
        include.rownames = FALSE,
        sanitize.text.function = function(x){x},
        size = size.string,
        add.to.row = addtorow,
        table.placement = "H")
}

make.long.parameter.estimates.table <- function(model,
                                                posterior.regex,
                                                digits = 4,
                                                xcaption = "default",
                                                xlabel   = "default",
                                                font.size = 9,
                                                space.size = 10){
  ## Returns an xtable in the proper format for the posterior medians of the
  ##  parameter estimates
  ##
  ## model - an mcmc run, output of the r4ss package's function SSgetMCMC()
  ## posterior.regex - a vector of the posterior names to search for
  ##  (partial names will be matched)
  ## digits - number of decimal points for the estimates
  ## xcaption - caption to appear in the calling document
  ## xlabel - the label used to reference the table in latex
  ## font.size - size of the font for the table
  ## space.size - size of the vertical spaces for the table

  mc <- model$mcmc
  mc.names <- names(mc)

  ## Start with the key posteriors using the regex
  mcmc.grep <- unique(grep(paste(posterior.regex, collapse = "|"), mc.names))
  mcmc.names <- mc.names[mcmc.grep]
  mcmc.par <- mc[,mcmc.grep]
  mcmc.meds <- as.data.frame(apply(mcmc.par, 2, median))
  df <- cbind(mcmc.names, mcmc.meds)
  names(df) <- c("param", "p.med")
  rownames(df) <- NULL

  calc.meds <- function(df, x){
    ## x is a data frame of posteriors for some parameters
    ## This function will take the medians of these,
    ##  and bind them with the data frame df, and return the result
    ## Assumes df has column names param and p.med
    d <- as.data.frame(apply(x, 2, median))
    d <- cbind(rownames(d), d)
    rownames(d) <- NULL
    names(d) <- c("param", "p.med")
    df <- rbind(df, d)
    return(df)
  }

  ## Add Dirichlet-Multinomial parameter
  ## currently only 1 value so calc.meds doesn't work due to
  ## getting a vector instead of a data.frame with names in header
  dm <- data.frame(param = "ln.EffN_mult._1",
                   p.med = median(mc$ln.EffN_mult._1))
  df <- rbind(df, dm)

  ## Add all Early_InitAge parameters
  ei <- mc[,grep("Early_InitAge_[0-9]+", mc.names)]
  df <- calc.meds(df, ei)

  ## Add all Recruitment deviation parameters
  rec <- mc[,union(grep(".*_RecrDev_[0-9]+", mc.names),
                  grep("ForeRecr_[0-9]+", mc.names))]
  df <- calc.meds(df, rec)

  ## Add all AgeSel
  a.sel <- mc[,grep("AgeSel_.*", mc.names)]
  df <- calc.meds(df, a.sel)

  ## Format the values
  df[,2] <- f(df[,2], digits)

  ## Make the underscores in the names have a preceeding \ so latex will like it
  param.names <- levels(df[,1])[df[,1]]
  df[,1] <- gsub("\\_", "\\\\_", param.names)

  ## Latex column names
  names(df) <- c(latex.bold("Parameter"), latex.bold("Posterior median"))

  addtorow          <- list()
  addtorow$pos      <- list()
  addtorow$pos[[1]] <- c(0)
  addtorow$command  <- c(paste0(latex.hline,
                                "\n",
                                "\\endhead \n",
                                latex.hline,
                                "\n",
                                "{\\footnotesize Continued on next page} \n",
                                "\\endfoot \n",
                                "\\endlastfoot \n"))
  ## Make the size string for font and space size
  size.string <- latex.size.str(font.size, space.size)
  print(xtable(df,
               caption = xcaption,
               label = xlabel,
               align = get.align(ncol(df)),
               digits = digits),
        caption.placement = "top",
        table.placement = "H",
        tabular.environment = "longtable",
        floating = FALSE,
        include.rownames = FALSE,
        sanitize.text.function = function(x){x},
        size = size.string,
        add.to.row = addtorow,
        hline.after = c(-1))
}
