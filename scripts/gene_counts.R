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

#create DESeq db

condition <- factor(c(rep("WT",3),rep("SY14",3)))
print(condition)

coldata <- data.frame(
  row.names = samples,
  condition = condition
)

dds <- DESeqDataSetFromMatrix(
  countData = count,
  colData   = coldata,
  design    = ~ condition
)

#filter low-count genes
dds <- dds[rowSums(counts(dds)) > 10, ]

#run DESeq2
dds <- DESeq(dds)

res <- results(dds)
res$gene_id <- rownames(res)

#raw counts
raw_counts <- counts(dds, normalized = FALSE)

#order by adj pvalue
res <- res[order(res$padj), ]

#with definition of fold change more than 2 and false discovery rate (FDR) <0.001
sig <- subset(res, abs(log2FoldChange) > 1 & padj < 0.001)


#make gene_id the first col:
res_out <- res[, c("gene_id", setdiff(colnames(res), "gene_id"))]
sig_out <- sig[, c("gene_id", setdiff(colnames(sig), "gene_id"))]

#export results

write.csv(res_out, file.path(output_dir, "full_dseq_res.csv"), row.names = FALSE)
write.csv(sig_out, file.path(output_dir, "sig_dseq_res.csv"), row.names = FALSE)

#we cant create graphs easily inside of the container, so we prep the data here

vsd <- vst(dds, blind = TRUE)
mat <- assay(vsd)

mat_out <- data.frame(
  gene_id = rownames(mat),
  mat,
  row.names = NULL        # ensures rownames are NOT reused
)

write.csv(mat_out, file.path(output_dir, "hm.csv"), row.names = FALSE)
head(raw_counts)

raw_out <- data.frame(
  gene_id = rownames(raw_counts),
  raw_counts,
  row.names = NULL        # ensures rownames are NOT reused
)

write.csv(raw_out, file.path(output_dir, "full_raw_counts.csv"), row.names = FALSE)

message("Done! Results saved in: ", output_dir)