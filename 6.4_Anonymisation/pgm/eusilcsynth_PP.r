## ----Functions-----------------------------------------------------------

## ----echo=FALSE----------------------------------------------------------
getAge <- function(birth, year, data = NULL) {
  # this function is only applicable if the income 
  # reference period is the previous calender year
  if(!is.null(data)) {
    if(missing(birth)) birth <- "rb080"
    birth <- data[, birth]
    if(missing(year)) year <- "rb010"
    year <- data[, year]
  }
  year - 1 - birth
}
getGender <- function(gender, labels = c("male","female"), data = NULL) {
  if(!is.null(data)) {
    if(missing(gender)) gender <- "rb090"
    gender <- data[, gender]
  }
  factor(gender, labels=labels)
}
#getHsize <- function(data) 
#{
#  tab <- table(data$rb040)
#  hsize <- rep(tab, tab)
#}
getEcoStat <- function(ecoStat , data , levels) {  ## variable pl030 (economic status)
  if(missing(ecoStat)) ecoStat <- "pl031"
  ecoStat <- factor(data[, ecoStat])
  levels(ecoStat) <- levels
  return(ecoStat)
}
getCitizenship.mod <- function(citizenship, data, owncountry, EU, other) {
  if(missing(citizenship)) citizenship <- "pb220a"
  citizenship <- data[, citizenship]
  indNA <- which(levels(citizenship) == "")
  indOC <- which(levels(citizenship) == owncountry)
  indEU <- which(levels(citizenship) %in% EU)
  indOther <- which(levels(citizenship) %in% other)
  levels <- character(nlevels(citizenship))
  levels[indNA] <- NA
  levels[indOC] <- owncountry
  levels[indEU] <- "EU"
  levels[indOther] <- "Other"
  levels(citizenship) <- levels
  return(citizenship)
}
getHsize <- function(data,hhid) 
{ 
  if(missing(hhid)) hhid <- "db030"
  tab <- table(data[,hhid]) #table(data$rb040)
  hsize <- rep(tab, tab)
  hsize <- as.numeric((hsize))
  return(hsize)
}
restructureHHid <- function(data){
  tab <- table(data$db030)
  hsize <- rep(tab, tab)
  db030 <- as.numeric(names(hsize))
  return(db030)
}
#Function factorNA from package simPop: includes NAs as an extra level in the factor
factorNA <- function(x, always = FALSE) {
  always <- isTRUE(always)
  if(is.factor(x)) {
    l <- levels(x)
    if(NA %in% l || !(always || any(is.na(x)))) x
    else {
      l <- c(l, NA)
      factor(x, levels=c(levels(x), NA), exclude=c())
    }
  } else {
    if(always) {
      factor(c(NA, x), exclude=c())[-1] # little trick
    } else factor(x, exclude=c())
  }
}

# Function uni.distribution: random draws from the weighted univariate distribution of
# the original data (maybe better from the SUF, but then the SUF always has to be used as well)
univariate.dis <- function(puf,data,additional,w){
  if (sum(is.na(data[,additional]))>0 & sum(is.na(data[,additional])) != dim(data)[1]) {
    var <- factorNA(data[,additional],always=TRUE)
  } else if (sum(is.na(data[,additional])) == dim(data)[1]) {
    var <- factor(c(NA, data[,additional]), exclude=c())[-1]
  } else {
    var <- as.factor(data[,additional])
  }
  tab <- wtd.table(var,weights=data[,w],type="table")
  p <- tab/sum(data[,w])
  puf[,additional] <- sample(x=levels(var)[levels(var) %in% names(tab)],size=dim(puf)[1],prob=p,replace=T)
  return(puf)
}

# Function con.distribution: random draws from the weighted conditional distribution
# (conditioned on a factor variable)
conditional.dis <- function(puf,data,additional,conditional,w){
  if (sum(is.na(data[,additional]))>0 & sum(is.na(data[,additional])) != dim(data)[1]) {
    var <- factorNA(data[,additional],always=TRUE)
  } else if (sum(is.na(data[,additional])) == dim(data)[1]) {
    var <- factor(c(NA, data[,additional]), exclude=c())[-1]
  } else {
    var <- as.factor(data[,additional])
  }
  puf[,additional] <- NA
  for (i in 1:length(levels(puf[,conditional]))) {
    tab <- wtd.table(var[data[,conditional]==levels(data[,conditional])[i]],weights=data[data[,conditional]==levels(data[,conditional])[i],w],type="table")
    p <- tab/sum(tab)
    puf[which(puf[,conditional]==levels(puf[,conditional])[i]),additional] <- sample(x=levels(var)[levels(var) %in% names(tab)],size=dim(puf[which(puf[,conditional]==levels(data[,conditional])[i]),])[1],prob=p,replace=T)
  }
  return(puf)
}

#########################################################################################
# Step 1: Preparation of the original data
#########################################################################################

# Setting library path to include personal library
.libPaths("\\\\cbsp.nl/HomeDirectory/Productie/PWOF/R/win-library/3.1.1")

## ----include=FALSE-------------------------------------------------------
library(knitr)
opts_chunk$set(
  concordance=TRUE
)

## ----globalSettings3, echo=FALSE-----------------------------------------
knitr::opts_chunk$set(warning=FALSE, message=FALSE)
knitr::opts_chunk$set(fig.path="figures/") # cache=TRUE
knitr::opts_chunk$set(dev=c("pdf"))
knitr::opts_chunk$set(size="small")

## ----options1, echo=FALSE, message=FALSE, warning=FALSE------------------
options(prompt = "R> ")

## ----echo=FALSE, results='hide'------------------------------------------
library("lattice")
lattice.options(default.theme = canonical.theme(color = FALSE))
sl <- trellis.par.get("superpose.line")
sl$col[1] <- "#A9A9A9"  # set first color to dark grey
rl <- trellis.par.get("reference.line")
rl$lty <- 2
trellis.par.set(superpose.line=sl, reference.line=rl)
options(width=75, prompt="R> ")

## ----echo=FALSE, message=FALSE, warning=FALSE----------------------------
if (!require("sdcMicro")) install.packages("sdcMicro")
if (!require("simPop")) install.packages("simPop")
if (!require("parallel")) install.packages("parallel")
if (!require("laeken")) install.packages("laeken")


## ----setwd---------------------------------------------------------------
setwd("\\\\dmkv1f\\personen1\\PWOF\\Beveiliging (SDC)\\FPA2014\\SGA1\\Data\\EU-SILC")

## ----import data, eval=TRUE----------------------------------------------
x <- read.csv(file = "EUSILC_CROSS_2013_V3.CSV", header =TRUE)
x <- subset(x,DB135==1)

## ----table of number of households per region (used later for drawing the puf)
x2 <- data.table(x[,c("DB040","DB030")])
setkey(x2, DB030)
hh <- x2[, unique(DB040), by = DB030]
tab <- as.numeric(table(hh$V1))

## ----some member states have capitals in var-names, others have lower case
names(x) <- tolower(names(x))
## ----silc, eval=FALSE----------------------------------------------------
eusilc13 <- data.frame("db030"=x$db030, #HHid
                       "db040"=x$db040, #region
                       "rb030"=x$rb030, #Personid
                       "rb080"=x$rb080, #year of birth
                       "rb090"=x$rb090, #sex
                       "pl031"=factor(x$pl031), #economic status
                       "pb220a"=factor(x$pb220a), #citizenship 1
                       "py010g"=x$py010g, 
                       #"py020g"=x$py020g,
                       "py021g"=x$py021g,
                       "py050g"=x$py050g,
                       "py080g"=x$py080g,
                       "py090g"=x$py090g,
                       "py100g"=x$py100g, 
                       "py110g"=x$py110g,
                       "py120g"=x$py120g, 
                       "py130g"=x$py130g,
                       "py140g"=x$py140g,
                       "hy040g"=x$hy040g,
                       "hy050g"=x$hy050g, 
                       "hy060g"=x$hy060g,
                       "hy070g"=x$hy070g,
                       "hy080g"=x$hy080g,
                       #"hy081g"=x$hy081g,
                       "hy090g"=x$hy090g,
                       "hy100g"=x$hy100g,
                       "hy110g"=x$hy110g, 
                       "hy120g"=x$hy120g,
                       "hy130g"=x$hy130g,
                       "hy140g"=x$hy140g, 
                       #"hy170g"=x$hy170g,
                       "db090"=x$db090,  #household cross-sectional weight
                       "rb050"=x$rb050,  #personal cross-sectional weight
                       "pb190"=x$pb190,  #maritial status
                       "pe040"=x$pe040,  #highest isced level attained
                       "pl051"=x$pl051,  #occupation
                       "pl111"=x$pl111   #NACE
)

## ----arrange-------------------------------------------------------------
## arrange datasets according to db030 (household id)
eusilc13 <- eusilc13[order(eusilc13$db030),]

## ----add age-------------------------------------------------------------
## add age
eusilc13$age <- getAge(data=x)

## ----add gender----------------------------------------------------------
## add gender
eusilc13$rb090 <- getGender(data=x)

## ----add hsize-----------------------------------------------------------
## add hhsize
eusilc13$hsize <- getHsize(data=x)

## ----add ecostat---------------------------------------------------------
## add ecostat
eusilc13$pl031 <- getEcoStat(data=x,levels=levels(eusilc13$pl031))

##----pb220a3, eval=FALSE-------------------------------------------------
## modify pb220a
owncountry <- "NL"
EU <- c("AT","BE","BG","CY","CZ","DE","DK","EE","EL","ES","FI","FR","GR","HU","IE",
        "IT","LT","LU","LV","MT","PL","PT","RO","SI","SE","SK","UK")
other <- c("CAN","CH","CSA","HR","IS","ME","MK","NAF","NME","NO",
           "OAF","OAS","OCE","OEU","OT","OTH","TR","USA","WAF")
eusilc13$pb220a <- getCitizenship.mod(data=x, owncountry=owncountry, EU=EU, other=other)

## ----restruct------------------------------------------------------------
## restructure HHID
eusilc13$db030 <- restructureHHid(eusilc13)

## ----eqSS, message=FALSE, warning=FALSE----------------------------------
require(laeken)
## compute equivalized sample size
eusilc13$eqSS <- x$eqSS <- eqSS("db030", "age", data=eusilc13)

## ----eqIncome------------------------------------------------------------
eusilc13$eqInc <- eqInc("db030", 
                        #hplus
                        c("hy040g","hy050g","hy060g","hy070g","hy080g",
                          "hy090g","hy100g","hy110g"), 
                        #hminus
                        c("hy120g","hy130g","hy140g"), 
                        #pplus
                        c("py010g","py021g","py050g","py080g","py090g",
                          "py100g","py110g","py120g","py130g","py140g"), 
                        character(), "eqSS", 
                        data=x)

## ----grossincomes, message=FALSE, warning=FALSE--------------------------
require(simPop)

eusilc13$pgrossIncome <- apply(eusilc13[, c("py010g","py021g","py050g","py080g",
                                            "py090g","py100g", "py110g","py120g",
                                            "py130g","py140g"
                                            )], 1, sum, na.rm=TRUE)
breaks <- getBreaks(eusilc13$pgrossIncome, eusilc13$rb050, 
                    upper = Inf, equidist = FALSE)
eusilc13$pgrossIncomeCat <- getCat(eusilc13$pgrossIncome, breaks)

eusilc13$hgrossIncome <- apply(eusilc13[, c("hy040g","hy050g","hy060g","hy070g","hy080g",
                                            "hy090g","hy100g","hy110g")], 1, sum, na.rm=TRUE)
breaks <- getBreaks(eusilc13$hgrossIncome, eusilc13$rb050, 
                    upper = Inf, equidist = FALSE)
eusilc13$hgrossIncomeCat <- getCat(eusilc13$hgrossIncome, breaks)

eusilc13$hgrossminus <- apply(eusilc13[, c("hy120g","hy130g","hy140g")], 1, sum, na.rm=TRUE)
breaks <- getBreaks(eusilc13$hgrossminus, eusilc13$rb050, 
                    upper = Inf, equidist = FALSE)
eusilc13$hgrossminusCat <- getCat(eusilc13$hgrossminus, breaks)

## ----1-digit occupation----------------------------------------------
eusilc13$pl051 <- as.factor(trunc(eusilc13$pl051/10))

## ----recoding of NACE (Rev 2)----------------------------------------
eusilc13$pl111 <- as.factor(eusilc13$pl111)
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="1")] <- "a"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("2","3","4","5","6"))] <- "b-e"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="7")] <- "f"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="8")] <- "g"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="9")] <- "h"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="10")] <- "i"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="11")] <- "j"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="12")] <- "k"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("13","14","15"))] <- "l-n"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="16")] <- "o"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="17")] <- "p"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="18")] <- "q"
#levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("19","20","21","22","23"))] <- "r-u"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("1","2","3"))] <- "a"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("5","6","7","8","9","10","11","12","13","14",
                                                           "15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34",
                                                           "35","36","37","38","39"))] <- "b-e"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("41","42","43"))] <- "f"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("45","46","47"))] <- "g"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("49","50","51","52","53"))] <- "h"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("55","56"))] <- "i"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("58","59","60","61","62","63"))] <- "j"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("64","65","66"))] <- "k"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("68","69","70",
                                                           "71","72","73","74","75","76","77","78","79","80","81","82"))] <- "l-n"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="84")] <- "o"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111)=="85")] <- "p"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("86","87","88"))] <- "q"
levels(eusilc13$pl111)[which(levels(eusilc13$pl111) %in% c("90","91","92","93","94","95","96","97","98","99"))] <- "r-u"


eusilc13$pb190 <- as.factor(eusilc13$pb190)
eusilc13$pe040 <- as.factor(eusilc13$pe040)
levels(eusilc13$pe040)[which(levels(eusilc13$pe040)=="6")] <- "5"

rm(x2,hh,EU,breaks,other,owncountry)

#########################################################################################
# Step 2: Preparation of the SUF
#########################################################################################


#setwd("E:/g-c1-geheim/fpa_sga1/silc/anonymisierte_daten_von_eurostat/c-2013_with_de_for_de")

## ----import data, eval=TRUE----------------------------------------------
suf.d <- read.csv2(file = "nl_udb_c13d_ver 2013-1 from 01-03-15.csv", header =TRUE,sep=",")
suf.h <- read.csv2(file = "nl_udb_c13h_ver 2013-1 from 01-03-15.csv", header =TRUE,sep=",")
suf.p <- read.csv2(file = "nl_udb_c13p_ver 2013-1 from 01-03-15.csv", header =TRUE,sep=",")
suf.r <- read.csv2(file = "nl_udb_c13r_ver 2013-1 from 01-03-15.csv", header =TRUE,sep=",")

## ----merge data----------------------------------------------------------
suf.pers <- merge(x=suf.r,y=suf.p,by.x="RB030",by.y="PB030",all.x=TRUE)
suf.pers$RB030 <- suf.pers$PB030
suf.hh <- merge(x=suf.d,y=suf.h,by.x="DB030",by.y="HB030",all.x=TRUE)
suf.hh$HB030 <- suf.hh$DB030
suf <- merge(x=suf.pers,y=suf.hh,by.x="RX030",by.y="HB030")
names(suf) <- tolower(names(suf))
names(suf.d) <- tolower(names(suf.d))
names(suf.h) <- tolower(names(suf.h))
names(suf.p) <- tolower(names(suf.p))
names(suf.r) <- tolower(names(suf.r))


## ----create additional variables-----------------------------------------
suf$age <- getAge(data=suf)
suf$eqSS <- eqSS("db030", "age", data=suf)
suf$hy080g <- as.numeric(as.character(suf$hy080g))
suf$hy081g <- as.numeric(as.character(suf$hy081g))
suf$rb050 <- as.numeric(as.character(suf$rb050))
suf$pb040 <- as.numeric(as.character(suf$pb040))
suf$eqInc <- eqInc("db030", 
                   #hplus
                   c("hy040g","hy050g","hy060g","hy070g","hy080g",
                     "hy090g","hy100g","hy110g"), 
                   #hminus
                   c("hy120g","hy130g","hy140g"), 
                   #pplus
                   c("py010g","py021g","py050g","py080g","py090g",
                     "py100g", "py110g","py120g", "py130g","py140g"), character(), "eqSS", 
                   data=suf)

suf$pgrossIncome <- apply(suf[, c("py010g","py020g","py021g","py050g","py080g",
                                  "py090g","py100g", "py110g","py120g",
                                  "py130g","py140g"
                              )], 1, sum, na.rm=TRUE)

suf$hgrossIncome <- apply(suf[, c("hy040g","hy050g","hy060g","hy070g","hy080g",
                                  "hy090g","hy100g","hy110g")], 1, sum, na.rm=TRUE)

rm(suf.d,suf.h,suf.p,suf.r)

#########################################################################################
# Step 3: Simulation of the population and some variables
#########################################################################################

## ----strdata-------------------------------------------------------------
str(eusilc13)

## ----check platform, echo=FALSE------------------------------------------
if(.Platform$OS.type == "windows"){
  cat("Holy shit you use windows. \n We use only one CPU since this is faster than using more than one.")
  cpus <- 1
} else {
  cat("good choice. Number of CPU's is set to NULL \n which means that maximum number of CPU's minus one is used")
  cpus <- NULL
  number <- parallel::detectCores() - 1
  cat(paste("\n On my machine, this is", number))
}

## ----simStructure1, warning=FALSE, message=FALSE-------------------------
library(simPop)
set.seed(123)
eusilc13$db090 <- as.numeric(as.character(eusilc13$db090))

## ----division of the household weight (=db090) by 10 in order to simulate a smaller synthetic population
eusilc13$db090 <- eusilc13$db090/10

inp <- specifyInput(data=eusilc13, 
                    hhid="db030", 
                    hhsize="hsize", 
                    strata="db040", 
                    weight="db090")
inp

## ----simStructure2, cache=TRUE-------------------------------------------
eusilcP <- simStructure(inp, 
                        method="direct", 
                        basicHHvars=c("age", "rb090") )
eusilcP

## ----simCat, tidy=FALSE, cache=TRUE--------------------------------------
eusilcP <- simCategorical(eusilcP, 
                          additional = c("pl031","pb220a","pb190","pe040","pl051","pl111"),
                          nr_cpus=cpus, MaxNWts=5000 )
eusilcP 

## ----peronal income------------------------------------------------------

## ----simCont, cache=TRUE, message=FALSE, warning=FALSE-------------------
eusilcP <- simContinuous(eusilcP, additional = "pgrossIncome", 
                          upper = 200000, equidist = TRUE, zeros=TRUE, nr_cpus=cpus, MaxNWts=2000 )

## ----simComp, cache=TRUE-------------------------------------------------
pcomponents <- c("py010g","py021g","py050g","py080g",
                 "py090g","py100g", "py110g","py120g",
                 "py130g","py140g")
eusilcP <- simComponents(eusilcP, 
                          total = "pgrossIncome", components = pcomponents, 
                          conditional = c("pl031"))

## ----household income-----------------------------------------------------

## ----household data-------------------------------------------------------
eusilcH <- eusilcP
eusilcH@sample@data <- eusilcH@sample@data[!duplicated(eusilcH@sample@data$db030)]
eusilcH@pop@data <- eusilcH@pop@data[!duplicated(eusilcH@pop@data$db030)]
eusilcH@basicHHvars <- c("hsize")

## ----simCont, cache=TRUE, message=FALSE, warning=FALSE-------------------
eusilcH <- simContinuous(eusilcH, additional = "eqInc", 
                         upper = 200000, equidist = TRUE, nr_cpus=cpus, MaxNWts=2000 )
eusilcH <- simContinuous(eusilcH, additional = "hgrossIncome", 
                         upper = 200000, equidist = TRUE, nr_cpus=cpus, MaxNWts=2000 )
eusilcH <- simContinuous(eusilcH, additional = "hgrossminus", 
                         upper = 200000, equidist = TRUE, nr_cpus=cpus, MaxNWts=2000 )

## ----simComp, cache=TRUE-------------------------------------------------
hcomponents <- c("hy040g","hy050g","hy060g","hy070g","hy080g",
                 "hy090g","hy100g","hy110g")
eusilcH <- simComponents(eusilcH, 
                         total = "hgrossIncome", components = hcomponents, 
                         conditional = c("hsize"))

hminuscomponents <- c("hy120g","hy130g","hy140g")

eusilcH <- simComponents(eusilcH, 
                         total = "hgrossminus", components = hminuscomponents, 
                         conditional = c("hsize"))

eusilcH

## ----merge household income to synthetic population data--------------------
hhIncome <- as.data.frame(cbind(eusilcH@pop@data$db030,eusilcH@pop@data$eqInc,eusilcH@pop@data$hgrossIncomeCat,eusilcH@pop@data$hgrossIncome,
                                eusilcH@pop@data$hy120g,eusilcH@pop@data$hy130g,eusilcH@pop@data$hy140g,
                                eusilcH@pop@data$hy040g,eusilcH@pop@data$hy050g,eusilcH@pop@data$hy060g,
                                eusilcH@pop@data$hy070g,eusilcH@pop@data$hy080g,
                                eusilcH@pop@data$hy090g,eusilcH@pop@data$hy100g,eusilcH@pop@data$hy110g))

names(hhIncome) <- c("db030","eqInc","hgrossIncomeCat","hgrossIncome","hy120g","hy130g","hy140g",
                     "hy040g","hy050g","hy060g","hy070g","hy080g",
                     "hy090g","hy100g","hy110g")

eusilcP@pop@data <- merge(x=eusilcP@pop@data,
                           y=hhIncome,
                           by="db030")

eusilcP

rm(hhIncome,eusilcH,inp,hcomponents,pcomponents)

#########################################################################################
# Step 4: Making the PUF
#########################################################################################

library(Hmisc)
library(stringr)

## ----echo=FALSE, results='hide'------------------------------------------
options(width=66)

## ----puf, message=FALSE, warning=FALSE-----------------------------------
require(simFrame)

## stratified group sampling, equal size
set.seed(23456)
puf <- draw(data.frame(eusilcP@pop@data), 
             design = "db040", 
             grouping = "db030", 
             size = tab)
dim(puf) 
colnames(puf)[which(colnames(puf) == ".weight")] <- "rb050"
puf$rb050 <- puf$rb050*10
puf$pb040 <- puf$rb050

puf$hb030 <- puf$db030
puf$px030 <- puf$db030
puf$rx030 <- puf$db030
puf$pb030 <- puf$pid
puf$rb030 <- puf$pid
puf$hx040 <- puf$hsize
puf$pb150 <- puf$rb090

## ---- age variables:
puf$rx020 <- as.numeric(as.character(puf$age))
puf$px020 <- as.numeric(as.character(puf$age))

## ---- age difference:
tab <- wtd.table(suf$rx010-suf$rx020,weights=suf[,"rb050"],type="table")
p <- tab/sum(suf[,"rb050"])
age.dif <- sample(x=c(0,1),size=dim(puf)[1],prob=p,replace=T)
puf$rx010 <- puf$rx020 + age.dif

## ---- equivalized household size:
puf$hx050 <- eqSS("db030", "rx020", data=puf)


## ----compute income variables:
## ----hy010: total household gross income 
#(HY010 = HY040G + HY050G + HY060G + HY070G + HY080G + HY090G + HY110G +
#[for all household members](PY010G + PY021G + PY050G + PY080G + PY090G +
                              #PY100G + PY110G + PY120G + PY130G + PY140G))

sum.pgrossIncome <- aggregate(puf[,c("py010g","py021g","py050g","py080g","py090g",
                                     "py100g","py110g","py120g","py130g","py140g")],by=list(puf$db030),FUN=sum)
names(sum.pgrossIncome)[names(sum.pgrossIncome)=="Group.1"] <- "db030"
puf <- merge(x=puf,y=sum.pgrossIncome,by="db030",suffixes=c("",".hh"))
puf$hy010 <- puf$hy040g + puf$hy050g + puf$hy060g + puf$hy070g + puf$hy080g + puf$hy090g + puf$hy110g +
              puf$py010g.hh + puf$py021g.hh + puf$py050g.hh + puf$py080g.hh + puf$py090g.hh +
              puf$py100g.hh + puf$py110g.hh + puf$py120g.hh + puf$py130g.hh + puf$py140g.hh

## ----hy020: total disposable household income
#HY020 = HY010 – HY120G – HY130G – HY140G
puf$hy020 <- puf$hy010 - puf$hy120g - puf$hy130g - puf$hy140g

## ----hy022: total disposable household income before social transfers other than old-age and survivor´s benefits
#HY022 = HY040G + HY080G + HY090G + HY110G – HY120G – HY130G – HY140G +
#  [for all household members](PY010G + PY021G + PY050G + PY080G + PY100G + PY110G)
puf$hy022 <- puf$hy040g + puf$hy080g + puf$hy090g + puf$hy110g - puf$hy120g - puf$hy130g - puf$hy140g +
             puf$py010g.hh + puf$py021g.hh + puf$py050g.hh + puf$py080g.hh + puf$py100g.hh + puf$py110g.hh

## ----hy023: total disposable household income berfore social transfers including than old-age and survivor´s benefits
#HY023 = HY040G + HY080G + HY090G + HY110G – HY120G – HY130G – HY140G +
#  [for all household members](PY010G + PY021G + PY050G + PY080G)
puf$hy023 <- puf$hy040g + puf$hy080g + puf$hy090g + puf$hy110g - puf$hy120g - puf$hy130g - puf$hy140g +
             puf$py010g.hh + puf$py021g.hh + puf$py050g.hh + puf$py080g.hh

keep <- names(puf)[str_sub(names(puf), start= -3)!=".hh"]
puf <- subset(puf,select=keep)

## ----create rest of the variables------------------------------------------

## ----d-file: household register-------------------------------------------- 
puf.d <- puf[!duplicated(puf$db030),substring(names(puf),1,1)=="d"]

var.d <- names(suf)[substr(names(suf),1,1)=="d" & !(names(suf) %in% names(puf.d))]

for (i in 1:length(var.d)) {
#  print(var.d[i])
  puf.d <- univariate.dis(puf.d,data=suf[!duplicated(suf$db030),],var.d[i],"rb050")
#  print(table(puf.d[,var.d[i]],useNA="always"))
#  print(table(suf[!duplicated(suf$db030),var.d[i]],useNA="always"))
}

## ----h-file: household data------------------------------------------------ 
puf.h <- puf[!duplicated(puf$db030),substring(names(puf),1,1)=="h"]

var.hb <- names(suf)[substring(names(suf),1,2)=="hb" & !(names(suf) %in% names(puf.h))]

for (i in 1:length(var.hb)) {
#  print(var.hb[i])
  puf.h <- univariate.dis(puf.h,suf[!duplicated(suf$db030),],var.hb[i],"rb050")
#  print(table(puf.h[,var.hb[i]],useNA="always"))
#  print(table(suf[!duplicated(suf$db030),var.hb[i]],useNA="always"))
}

hgrossIncome5 <- quantile(puf[!duplicated(puf$db030),"hgrossIncome"],probs=seq(0,1,0.2))
hgrossIncome5[1] <- -Inf
hgrossIncome5[6] <- Inf
puf.h$hgrossIncome5<-cut(puf[!duplicated(puf$db030),"hgrossIncome"], breaks=hgrossIncome5, labels=seq(1,5,1))

suf$hgrossIncome5<-cut(suf$hgrossIncome, breaks=hgrossIncome5, labels=seq(1,5,1))

var.hh <- names(suf)[substring(names(suf),1,2)=="hh" & !(names(suf) %in% names(puf.h))]

for (i in 1:length(var.hh)) {
#  print(var.hh[i])
  puf.h <- conditional.dis(puf.h,suf[!duplicated(suf$db030),],var.hh[i],"hgrossIncome5","rb050")
#  print(table(puf.h[,var.hh[i]],useNA="always"))
#  print(table(suf[!duplicated(suf$db030),var.hh[i]],useNA="always"))
}

var.hs <- names(suf)[substring(names(suf),1,2)=="hs" & !(names(suf) %in% names(puf.h))]

for (i in 1:length(var.hs)) {
#  print(var.hs[i])
  puf.h <- conditional.dis(puf.h,suf[!duplicated(suf$db030),],var.hs[i],"hgrossIncome5","rb050")
#  print(table(puf.h[,var.hs[i]],useNA="always"))
#  print(table(suf[,var.hs[i]],useNA="always"))
}

var.h <- names(suf)[substring(names(suf),1,1)=="h" & !(names(suf) %in% names(puf.h))]

for (i in 1:length(var.h)) {
#  print(var.h[i])
  puf.h <- univariate.dis(puf.h,suf[!duplicated(suf$db030),],var.h[i],"rb050")
#  print(table(puf.h[,var.h[i]],useNA="always"))
#  print(table(suf[!duplicated(suf$db030),var.h[i]],useNA="always"))
}


## ----r-file: personal register-------------------------------------------------
puf.r <- puf[,substring(names(puf),1,1)=="r"]

var.r <- names(suf)[substring(names(suf),1,1)=="r" & !(names(suf) %in% names(puf.r))]

for (i in 1:length(var.r)) {
#  print(var.r[i])
  puf.r <- univariate.dis(puf.r,suf,var.r[i],"rb050")
#  print(table(puf.r[,var.r[i]],useNA="always"))
#  print(table(suf[,var.r[i]],useNA="always"))
}

## ----adjustment of year of birth
puf.r$rb080 <- as.numeric(as.character(puf.r$rb010)) - 1 - puf.r$rx020


## ----p-file: personal data------------------------------------------------------
puf.p <- puf[which(puf$px020 > 15),substring(names(puf),1,1)=="p"]

var.pb <- names(suf)[substring(names(suf),1,2)=="pb" & !(names(suf) %in% names(puf.p))]

for (i in 1:length(var.pb)) {
#  print(var.pb[i])
  puf.p <- univariate.dis(puf.p,suf[which(suf$px020>15),],var.pb[i],"pb040")
#  print(table(puf.p[,var.pb[i]]))
#  print(table(suf[,var.pb[i]]))
}

pgrossIncome5 <- quantile(puf.p[,"pgrossIncome"],probs=seq(0,1,0.2))
pgrossIncome5[1] <- -Inf
pgrossIncome5[6] <- Inf
puf.p$pgrossIncome5<-cut(puf.p[,"pgrossIncome"], breaks=pgrossIncome5, labels=seq(1,5,1))

suf$pgrossIncome5<-cut(suf$pgrossIncome, breaks=pgrossIncome5, labels=seq(1,5,1))

var.pe <- names(suf)[substring(names(suf),1,2)=="pe" & !(names(suf) %in% names(puf.p))]

for (i in 1:length(var.pe)) {
#  print(var.pe[i])
  puf.p <- conditional.dis(puf.p,suf[which(suf$px020>15),],var.pe[i],"pgrossIncome5","pb040")
#  print(table(puf.p[,var.pe[i]],useNA="always"))
#  print(table(suf[,var.pe[i]],useNA="always"))
}

var.ph <- names(suf)[substring(names(suf),1,2)=="ph" & !(names(suf) %in% names(puf.p))]

for (i in 1:length(var.ph)) {
#  print(var.ph[i])
  puf.p <- conditional.dis(puf.p,suf[which(suf$px020>15),],var.ph[i],"pgrossIncome5","pb040")
#  print(table(puf.p[,var.ph[i]],useNA="always"))
#  print(table(suf[,var.ph[i]],useNA="always"))
}

var.pl <- names(suf)[substring(names(suf),1,2)=="pl" & !(names(suf) %in% names(puf.p))]

for (i in 1:length(var.pl)) {
#  print(var.pl[i])
  puf.p <- conditional.dis(puf.p,suf[which(suf$px020>15),],var.pl[i],"pgrossIncome5","pb040")
#  print(table(puf.p[,var.pl[i]],useNA="always"))
#  print(table(suf[,var.pl[i]],useNA="always"))
}

var.p <- names(suf)[substring(names(suf),1,1)=="p" & !(names(suf) %in% names(puf.p))]

for (i in 1:length(var.p)) {
#  print(var.p[i])
  puf.p <- univariate.dis(puf.p,suf[which(suf$px020>15),],var.p[i],"pb040")
#  print(table(puf.p[,var.p[i]],useNA="always"))
#  print(table(suf[,var.p[i]],useNA="always"))
}

## ----adjustment of year of birth
puf.p$pb140 <- as.numeric(as.character(puf.p$pb010)) - 1 - puf.p$px020

## ----second digit of occupation (pl051)
puf.p$pl051.1d <- puf.p$pl051
suf$pl051.1d <- as.factor(trunc(suf$pl051/10))
puf.p <- conditional.dis(puf.p,suf[which(suf$px020>15),],"pl051","pl051.1d","pb040")

rm(hgrossIncome5,pgrossIncome5,i,var.d,var.h,var.hb,var.hh,var.hs,var.p,
   var.pb,var.pe,var.ph,var.pl,var.r)

## ----further anonymizations: only necessary for variables that are not drawn from
#                              the suf distributions

#year of birth:
min <- as.numeric(as.character(puf.p$pb010))[1]-81
puf.p$pb140[which(puf.p$pb140<min)] <- min
puf.r$rb080[which(puf.r$rb080<min)] <- min

#age:
max <- 80
puf.r$rx010[which(puf.r$rx010>max)] <- max
puf.r$rx020[which(puf.r$rx020>max)] <- max
puf.p$px020[which(puf.p$px020>max)] <- max

## ----remove additionally simulated variables:
#puf.r <- puf.r[,names(suf.r)]
#puf.p <- puf.p[,names(suf.p)]
#puf.h <- puf.h[,names(suf.h)]
#puf.d <- puf.d[,names(suf.d)]

rm(age.dif,hminuscomponents,keep,max,min)

#########################################################################################
# Step 5: Utility measures
#########################################################################################


## ----measure1------------------------------------------------------------
utility <- function(x, y, type="all"){
  if(type=="all" | type=="measure2"){
    measure2 <- ncol(x) / ncol(y)
  }
  if(type=="all" | type=="measure3"){
    measure3 <- nrow(x) / nrow(y)
  }
  if(type=="all" | type=="measure4"){
    puf <- sum(is.na(x))
    suf <- sum(is.na(y))
    if(suf > 0 & puf > 0){ 
      measure4 <- sum(is.na(x)) / sum(is.na(y)) - 1
    } else if(suf == 0 & puf == 0) {
      measure4 <- 0  
    } else if(suf > 0 & puf == 0){
      measure4 <- 1
    } else if(suf == 0 & puf > 0){
      measure4 <- min(c(puf / nrow(x), 1))
    }
  }
  measures <- list("measure2"=measure2,
                   "measure3"=measure3,
                   "measure4"=measure4)
  return(measures)
}

## ----meas2---------------------------------------------------------------
utilityModal <- function(x, y, variable){
  measure5 <- length(table(x[, variable])) / length(table(y[, variable]))
  return(measure5)
}

## ----measuresvar---------------------------------------------------------
utilityIndicator <- function(indicatorPUF, indicatorSUF){
  measure6 <- abs(indicatorPUF - indicatorSUF) / indicatorSUF 
  return(measure6)
}

## ----util1, cache=TRUE---------------------------------------------------
utility(puf, suf)

## ----util2, cache=TRUE---------------------------------------------------
utilityModal(puf.p, suf.p, "pb220a")
utilityModal(puf.p, suf.p, "pl031")

## ----util3, cache=TRUE---------------------------------------------------
i1 <- gini("eqInc", data=puf)$value
i2 <- gini("eqInc", data=suf)$value
utilityIndicator(i1, i2)

## ----util4, cache=TRUE---------------------------------------------------
# i1s <- gini("eqInc", breakdown="db040", data=puf)$valueByStratum$value
# i2s <- gini("eqInc", breakdown="db040", data=eusilc13)$valueByStratum$value
# abs(i2s - i1s) / i2s
# 
# ## ----util5, cache=TRUE---------------------------------------------------
# resSUF <- gini(inc = "eqInc",
#             weigths = "rb050",
#             breakdown = "db040", 
#             data = eusilc13)
# resVarSUF <- variance("eqInc", weights = "rb050", 
#             design = "db040", breakdown = "db040",
#             data = eusilc13, indicator = resSUF, R = 50,
#             X = calibVars(eusilc13$db040), seed = 123)
# resSUF <- resVarSUF$valueByStratum$value
# resVarSUF <- resVarSUF$varByStratum$var
# resPUF <- gini(inc = "eqInc",
#            weigths = "rb050",
#            breakdown = "db040", 
#            data = puf)
# resVarPUF <- variance("eqInc", weights = "rb050", 
#             design = "db040", breakdown = "db040",
#             data = puf, indicator = resPUF, R = 50,
#             X = calibVars(puf$db040), seed = 123)
# resPUF <- resVarPUF$valueByStratum$value
# resVarPUF <- resVarPUF$varByStratum$var
# 100*abs((resSUF - resPUF) / resSUF)
# 100*abs((resVarSUF - resVarPUF) / resVarSUF)
# 
# ## ----util6---------------------------------------------------------------
# (resSUF - resPUF)^2 + abs(resVarSUF - resVarPUF)


