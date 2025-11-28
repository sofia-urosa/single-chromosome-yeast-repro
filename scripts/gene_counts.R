#DESeq2 expects counts, not sequences
#from RSEM outputs: genes.results contains what we need

suppressPackageStartupMessages({
  suppressWarnings({
    library(DESeq2)
  })
})

#args parser
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: Rscript gene_counts.R <input_dir> <output_dir>")
}

input_dir  <- args[1]
output_dir <- args[2]

message("Creating a gene count matix (expression)")
message("Input directory: ", input_dir)
message("Output directory: ", output_dir)

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

#loading the data + making sure it exists:
read_rsem <- function(path) {
  df <- read.table(path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  df[, c("gene_id", "expected_count")]
}

#this only works because I know the name of the files.
#it won't work otherwise.
samples <- c("WT_1","WT_2","WT_3","SY14_1","SY14_2","SY14_3")

files <- file.path(input_dir, paste0(samples, ".genes.results"))

#check that they exist
for (f in files) {
  if (!file.exists(f)) stop("Missing file: ", f)
}

#list of dataframes after reading .results
count_list <- lapply(files, read_rsem)

#for each sample: take expected count, insert it
#into the count table under the sample name
count <- count_list[[1]][,"gene_id",drop=FALSE]
for (i in seq_along(samples)){
  count[[samples[i]]] <- count_list[[i]]$expected_count
}

#count looks like:
# gene_id  WT_1
# YYYY     3
# remove gene_id

rownames(count) <- count$gene_id
count$gene_id <- NULL

count <- round(count)
head(count)
