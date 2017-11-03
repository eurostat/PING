## ----include=FALSE-------------------------------------------------------
if (!require("knitr")) install.packages("knitr")
library(knitr)
opts_chunk$set(
concordance=TRUE
)

## ----globalSettings3, echo=FALSE, include = TRUE, cache = FALSE----------

knitr::opts_chunk$set(warning=FALSE, message=FALSE)
knitr::opts_chunk$set(fig.path="figures/") # cache=TRUE
knitr::opts_chunk$set(dev=c("pdf"))
knitr::opts_chunk$set(size="small")
options(width = 65)
#render_sweave()

## ----options1, echo=FALSE, message=FALSE, warning=FALSE------------------
options(prompt = "R> ")

## ----echo = FALSE--------------------------------------------------------
rm(list=ls())

## ----echo=FALSE, message=FALSE, warning=FALSE----------------------------
if (!require("devtools")) install.packages("devtools")
if (!require("sdcMicro")) install.packages("sdcMicro")
if (!require("simPop")) install.packages("simPop")
if (!require("parallel")) install.packages("parallel")
if (!require("laeken")) install.packages("laeken")
if (!require("Hmisc")) install.packages("Hmisc")
if (!require("stringr")) install.packages("stringr")
if (!require("simFrame")) install.packages("simFrame")
set.seed(23456)

## ----sessioninfo, echo=FALSE, results="asis"-----------------------------
utils::toLatex(sessionInfo())

## ----echo=FALSE----------------------------------------------------------
hook_output <<- knit_hooks$get('output')
knit_hooks$set(output = function(x, options) {
  # this hook is used only when the linewidth option is not NULL
  if (!is.null(n <- options$linewidth)) {
    x = knitr:::split_lines(x)
    # any lines wider than n should be wrapped
    if (any(nchar(x) > n)) x = strwrap(x, width = n)
    x = paste(x, collapse = '\n')
  }
  hook_output(x, options)
})

## ----person, echo=FALSE--------------------------------------------------
country <- "Austria"
year <- 2013
myfactor <- 1
calib <- TRUE

## ----importdata, cache = FALSE, include = TRUE---------------------------
if(country == "Austria"){
  orig_file <- "~/workspace/sga_sdc/silcPop/new_workfile.RData"
}

if(country == "France"){
  orig_file <- "Z:/Eurostat/FPA/Donn?es/SILC 2012/Fichiers originaux/indiv_complet_csv.csv"
}

## ----importdata2, cache = TRUE, include = TRUE, message=FALSE, warning=FALSE----
library("simPop")
x <- loadSILC(orig_file)

## ----import data 2, eval=TRUE, cache=TRUE, include = TRUE----------------
if(country == "Austria"){
  filed <- "~/workspace/sga_sdc/eurostatFormatData/2013/zielvar_d_eurostat2013.sav"
  filer <- "~/workspace/sga_sdc/eurostatFormatData/2013/zielvar_r_eurostat2013.sav"
  filep <- "~/workspace/sga_sdc/eurostatFormatData/2013/zielvar_p_eurostat2013.sav"
  fileh <- "~/workspace/sga_sdc/eurostatFormatData/2013/zielvar_h_eurostat2013.sav"
  suf4 <- loadSILC(filed = filed, filer = filer, filep = filep, fileh = fileh)
}
if(country == "France"){
## please use appropriate names for the csv files
  filed <- "~Z:/Eurostat/FPA/Donn?es/SILC 2012/SUFs/UDB_c12D_ver 2012-3 from 01-03-15.csv"
  filer <- "Z:/Eurostat/FPA/Donn?es/SILC 2012/SUFs/UDB_c12R_ver 2012-3 from 01-03-15.csv"
  filep <- "Z:/Eurostat/FPA/Donn?es/SILC 2012/SUFs/UDB_c12P_ver 2012-3 from 01-03-15.csv"
  fileh <- "Z:/Eurostat/FPA/Donn?es/SILC 2012/SUFs/UDB_c12H_ver 2012-3 from 01-03-15.csv"
}

## ----read4---------------------------------------------------------------
suf4 <- loadSILC(filed = filed, 
                 filer = filer, 
                 filep = filep, 
                 fileh = fileh)  

## ----mergeSILC-----------------------------------------------------------
suf <- mergeSILC(filed = suf4[["d"]], 
                 filer = suf4[["r"]], 
                 fileh = suf4[["h"]], 
                 filep = suf4[["p"]])

## ----echo = FALSE--------------------------------------------------------
if(country == "Austria"){
  suf.d <- suf4[["d"]]
  suf.r <- suf4[["r"]]
  suf.h <- suf4[["h"]]
  suf.p <- suf4[["p"]]
}
# suf <- x[,colnames(suf) %in% colnames(x)]

## ----check---------------------------------------------------------------
cn <- checkCol(x, suf)

## ------------------------------------------------------------------------
if(country == "Austria"){
  ## rx020, px020 age at the end of the income reference period
  suf$rx020 <- getAge(suf$rb080, year)
  suf$px020 <- suf$rx020
  ## household identification number
#  suf.r$rx030 <- 
}   

## ----silc, include = TRUE------------------------------------------------
eusilc <- chooseSILCvars(x, country = "Austria")

## ----addvars, eval=TRUE, cache=FALSE, include = TRUE---------------------
eusilc <- modifySILC(x = eusilc, country = "Austria")
breaks <- c(min(eusilc$age, na.rm = TRUE), seq(15, 65, 15), max(eusilc$age, na.rm=TRUE))
eusilc$ageCat <- cut(eusilc$age, 
                       breaks=breaks, include.lowest=TRUE)

## ----factorNAs, cache=FALSE----------------------------------------------
vars <- c("pl031", "pb220a", "pb190", "pl051", "pe040", "pl111")
for(i in vars){
  eusilc[, i] <- factorNA(eusilc[, i], newval = "NAs")
}

## ----strdata, linewidth=72-----------------------------------------------
str(eusilc)

## ----eval=TRUE, cache=FALSE, include = TRUE, echo=FALSE, linewidth=75----
if(.Platform$OS.type == "windows"){
  cat("simPop provides parallel computing. However, forking and is not efficient within your operating system with moderate or large data files. Therefore the use of one CPU is faster than using more than one. On Linux and OS X the number of CPU's used is the maximum of CPU's minus one.")
  cpus <- 1
} else {
  cat("simPop is parallel. The maximum number of CPU's minus one is used for computations")
  cpus <- NULL
  number <- parallel::detectCores() - 1
  cat(paste("\n On the machine used to generate this document, the number of parallel processes used is", number))
}

## ----eval=TRUE, cache=FALSE, include = TRUE------------------------------
eusilc$db090 <- eusilc$db090 / myfactor

## ----eval=TRUE, cache=FALSE, include = TRUE------------------------------
inp <- specifyInput(data=eusilc, 
                    hhid="db030", 
                    hhsize="hsize", 
                    strata="db040", # if country level, strata could be skipped
                    weight="db090")
inp

## ----simStructure2, eval=TRUE, cache=TRUE, include = TRUE----------------
eusilcP <- simStructure(inp, method="direct", 
                  basicHHvars=c("age", "rb090") )
eusilcP

## ----simCat6, eval=TRUE, cache=TRUE, include = TRUE, linewidth=72, results='hide'----
eusilcP <- simCategorical(eusilcP,
                          additional = c("pl031","pb220a", "pb190",
                                         "pl051", "pe040", "pl111"),
                          regModel = rep("available", 6),
                          nr_cpus=cpus, MaxNWts=5000 )
## for latter use:
age <- as.numeric(as.character(pop(eusilcP)$age))
breaks <- c(min(age, na.rm = TRUE), seq(15, 65, 15), max(age, na.rm=TRUE))
ageCat <- cut(age, breaks=breaks, include.lowest=TRUE)
pop(eusilcP, var="ageCat") <- ageCat

eusilcP 

## ----breaks--------------------------------------------------------------
breaks <- getBreaks(eusilc$pgrossIncome, eusilc$rb050, 
                      upper = Inf, equidist = FALSE, zeros = TRUE)
breakshh <- getBreaks(eusilc$hgrossIncome, eusilc$rb050, 
                      upper = Inf, equidist = FALSE, zeros = TRUE)
breakshhm <- getBreaks(eusilc$hgrossminus, eusilc$rb050, 
                      upper = Inf, equidist = FALSE, zeros = TRUE)

## ----simCont, eval=TRUE, cache=TRUE, include = TRUE, message=FALSE, warning=FALSE, linewidth=75, results='hide'----
eusilcP <- simContinuous(eusilcP, breaks = breaks, additional = "pgrossIncome",
                          upper = 200000, equidist = FALSE, 
                          zeros=TRUE, nr_cpus=cpus, MaxNWts=10000,
                          regModel = formula(~ age + rb090 + pl031 + pb220a))

## truncate personal income
p <- pop(eusilcP)$pgrossIncome
m <- max(samp(eusilcP)$pgrossIncome)
p[p > m] <- m
pop(eusilcP, var="pgrossIncome") <- p

eusilcP <- simContinuous(eusilcP, breaks = breakshh, additional = "hgrossIncome",
                          upper = 200000, equidist = FALSE, zeros=FALSE,
                          nr_cpus=cpus, MaxNWts=10000,
                          regModel = formula(~ hsize + age + rb090 + pl031 + pb220a),
                          byHousehold = "random")
## truncate hh income
p <- pop(eusilcP)$hgrossIncome
m <- max(samp(eusilcP)$hgrossIncome)
p[p > m] <- m
pop(eusilcP, var="hgrossIncome") <- p

eusilcP <- simContinuous(eusilcP, breaks = breakshhm, additional = "hgrossminus",
                          upper = 200000, equidist = FALSE, zeros=FALSE,
                          nr_cpus=cpus, MaxNWts=10000,
                          regModel = formula(~ hsize + age + rb090 + pl031 + pb220a),
                          byHousehold = "random")
eusilcP 

## ----simCompP, eval=TRUE, cache=TRUE, include = TRUE---------------------
if(country == "France"){
  ## in France "py021g" is missing
  pcomponents <- c("py010g","py050g","py080g",
                 "py090g","py100g", "py110g","py120g",
                 "py130g","py140g")

} else {
  pcomponents <- c("py010g","py021g","py050g","py080g",
                   "py090g","py100g", "py110g","py120g",
                   "py130g","py140g")
}

eusilcP <- simComponents(eusilcP, 
                          total = "pgrossIncome", 
                          components = pcomponents, 
                          conditional = c("pl031","ageCat"))

## ------------------------------------------------------------------------
hcomponents <- c("hy040g", "hy050g", "hy060g", "hy070g",
                "hy080g", "hy090g", "hy110g")
eusilcP <- simComponents(eusilcP, 
                        total = "hgrossIncome", components = hcomponents, 
                        conditional = c("hsize", "db040"))

hminuscomponents <- c("hy120g","hy130g","hy140g")
eusilcP <- simComponents(eusilcP, 
                        total = "hgrossminus", components = hminuscomponents, 
                        conditional = c("hsize","db040"))

## ----removeHH, echo = FALSE----------------------------------------------
## delete unnecessary files
rm(hhIncome,eusilcH)

## ----store new file, echo=FALSE, cache=TRUE------------------------------
save(eusilcP, file = "eusilcP.RData")

## ----showP, linewidth=72-------------------------------------------------
eusilcP

## ----drawSample, linewidth=72--------------------------------------------
## ----table of number of households per region (used drawing the puf)
x2 <- data.table(x[,c("db040","db030")])
setkey(x2, db030)
hh <- x2[, unique(db040), by = db030]
tab <- table(hh$V1)
## number of households in all districts
tab
tab <- as.numeric(table(hh$V1))
## number of households:
sum(tab)

## stratified group sampling, equal size
set.seed(23456)
dim(pop(eusilcP))
class(pop(eusilcP))
puf <- draw(data.frame(pop(eusilcP)), 
             design = "db040", 
             grouping = "db030", 
             size = tab)

## rename weight vector
colnames(puf)[which(colnames(puf) == ".weight")] <- "rb050"
puf$rb050 <- puf$rb050 * myfactor

## size of the data
dim(puf)
nrow(puf[!duplicated(puf$db030), ])

## ------------------------------------------------------------------------
if(calib){
  totals1 <- tableWt(eusilc[, c("rb090","db040")], weights=eusilc$rb050)
  weights2 <- calibSample(puf, as.data.frame(totals1), w = puf$rb050)  
  puf$rb050_calib <- weights2$final_weights
}

## ----sumamries, fig.height = 5, out.width='9cm', echo = FALSE, fig.align='center'----
gg <- ggplot(x, aes(x = rb050)) + geom_density(data = x, aes(x = rb050), color = "blue") +  geom_density(data = data.frame(puf), aes(x = rb050), color = "red")
print(gg)
summary(x$rb050)
summary(puf$rb050)

## ----rowsumspgi, linewidth=72, tidy = TRUE-------------------------------
if(is.factor(suf$py010g)){
  require(dplyr)
  fac <- c("py010g", "py021g", "py050g", "py080g", "py090g", "py100g", "py110g", 
           "py120g", "py130g", "py140g", "hy080g", "rb050", "pb040")
  suf <- suf %>% mutate_each_(funs(as.character), fac) %>% mutate_each_(funs(as.numeric), fac)
}

suf$pgrossIncome <- rowSums(suf[, c("py010g","py021g","py050g","py080g",
                                    "py090g","py100g", "py110g","py120g",
                                    "py130g","py140g")], na.rm=TRUE)

suf$hgrossIncome <- rowSums(suf[, c("hy040g","hy050g","hy060g","hy070g","hy080g",
                                    "hy090g","hy110g")], na.rm = TRUE)
                                 

## ----addvarspuf, cache=TRUE, linewidth=72--------------------------------
puf$pb040 <- puf$rb050
puf$hb030 <- puf$db030
puf$px030 <- puf$db030
puf$rx030 <- puf$db030
#puf$pb030 <- puf$pid
#puf$rb030 <- puf$pid
### NEW:
puf$hid <- as.character(puf$pid)
puf$hid <- as.numeric(sapply(puf$hid, function(x) substr(x, 1, nchar(x)-2)))
puf$hx040 <- puf$hsize
puf$pb150 <- puf$rb090

## add age variables:
if(!is.numeric(puf$age)) {
  puf$rx020 <- as.numeric(as.character(puf$age))
} else {
   puf$rx020 <- puf$age
}
puf$px020 <- puf$rx020

## add age difference (if rx010 is provided):

if(country == "Austria"){
  ## date of interview not found in suf
  puf$rx010 <- puf$rx020
} else {
  tab <- wtd.table(suf$rx010 - suf$rx020, weights = suf[, "rb050"], type = "table")
  p <- tab/sum(suf[, "rb050"])
  age.dif <- sample(x = c(0, 1), size = dim(puf)[1], prob = p, replace = TRUE)
  puf$rx010 <- puf$rx020 + age.dif
}

## add the equivalised household size
puf$hx050 <- eqSS("db030", "rx020", data=puf)


## compute income variables
sum.pgrossIncome <- aggregate(puf[,c("py010g","py021g","py050g","py080g","py090g",
                                     "py100g","py110g","py120g","py130g","py140g")],
                              by=list(puf$db030),FUN=sum, na.rm=TRUE)
names(sum.pgrossIncome)[names(sum.pgrossIncome)=="Group.1"] <- "db030"
puf <- merge(x=puf,y=sum.pgrossIncome,by="db030",suffixes=c("",".hh"))

## hy010: total household gross income 
puf$hy010 <- puf$hy040g + puf$hy050g + puf$hy060g + puf$hy070g + puf$hy080g + 
             puf$hy090g + puf$hy110g + puf$py010g.hh + puf$py021g.hh + 
             puf$py050g.hh + puf$py080g.hh + puf$py090g.hh +
             puf$py100g.hh + puf$py110g.hh + puf$py120g.hh + 
             puf$py130g.hh + puf$py140g.hh

## hy020: total disposable household income
puf$hy020 <- puf$hy010 - puf$hy120g - puf$hy130g - puf$hy140g

## hy022: total disposable household income before social transfers 
## other than old-age and survivor?s benefits
puf$hy022 <- puf$hy040g + puf$hy080g + puf$hy090g + puf$hy110g - puf$hy120g - 
             puf$hy130g - puf$hy140g + puf$py010g.hh + puf$py021g.hh + 
             puf$py050g.hh + puf$py080g.hh + puf$py100g.hh + puf$py110g.hh

## hy023: total disposable household income berfore social transfers 
## including than old-age and survivor's benefits

puf$hy023 <- puf$hy040g + puf$hy080g + puf$hy090g + puf$hy110g - puf$hy120g - 
             puf$hy130g - puf$hy140g + puf$py010g.hh + puf$py021g.hh + 
             puf$py050g.hh + puf$py080g.hh

keep <- names(puf)[str_sub(names(puf), start= -3)!=".hh"]
puf <- subset(puf,select=keep)

if(country == "France"){
  # add a NA variable for py021g in order to mimic the SUF
  puf$py021g <- as.numeric(rep(NA, length(puf$db030)))
}

## remove level 'NAs'
puf[puf == "NAs"] <- NA
w <- apply(puf, 2, function(x) "NAs" %in% levels(x))
w <- which(unlist(lapply(puf, function(x) "NAs" %in% levels(x))))
for(j in w){
  puf[, j] <- puf[, j][drop = TRUE]
}

## ----cache=TRUE, linewidth=72--------------------------------------------
delete <- c(names(suf)[str_sub(names(suf), start= -2)=="_f"],
            names(suf)[str_sub(names(suf), start= -2)=="_i"],
            names(suf)[str_sub(names(suf), start= -1)=="n"],
            "db050","db060","db070","db070","db075",
            "db100","db110","db120","db130","db135",
            "pb160","pb170","pb180","hb070","hb080",
            "hb090","rb220","rb230","rb240","rb270",
            "pb210","pe030","pl073","pl074","pl075",
            "pl076","pl080","pl085","pl086","pl087",
            "pl088","pl089","pl090","pl200","pl211a",
            "pl211b","pl211c","pl211d","pl211e","pl211f",
            "pl211g","pl211h","pl211i","pl211j","pl211k","pl211l",
            "hh031","rb031","db080","rb060","rb062",
            "rb063","rb064","rl070","rb180","rb190",
            "rb140","rb150")

simulated <- colnames(puf)

## ----createRestvars------------------------------------------------------
vars <- function(char1 = "d", p = puf.d, s = suf){
  nam <- names(s)[substr(names(s), 1, nchar(char1)) == char1 & 
                      !(names(s) %in% names(p)) &
                      !(names(s) %in% delete) & !(names(s) %in% simulated)]
  return(nam)
}

## d-file: household register
puf.d <- puf[!duplicated(puf$db030),substring(names(puf),1,1)=="d"]
ss <- suf[!duplicated(suf$db030), ]
for (i in vars()) {
  puf.d[, i] <- univariate.dis(puf.d, data = ss, i, "rb050")
}

## h-file: household data 
puf.h <- puf[!duplicated(puf$db030),substring(names(puf),1,1)=="h"]
for (i in vars(char1 = "hb", p = puf.h)) {
  puf.h[, i] <- univariate.dis(puf.h, ss , i ,"rb050")
}

hgrossIncome5 <- quantile(puf[!duplicated(puf$db030),"hgrossIncome"],probs=seq(0,1,0.2))
hgrossIncome5[1] <- -Inf
hgrossIncome5[6] <- Inf
if(country == "Austria"){
  suf$hgrossIncome <- rowSums(suf[, c("hy040g","hy050g","hy060g",
          "hy070g", "hy080g", "hy090g", "hy110g")], na.rm = TRUE)
}
suf$hgrossIncome5 <- cut(suf$hgrossIncome, breaks=hgrossIncome5, labels=seq(1,5,1))
puf.h$hgrossIncome5 <- cut(puf.h$hgrossIncome, breaks=hgrossIncome5, labels=seq(1,5,1))
ss <- suf[!duplicated(suf$db030), ]
for (i in vars("hh", puf.h)) {
  puf.h[, i] <- conditional.dis(puf.h, suf[!duplicated(suf$db030),], i,
                           "hgrossIncome5","rb050")
}
for (i in vars("hs", puf.h)) {
  puf.h[, i] <- conditional.dis(puf.h, ss, i,
                           "hgrossIncome5","rb050")
}
vars("hs", puf.h)
colnames(puf.h)
for (i in vars("h", puf.h)) {
  puf.h[, i] <- univariate.dis(puf.h, ss, i, "rb050")
}

## r-file: personal register
puf.r <- puf[,substring(names(puf), 1, 1) == "r"]
for (i in vars("r", puf.r, suf.r)) {
  puf.r[, i] <- univariate.dis(puf.r, suf.r, i,"rb050")
}

## adjustment of year of birth
puf.r$rb080 <- as.numeric(as.character(puf.r$rb010)) - 1 - puf.r$rx020

## p-file: personal data 
puf.p <- puf[which(puf$px020 > 15),substring(names(puf),1,1)=="p"]
s2 <- suf[which(suf$px020 > 15), ]
for (i in vars("pb", puf.p)) {
  puf.p[, i] <- univariate.dis(puf.p, s2, i ,"pb040")
}

pgrossIncome5 <- quantile(puf.p[,"pgrossIncome"],probs=seq(0,1,0.2))
pgrossIncome5[1] <- -Inf
pgrossIncome5[6] <- Inf
puf.p$pgrossIncome5 <- cut(puf.p[,"pgrossIncome"], breaks=pgrossIncome5, 
                         labels=seq(1,5,1))

if(country == "Austria"){
suf$pgrossIncome <- rowSums(suf[, c("py010g","py021g","py050g","py080g",
        "py090g","py100g", "py110g","py120g", "py130g","py140g")], na.rm = TRUE)
}
suf$pgrossIncome5 <- cut(suf$pgrossIncome, breaks=pgrossIncome5, labels=seq(1,5,1))
s2 <- suf[which(suf$px020 > 15), ]
for (i in vars("pe", "puf.p")) {
  puf.p[, i] <- conditional.dis(puf.p, s2, i,
                           "pgrossIncome5","pb040")
}
for (i in vars("ph", puf.p)) {
  puf.p[, i] <- conditional.dis(puf.p, s2, i,
                           "pgrossIncome5","pb040")
}
for (i in vars("pl", puf.p)) {
  puf.p[, i] <- conditional.dis(puf.p, s2, i,
                           "pgrossIncome5","pb040")
}
for (i in vars("p", puf.p)) {
  puf.p[, i] <- univariate.dis(puf.p, s2, i, "pb040")
}

## adjustment of year of birth
puf.p$pb140 <- as.numeric(as.character(puf.p$pb010)) - 1 - puf.p$px020

## second digit of occupation (pl051)
puf.p$pl051.1d <- puf.p$pl051
suf$pl051.1d <- as.factor(trunc(suf$pl051/10))
library("plyr")
if(country == "Austria"){
  cat("some modifications due to combined level at the beginning")
  suf$pe040 <- factor(suf$pe040)
  puf.p$pe040 <- factor(puf.p$pe040) 
  suf$pl051.1d <- revalue(suf$pl051.1d, c("0"="0-1", "1"="0-1" ))
  suf$pe040 <- revalue(suf$pe040, c("0"="0-1", "1"="0-1" ))
} 

suf$pl051 <- factorNA(as.factor(suf$pl051), newval = "NAs")
suf$pl051.1d <- factorNA(suf$pl051.1d, newval = "NAs")
puf.p$pl051.1d <- factorNA(puf.p$pl051.1d, newval = "NAs")
puf.p[, "pl051"] <- conditional.dis(puf.p, suf[which(suf$px020>15),],
                           additional = "pl051", conditional = "pl051.1d", 
                         weights = "pb040", fNA = "NAs")

## ----echo = FALSE--------------------------------------------------------
rm(hgrossIncome5,pgrossIncome5,i,var.d,var.h,var.hb,var.hh,var.hs,var.p,
   var.pb,var.pe,var.ph,var.pl,var.r)

## ----cache=TRUE----------------------------------------------------------
#year of birth:
min <- as.numeric(as.character(puf.p$pb010))[1]-81
puf.p$pb140[which(puf.p$pb140<min)] <- min
puf.r$rb080[which(puf.r$rb080<min)] <- min

#age:
max <- 80
puf.r$rx010[which(puf.r$rx010>max)] <- max
puf.r$rx020[which(puf.r$rx020>max)] <- max
puf.p$px020[which(puf.p$px020>max)] <- max

## ----echo = FALSE--------------------------------------------------------
if(country == "Austria"){
  rm(hminuscomponents, keep, max, min)
} else {
  rm(age.dif, hminuscomponents, keep, max, min)
}

## ----echo = TRUE---------------------------------------------------------
if(country == "Austria"){
  filename <- paste0("~/workspace/sga_sdc/silcPop/simData", year, ".RData")
  save(suf.d, suf.p, suf.r, suf.h, #suf.hh, 
       puf.d, puf.p, puf.r, puf.h,
       puf, suf, eusilc, file = filename)
}

## ----saveCsvs, eval=TRUE, cache=TRUE, include = TRUE, echo=FALSE, eval=FALSE----
## if(country == "FRANCE"){
##   setwd("Z:/Eurostat/FPA/Donn?es/SILC 2012/PUFs")
## }
## write.csv(x = puf, file = "puf_SILC2012.csv", col.names = TRUE)
## write.csv(x = puf.p, file = "puf_p_SILC2013.csv", col.names = TRUE)
## write.csv(x = puf.h, file = "puf_h_SILC2013.csv", col.names = TRUE)
## write.csv(x = puf.r, file = "puf_r_SILC2013.csv", col.names = TRUE)
## write.csv(x = puf.d, file = "puf_d_SILC2013.csv", col.names = TRUE)
## 
## ## optionally one may also save the suf,
## ## since a few modifications were done
## write.csv(x = suf, file = "suf_SILC2012.csv", col.names = TRUE)
## write.csv(x = suf.p, file = "suf_p_SILC2013.csv", col.names = TRUE)
## write.csv(x = suf.h, file = "suf_h_SILC2013.csv", col.names = TRUE)
## write.csv(x = suf.r, file = "suf_r_SILC2013.csv", col.names = TRUE)
## write.csv(x = suf.d, file = "suf_d_SILC2013.csv", col.names = TRUE)

## ----saveAustria, echo = FALSE-------------------------------------------
if(country == "Austria") save.image("image.RData")

## ----remove vars---------------------------------------------------------
## (add variable names that you don't want to have included)
remove_vars <- function(x, 
                        delete = c("hgrossminusCat", "pgrossIncomeCat",
                                   "hgrossIncomeCat", "db062",
                                    "hgrossIncome", "hgrossminus",
                                    "pgrossIncome", "hgrossIncome5",
                                    "pgrossIncome5", "pl051.1d",
                                    "X", "X.1", "hsize"), 
                        deletesub = c("hx", "rx", "px"),
                        duplicated = c("hsize", "hid", "pid")){
  ss <- !(substr(names(x), 1, 2) %in% substr(deletesub, 1, 2)) & 
                    !(names(x) %in% delete) & !(names(x) %in% duplicated)
  return(x[, ss])
}

puf.p <- remove_vars(puf.p)  
puf.h <- remove_vars(puf.h)  
puf.d <- remove_vars(puf.d)  
puf.r <- remove_vars(puf.r)  
suf.p <- remove_vars(suf.p)  
suf.h <- remove_vars(suf.h)  
suf.d <- remove_vars(suf.d)  
suf.r <- remove_vars(suf.r)  

## ------------------------------------------------------------------------
require("plyr")
puf.r$rb090 <- revalue(puf.r$rb090, c("male" = 1, "female" = 2)) 
puf.p$pb150 <- revalue(puf.p$pb150, c("male" = 1, "female" = 2)) 

## ----round---------------------------------------------------------------
# Household income variables HYxxx
HIncomeVariables <- subset(colnames(puf.h), 
                           substr(colnames(puf.h),1,2) %in% c("hy"))
for (i in HIncomeVariables){
  puf.h[,which(colnames(puf.h)==i)] <- 
    round(as.numeric(puf.h[,which(colnames(puf.h)==i)],digits=2))
}
# Personal income variables PYxxx
PIncomeVariables <- subset(colnames(puf.p), 
                           substr(colnames(puf.p),1,2) %in% c("py"))
for (i in PIncomeVariables){
  puf.p[,which(colnames(puf.p)==i)] <- 
    round(as.numeric(puf.p[,which(colnames(puf.p)==i)],digits=2))
}

## ----id------------------------------------------------------------------
if(country == "France"){
require("stringr")
strip <- function(x){
  l <- str_length(x)
  p <- str_locate(x, "[.]")[1]
  y <- str_sub(x, 1, p-1)
  if (p+1 == l) y <- paste(y, "0", sep = "")
  return(paste(y, str_sub(x, p+1, -1), sep = ""))
}
puf_p$pb030 <- sapply(puf.p$pb030, strip)
puf_r$rb030 <- sapply(puf.r$rb030, strip)
}

## ------------------------------------------------------------------------
suf.d <- remove_vars(suf.d, delete = c("X", "X.1"), 
                     deletesub = c(""), duplicated = c(""))
suf.h <- remove_vars(suf.h, delete = c("X", "X.1"), 
                     deletesub = c(""), duplicated = c(""))
suf.p <- remove_vars(suf.p, delete = c("X", "X.1"), 
                     deletesub = c(""), duplicated = c(""))
suf.r <- remove_vars(suf.r, delete = c("X", "X.1"), 
                     deletesub = c(""), duplicated = c(""))

## ----missVars------------------------------------------------------------
addMissingVars <- function(puf = puf.d, suf = suf.d) {
  # Names of variables in PUF and SUD
  listVarSUF <- colnames(suf)
  listVarPUF <- colnames(puf)
  
  for (i in listVarSUF) {
    if (i %in% listVarPUF) {
      # Do nothing if already simulated
      puf <- puf
    } else {
      ## USE blank values for the new (non-simulated) column
      newCol <- rep(NA, nrow(puf))
      puf<- data.frame(puf, newCol)
      ## Add the good name to the column
      colnames(puf)[which(names(puf) == "newCol")] <- i
    }
  }
  return(puf)
}

## ----addMissvarsaction---------------------------------------------------
puf.p <- addMissingVars(puf.p, suf.p)  
puf.h <- addMissingVars(puf.h, suf.h)  
puf.d <- addMissingVars(puf.d, suf.d)  
puf.r <- addMissingVars(puf.r, suf.r)   

## ------------------------------------------------------------------------
if(country == "France"){
weight <- unique(data.frame(
  id=as.numeric(as.character(substr(puf.r$rb030, 1, nchar(puf.r$rb030) - 2))), 
  weight = puf.r$rb050))
puf.d$db090 <- weight$weight
}

## ----alphabetic----------------------------------------------------------
puf.p <- puf.p[, colnames(suf.p)] 
puf.h <- puf.h[, colnames(suf.h)] 
puf.d <- puf.d[, colnames(suf.d)] 
puf.r <- puf.r[, colnames(suf.r)] 

## ----uppercase-----------------------------------------------------------
names(puf.p) <- toupper(names(puf.p))
names(puf.h) <- toupper(names(puf.h))
names(puf.d) <- toupper(names(puf.d))
names(puf.r) <- toupper(names(puf.r))

## ----writefilesfinal-----------------------------------------------------
puf.p$pl051 <- revalue(puf.p$pl051, c("NAs"=NA))
where <- "/data/home/templ/workspace/sga_sdc/silcPop/"
write.csv(puf.p, file = paste0(where, "puf_p_SILC2013.csv"), na = "")
write.csv(puf.h, file = paste0(where, "puf_h_SILC2013.csv"), na = "")
write.csv(puf.d, file = paste0(where, "puf_d_SILC2013.csv"), na = "")
write.csv(puf.r, file = paste0(where, "puf_r_SILC2013.csv"), na = "")

## ----writefilesfinal2----------------------------------------------------
write.csv(x = suf, file = paste0(where, "suf_SILC2013.csv"), 
          col.names = TRUE, na = "")
write.csv(x = suf.p, file = paste0(where, "suf_p_SILC2013.csv"), 
          col.names = TRUE, na = "")
write.csv(x = suf.h, file = paste0(where, "suf_h_SILC2013.csv"), 
          col.names = TRUE, na = "")
write.csv(x = suf.r, file = paste0(where, "suf_r_SILC2013.csv"), 
          col.names = TRUE, na = "")
write.csv(x = suf.d, file = paste0(where, "suf_d_SILC2013.csv"), 
          col.names = TRUE, na = "")

