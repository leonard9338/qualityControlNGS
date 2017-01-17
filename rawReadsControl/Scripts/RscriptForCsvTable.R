#!/usr/bin/env Rscript

## -----------------------------------------------------------------------------
## Libraries
## -----------------------------------------------------------------------------
# http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them

load.fun <- function(x) { 
  x <- as.character(substitute(x)) 
  if(isTRUE(x %in% .packages(all.available=TRUE))) { 
    eval(parse(text=paste("require(", x, ")", sep=""))) 
  } else { 
    eval(parse(text=paste("install.packages('", x, "', repos = 'http://cran.us.r-project.org')", sep=""))) 
    eval(parse(text=paste("require(", x, ")", sep=""))) 
  } 
} 

suppressMessages(load.fun("getopt"))



## -----------------------------------------------------------------------------
## Command line args
## -----------------------------------------------------------------------------

spec = matrix(c(
  'help',        'h', 0, "logical",	"Help about the program",
  'input_file',  'i', 1, "character",	"REQUIRED: tabulated csv file). E.g output from writeTablePerRun.py",
  'outdir',      'o', 1, "character", 	"Output directory. Default to current working directory.",
  'customer',			'c', 2, "character", "The customer", 
  'specie',      's', 2, "character", "The specie of the sample (only if just one specie for the moment)",
  'application', 'a', 2, "character", "The application (E. g ChIP-seq)", 
  'readsLength', 'l', 2, "character", 'The length of the reads',
  'runDate',			'd', 2, "character",	"The run date",
  'runName', 'N', 2, "character","The run name (E.g Run_165_NS500-072_24.11.2016_DP_BSoS)",
  'runNumber',			'n', 2, "character",	"The run number"), byrow=TRUE, ncol=5);

opt = getopt(spec)

print(opt)
# if help was asked, print a friendly message
# and exit with a non-zero error code
args <- commandArgs()

print(opt$specie)

if ( !is.null(opt$help) | is.null(opt$input_file) | is.null(opt$outdir) ) {
    cat("This script add the results of the run to the general table of runs")
  cat(getopt(spec, usage=TRUE))
  q(status=1)
}


#args = commandArgs(trailingOnly=TRUE)
# 1 chemin csv
# 2 numéro du run
# 3 runDate
# 4 customer
# 5 RunName
# 
# output


#args = c("/home/herault/SacapusMount/herault/qualityControl/Run_165_NS500-072_24.11.2016_DP_BSoS/result/qualityMetrics.csv","165",
 #        "24.11.2016","DElphine Potier","Run_165_NS500-072_24.11.2016_DP_BSoS","mouse","RNA-Seq","76/76","279","74.5",
 #        "/home/herault/SacapusMount/herault/qualityControl/Runs_TGML.csv")

#if (length(args)<1) {
#stop("At least one argument must be supplied (input file).\n", call.=FALSE)
#}



dataToAdd <- list(RunID_TGML=NA,RunDate=NA,Customer=NA,RunName_Basespace_TGML=NA,Samples=NA,
                Organism=NA,Application=NA,Flowcell_Mreads=NA,Flowcell_Cycles=NA,Lreads=NA,Gb_Expected=NA,
                Gb_output=NA,Mreads_Output=NA,percent_Reads_supequals_Q30=NA,percent_Duplicates=NA,percent_GC=NA,
                Load_pM=NA,k_per_mm2=NA,percentK_PF=NA)

dataToAdd<-data.frame(t(unlist(dataToAdd)))

dataRunRead <- read.csv(opt$input_file,header = T, sep = ",",dec=".",na.strings="NA")

dataToAdd$RunID_TGML <- opt$runNumber

dataToAdd$RunDate <- opt$runDate

dataToAdd$Customer <- sub("_"," ",opt$customer) # pour le cas ou "prénom_nom"

dataToAdd$RunName_Basespace_TGML <- opt$runName

dataToAdd$Samples <- length(unique(dataRunRead$nom))

dataToAdd$Organism <- opt$specie

dataToAdd$Application <- opt$application

dataToAdd$Flowcell_Mreads <- NA # voir csv ludo ou ajouter à GUI

dataToAdd$Flowcell_Cycles <- NA  # voir csv ludo ou ajouter à GUI

dataToAdd$Lreads <- opt$readsLength

### dataComputed from precedent one

dataToAdd$Gb_Expected <- as.integer(dataToAdd$Flowcell_Mreads)*as.integer(dataToAdd$Flowcell_Cycles)

dataToAdd$Mreads_Output <- sum(dataRunRead$Nombre_sequences_total)/(1000000*2) #MClusters en fait

dataToAdd$Gb_output <- dataToAdd$Mreads_Output*dataToAdd$Flowcell_Cycles # à vérifier avec nico

dataToAdd$percent_Reads_supequals_Q30 <- sum((dataRunRead$X..Q30/100)*dataRunRead$Nombre_sequences_total)/sum(dataRunRead$Nombre_sequences_total)*100

dataToAdd$percent_Duplicates <- sum((dataRunRead$Duplicats/100)*dataRunRead$Nombre_sequences_total)/sum(dataRunRead$Nombre_sequences_total)*100

dataToAdd$percent_GC <-sum((dataRunRead$GC./100)*dataRunRead$Nombre_sequences_total)/sum(dataRunRead$Nombre_sequences_total)*100

dataToAdd$Load_pM <- NA ##à lire dans fichier csv de ludo ou ajouter à GUI
     
dataToAdd$k_per_mm2 <- NA ## de même

dataToAdd$percentK_PF <- NA ## de même

dataToAdd<-as.data.frame(dataToAdd)

print(dataToAdd)



colnames(dataToAdd)<-c("RunID_TGML","RunDate","Customer","RunName_Basespace_TGML","Samples",
                       "Organism","Application","Flowcell_Mread","Flowcell_Cycles","Lreads","Gb_Expected",
                       "Gb_output","Mreads_Output","%Reads>=Q30","%Duplicates","%GC",
                       "Load_pM","k/mm2","%K_PF")

outFile <- paste(opt$outdir,"/Runs_TGML.csv",sep = "")

dataToAdd[1,which(dataToAdd[1,]=="TRUE")]<-NA
print(dataToAdd)

if (file.exists(outFile)){
  write.table(x=dataToAdd,outFile,append=TRUE,row.names = FALSE,col.names = FALSE, sep =";",quote = FALSE)
} else {
  write.table(x=dataToAdd,outFile,append=TRUE,row.names = FALSE,col.names = TRUE, sep =";",quote = FALSE)
}

