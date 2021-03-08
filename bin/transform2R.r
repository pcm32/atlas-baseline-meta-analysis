#!/usr/bin/env Rscript

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(XML))

option_list = list(
  make_option(
    c("-c", "--countstsv"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Path to a tabular file with counts, presumably library size normalised."
  ),
  make_option(
    c("--sdrf"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Path to SDRF file."
  ),
  make_option(
    c("--configuration"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Path to Atlas experiment configuration file."
  ),
  make_option(
    c("--output"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Path to output RDS file."
  ),
  make_option(
    c("--batch"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Batch variable in the metadata"
  ),
  make_option(
    c("--methods"),
    action = "store",
    default = NA,
    type = 'character',
    help = "Path to analysis methods file."
  ),
  make_option(
    c("--remove_single_batch_genes"),
    action = "store_true",
    default = FALSE,
    help = 'Remove all zero genes and single batch genes.'
  )
)

op<-OptionParser(option_list=option_list)
opt <- parse_args(op)

suppressPackageStartupMessages(require(ExpressionAtlasInternal))
suppressPackageStartupMessages(require(SummarizedExperiment))

remove_genes_with_expression_on_single_batch<-function(experiment) {
  ma<-NULL
  batches<-unique(experiment$batch)
  for ( batch in batches ) {
    rowSums(experiment[,colData(experiment)$batch == batch]@assays$data[[1]])->batchGeneSum
    if(is.null(ma)) {
      ma<-as.matrix(batchGeneSum)
    } else {
      ma<-cbind(ma, batchGeneSum)
    }
  }
  # remove rows that only have zeros, due to
  # https://github.com/brentp/combat.py/issues/11
  # producing all NaNs
  #rowSums(experimentSummary@assays$data[[1]]) == 0 -> zeroRows
  #print(paste0("Removing ", length(which(zeroRows)), " genes with zero expression on all samples."))
  #experimentSummary<-experimentSummary[!zeroRows, ]

  # ma holds on each column the sum of within samples of a batch
  # ma-row > 0 will give a boolean vector with trues when >0
  # sum(ma-row > 0, na.rm = TRUE) will count how many trues we have.
  # We want all the genes that are present in more than a single batch.
  genesMoreOneBatch<-apply(ma, 1, function(x) sum(x > 0, na.rm = TRUE) > 1 )
  print(paste0("Removed ",sum(!genesMoreOneBatch)," genes that were only present in a single batch."))
  return(experiment[genesMoreOneBatch, ])
}


experimentXMLlist <- parseAtlasConfig( opt$configuration )
atlasSDRF <- parseSDRF( opt$sdrf, experimentXMLlist$experimentType )
allAnalytics <- experimentXMLlist$allAnalytics
expressionsFile <- file.path( opt$countstsv )
expressions <- read.delim( expressionsFile, header=TRUE, stringsAsFactors=FALSE, row.names = 1 )


experimentSummary<-SimpleList( lapply( allAnalytics, function(analytics) {
  analyticsSDRF <- createAnalyticsSDRF( analytics, atlasSDRF )
  sumExp<-createSummarizedExperiment( expressions, analyticsSDRF, opt$methods )
  return(sumExp)
}) )

study_batch<-as.factor(experimentSummary$rnaseq[[opt$batch]])
experimentSummary$rnaseq@metadata<-list(batch=study_batch)
experimentSummary$rnaseq$batch<-study_batch

if( opt$remove_single_batch_genes ) {
  experimentSummary$rnaseq<-remove_genes_with_expression_on_single_batch(experimentSummary$rnaseq)
}


# Save the object to a file.
save( experimentSummary, file = opt$output )
