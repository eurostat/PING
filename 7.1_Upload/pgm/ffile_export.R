#STARTDOC
### ffile_export {#ffile_export}
#Create flat/DFT files for the dissemination of data on Eurobase.
#
#~~~r
#    > ffile_export(data, dimensions, values, domain, table, type, name, folderOut, digits, rounding, count, flags, threshold_n)
#~~~
#
#### Arguments
#* `data` : the table to be exported.
#* `dimensions` : a list containing the different dimensions, describing the different 
# values taken by each dimension. Please report to Examples for more details.
#* `values` : name of the column in the data giving the values to be disseminated.
#* `domain` : name of the domain, to be included in the header of the file.
#* `table` : name of the table, to be included in the header of the file.
#* `type` : type of the file to be produced. Either DFT ("DFT") or flat/txt ("FLAT").
#* `name` : name of the file to be produced. By default, the file takes the name of the table.
#* `folderOut` : folder where to place the file to be produced. By default, the current working directory.
#* `digits` : defines the decimal rounding of the values.
#* `rounding` : defines a possible simplification of the values (typically, a division by 1,000). 
# By default, no rounding.
#* `count` : name of the column in the data giving the number of observations used for the computation of 
# this particular cell. Useful to discard unreliable values.
#* `flags` : name of the column in the data giving the flagging values. By default, no flag are put on the 
# observations. Flagging values will be overriden when values discarded due to a low number of observations.
#* `threshold_n` : defines the bound under which the number of observations is considered as too for the 
# estimation to be reliable. By default, 30.
#* `mode` : mode of upload. Either "RECORDS" (by default) or "DELETE" for txt files, "MERGE" (the default)
# or "REPLACE" for DFT files. Other options will be soon phased out.
#
#### Returns
# It produces a text file that can be uploaded for the dissemination of statistics on Eurobase.
#
#### Examples
#
#~~~r
#    > library(eurostat)
#    >
#    > dataToExp <- get_eurostat("icw_sr_01", time_format = "num", stringsAsFactors = FALSE)
#    > dataToExp$flag <- "e"
#    > dim <- list(name = c("geo","time","age","unit"),
#    >             values = list(geo = unique(dataToExp$geo),
#    >                           time = unique(dataToExp$time),
#    >                           age = unique(dataToExp$age),
#    >                           unit = unique(dataToExp$unit)),
#    >             pos = sapply(c("geo","time","age","unit"), function(x) which(x == names(dataToExp))))
#    >
#    > ffile_export(data = dataToExp, dimensions = dim, values = "values", domain = "icw", table = "sr_01",
#    >                    type = "FLAT", name = "icw_sr01", digits = 1,
#    >                    count = "count", flags = "flag")
#~~~
#ENDDOC
# credits: pierre-lamarche

#' Creating text files for the dissemination on Eurobase.
#'
#' @param data the table to be exported.
#' @param dimensions a list containing the different dimensions, describing the different 
#' values taken by each dimension. Please report to [details] for more information.
#' @param values name of the column in the data giving the values to be disseminated.
#' @param domain name of the domain, to be included in the header of the file.
#' @param table name of the table, to be included in the header of the file.
#' @param type type of the file to be produced. Either DFT ("DFT") or flat/txt ("FLAT").
#' @param name name of the file to be produced. By default, the file takes the name of the table.
#' @param folderOut folder where to place the file to be produced. By default, the current working directory.
#' @param digits defines the decimal rounding of the values.
#' @param rounding defines a possible simplification of the values (typically, a division by 1,000). 
#' By default, no rounding.
#' @param count name of the column in the data giving the number of observations used for the computation of 
#' this particular cell. Useful to discard unreliable values.
#' @param flags name of the column in the data giving the flagging values. By default, no flag are put on the 
#' observations. Flagging values will be overriden when values discarded due to a low number of observations.
#' @param threshold_n defines the bound under which the number of observations is considered as too for the 
#' estimation to be reliable. By default, 30.
#' @param mode mode of upload. Either "RECORDS" (by default) or "DELETE" for txt files, "MERGE" (the default)
#' or "REPLACE" for DFT files. Other options will be soon phased out.
#'
#' @return It produces a text file that can be uploaded for the dissemination of statistics on Eurobase.
#' @details
#' @export
#'
#' @examples
#' ```
#' library(eurostat)
#'
#' dataToExp <- get_eurostat("icw_sr_01", time_format = "num", stringsAsFactors = FALSE)
#' dataToExp$count <- 50
#' dataToExp$flag <- "e"
#' dim <- list(name = c("geo","time","age","unit"),
#'            values = list(geo = unique(dataToExp$geo),
#'                          time = unique(dataToExp$time),
#'                          age = unique(dataToExp$age),
#'                          unit = unique(dataToExp$unit)),
#'            pos = sapply(c("geo","time","age","unit"), function(x) which(x == names(dataToExp))))
#'
#' ffile_export(data = dataToExp, dimensions = dim, values = "values", domain = "icw", table = "sr_01",
#'              type = "FLAT", name = "icw_sr01", digits = 1,
#'              count = "count", flags = "flag")
#'
#'``` 
#' 
ffile_export <- function(data, dimensions, values, domain, table, type = c("FLAT","DFT"), name = NULL, folderOut = getwd(), digits,
                         rounding = NULL, count, flags = NULL, threshold_n = 30, mode = NULL) {
  if (is.null(name))
    name <- table
  
  # check the existence and type of data
  if (!exists(deparse(substitute(data))))
    stop("Table ", deparse(substitute(data)), " does not exist.")
  if (!any(sapply(class(data), function(x) x %in% c("data.frame","matrix"))))
    warning("Table ", deparse(subsitute(data)), " may have not the right type.")
  
  # check the proper specification of dimensions
  # TODO: S3/S4 proper specification of a class `dimension` with a builder and checks (S4)
  if (length(unique(unlist(lapply(dimensions, length)))) != 1)
    stop("List ", deparse(substitute(dimensions)), " is misspecified.")
  if (max(dimensions$pos) > ncol(data))
    stop("Attribute pos for ", deparse(substitute(dimensions)), 
         " exceeds the size of the table.")
  if (any(sapply(dimensions$name, function(x) !x %in% names(data))))
    stop("Some of the dimensions are not contained in table", deparse(substitute(data)))
  
  # check existence and type of the value variable
  if (!values %in% names(data))
    stop("Variable ", values, " does not exist in ", 
         deparse(substitute(data)), ".")
  if (class(eval(parse(text = paste0(deparse(substitute(data)), "$", 
                                     values)))) != "numeric")
    warning("Variable ", values, "may have a wrong type.")
  
  # check existence and type of the count variable
  if (!count %in% names(data))
    stop("Variable ", count, " does not exist in ", 
         deparse(substitute(data)), ".")
  if (class(eval(parse(text = paste0(deparse(substitute(data)), "$", 
                                     count)))) != "numeric")
    warning("Variable ", count, "may have a wrong type.")
  
  # check existence and type of the flag variable
  if (!count %in% names(data))
    stop("Variable ", flag, " does not exist in ", 
         deparse(substitute(data)), ".")
  if (class(eval(parse(text = paste0(deparse(substitute(data)), "$", 
                                     flag)))) != "character")
    warning("Variable ", flag, "may have a wrong type.")
  
  # assigning a value to parameter mode and checking validity of the parameter
  if (is.null(mode)) {
    if (type == "FLAT")
      mode <- "RECORDS" else
        mode <- "MERGE"
  } else {
    if (type == "FLAT" & !mode %in% c("RECORDS", "DELETE", "REPLACE", "CUBE"))
      stop("Parameter mode is misspecified: ", deparse(substitute(mode), "is not a valid value."))
    if (type == "DFT" & !mode %in% c("MERGE", "REPLACE"))
      stop("Parameter mode is misspecified: ", deparse(substitute(mode), "is not a valid value."))
    if (type == "FLAT" & mode %in% c("REPLACE", "CUBE"))
      warning("Option ", deparse(substitute(mode)), "for parameter mode to be deprecated.")
  }
  
  data <- as.data.frame(data)
  n <- data[,count]
  if (!is.null(flags))
    flags <- data[,flags] else
      flags <- rep(NA,nrow(data))
  varsToTake <- c(dimensions$pos, which(names(data) == values))
  data <- data[, varsToTake]
  names(data) <- c(toupper(dimensions$name),"VALUES")
  if (is.null(rounding))
    data$VALUES <- round(data$VALUES, digits = digits) else
      data$VALUES <- round(data$VALUES/10**rounding, digits = 0)*10**rounding
  if (sum(!is.na(flags)) > 0) 
    data[!is.na(flags),]$VALUES <- paste(data[!is.na(flags),]$VALUES, flags[!is.na(flags)], sep = "~")
  if (sum(as.numeric(n < threshold_n)) > 0) 
    data[n < threshold_n,]$VALUES <- ":~n"
  tab <- expand.grid(dimensions$values)
  names(tab) <- toupper(dimensions$name)
  tab <- merge(tab, data, all.x = TRUE)
  if (sum(is.na(tab$VALUES)) > 0)
    tab[is.na(tab$VALUES),"VALUES"] <- ":"
  if (type == "FLAT") {
    txtTXT <- "FLAT_FILE=STANDARD\n"
    txtTXT <- paste0(txtTXT,"ID_KEYS=",domain,"_",table,"\n")
    txtTXT <- paste0(txtTXT,"FIELDS=",paste(toupper(dimensions$name), collapse = ",", sep = ""),"\n")
    txtTXT <- paste0(txtTXT,"UPDATE_MODE=", mode)
    setwd(folderOut)
    write.table(txtTXT, file = paste0(name,".txt"), quote = FALSE, col.names = FALSE, row.names = FALSE)
    write.table(tab, file = paste0(name,".txt"), append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
    write.table("END_OF_FLAT_FILE", file = paste0(name,".txt"), append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE)
  } else {
    Sys.setlocale("LC_ALL","English_United Kingdom.1252")
    txtDFT <- "INFO \nCreated: "
    txtDFT <- paste0(txtDFT, toupper(format(Sys.time(), "%a %d %b %Y %T")), "UPDATE_MODE =", mode, " \n")
    txtDFT <- paste0(txtDFT, "LASTUP \n", toupper(format(Sys.time(), "%a %d %b %Y %T"))," \n")
    txtDFT <- paste0(txtDFT, "TYPE \nV \nDELIMS \n(),@~ \n")
    txtDFT <- paste0(txtDFT, "DIMLST \n(soft,domain,table,",paste0(dimensions$name, collapse = ",", sep = ""),") \n")
    txtDFT <- paste0(txtDFT, "DIMUSE \n(R,N,N,", paste(rep("V",length(dimensions$name)), collapse = ","),") \n")
    txtDFT <- paste0(txtDFT, "POSTLST \n(r) \n(", domain,") \n(", table,") \n")
    for (k in 1:length(dimensions$name)) {
      txtDFT <- paste0(txtDFT,"(", paste(dimensions$values[[k]], collapse = ",", sep = ""),")\n")
    }
    txtDFT <- paste0(txtDFT, "FORMAT \nFORMATR \n")
    txtDFT <- paste0(txtDFT, "NOTAV \n: \n")
    txtDFT <- paste0(txtDFT, "VALLST \n(", paste(tab[,"VALUES"], collapse = ",", sep = ""), ")\n")
    setwd(folderOut)
    write.table(txtDFT, file = paste0(name,".dft"), quote = FALSE, col.names = FALSE, row.names = FALSE)
  }
}

## Tests

library(eurostat)
dataToExp <- get_eurostat("icw_sr_01", time_format = "num", stringsAsFactors = FALSE)
## should not find the table
ffile_export(data = test, dimensions = dim, values = "values", domain = "icw", table = "sr_01",
             type = "FLAT", name = "icw_sr01", digits = 1,
             count = "count", flags = "flag")

dataToExp$count <- 50
dataToExp$flag <- "e"
dim <- list(name = c("geo","time","age","unit"),
           values = list(geo = unique(dataToExp$geo),
                         time = unique(dataToExp$time),
                         age = unique(dataToExp$age),
                         unit = unique(dataToExp$unit)),
           pos = sapply(c("geo","time","age","unit"), function(x) which(x == names(dataToExp))))

ffile_export(data = dataToExp, dimensions = dim, values = "values", domain = "icw", table = "sr_01",
             type = "FLAT", name = "icw_sr01", digits = 1,
             count = "count", flags = "flag")

