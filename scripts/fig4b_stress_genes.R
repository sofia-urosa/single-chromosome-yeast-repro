# fig 4b classifies  differentially expressed genes in SY14 compared to BY4742 into:
#   TPE (Telomere Position Effect) -> genes very close to telomeres
#   Stress-response genes -> genes involved in cellular stress pathways
#   Other

# this code does it by:
#   1. Which genes are differentially expressed?
#   2. Where are they? 
#   3. Are they related to a stress pathway?

# get output from DESeq for expression
res <- read.csv("outputs/rnaseq/expression_analysis/full_dseq_res.csv", header = TRUE, check.names = FALSE)

# replace padj NAs for 1 just in case
res$padj[is.na(res$padj)] <- 1

# read info of reference genome
# gtf -> POSITION of every read
gtf <- read.table(
  file.path("originals/ref/S288C.gtf"),
  sep = "\t",
  comment.char = "#", # ignore anything that starts with '#'
  stringsAsFactors = FALSE,
  header = FALSE
)

# keep only the genes (V3: feature = genes, exon, etc)
gtf_gene <- gtf[gtf$V3 == "gene", ]

extract_gene_id <- function(attr) {
  # remove leading/trailing spaces
  attr <- trimws(attr)
  # find "gene_id " followed by characters until the next semicolon
  # regex:
  #  .*gene_id[[:space:]]+ gene_id + one space
  #  ([^;]+) one or more characters that are not ;
  sub(".*gene_id[[:space:]]+([^;]+);.*", "\\1", attr)
}

# do it for all genes (V9: attribute [gene_id YAL068C; transcript_id ;])
gene_ids <- vapply(gtf_gene$V9, extract_gene_id, character(1))

# gene coordinate table
gene_table <- data.frame(
  gene_id = gene_ids,
  chr     = gtf_gene$V1,
  start   = gtf_gene$V4,
  end     = gtf_gene$V5,
  stringsAsFactors = FALSE
)

# fasta index for distance to telomeres
# we only need chr and len (col1 col2)

# fai -> chromosome size
fai <- read.table(
  file.path("originals/ref/S288C.fa.fai"),
  header = FALSE,
  stringsAsFactors = FALSE
)

colnames(fai) <- c("chr", "length", "offset", "linelen", "linebytes")
chr_len <- setNames(fai$length, fai$chr)

gene_table$chr_len <- chr_len[gene_table$chr]
gene_table$mid <- (gene_table$start + gene_table$end)/2

gene_table$dist_to_telo <- pmin(gene_table$mid -1, gene_table$chr_len - gene_table$mid)

summary(gene_table$dist_to_telo)

res_annot <- merge(res, gene_table[, c("gene_id", "chr", "start", "end", "dist_to_telo")], by = "gene_id", all.x = TRUE)

sig <- subset(res_annot,
              abs(log2FoldChange) >= 1 & padj < 0.001)

head(res_annot)

cutoff <- 20000

sig$tpe_flag <- !is.na(sig$dist_to_telo) & sig$dist_to_telo <= cutoff

table(sig$tpe_flag)
  
###
obo_file <- file.path("originals/ref/go.obo")
obo <- readLines(obo_file)

term_starts <- grep("^\\[Term\\]", obo)

get_block <- function(i) {
  start <- term_starts[i]
  end <- if (i == length(term_starts)) length(obo) else term_starts[i+1] - 1
  obo[start:end]
}

GO_IDs <- c()
GO_names <- c()

for (i in seq_along(term_starts)) {
  block <- get_block(i)
  
  id_line <- block[grep("^id: GO:", block)]
  name_line <- block[grep("^name:", block)]
  
  # Skip malformed terms
  if (length(id_line) != 1 || length(name_line) != 1) next
  
  go_id <- sub("^id: ", "", id_line)
  go_name <- sub("^name: ", "", name_line)
  
  GO_IDs   <- c(GO_IDs, go_id)
  GO_names <- c(GO_names, go_name)
}

go_map <- data.frame(
  GO_ID = GO_IDs,
  GO_name = GO_names,
  stringsAsFactors = FALSE
)

gaf_file <- file.path("originals/ref/gene_association.sgd.gaf")

gaf <- read.table(
  gaf_file,
  sep = "\t",
  comment.char = "!",
  stringsAsFactors = FALSE,
  quote = "",
  fill = TRUE
)

# ORF name from synonyms column
extract_orf <- function(x) {
  if (is.na(x) || x == "") return(NA)
  strsplit(x, "\\|")[[1]][1]
}

gaf$ORF <- vapply(gaf$V11, extract_orf, character(1))

colnames(gaf)[5] <- "GO_ID"

# Merge
gaf2 <- merge(
  gaf[, c("ORF", "GO_ID")],
  go_map,
  by = "GO_ID",
  all.x = TRUE
)

stress_rows <- grep("stress", gaf2$GO_name, ignore.case = TRUE)
stress_genes <- unique(gaf2$ORF[stress_rows])
sig$stress_flag <- sig$gene_id %in% stress_genes

sig$class <- ifelse(sig$tpe_flag, "TPE",
                    ifelse(sig$stress_flag, "Stress", "Other"))

table(sig$class)

count_ud <- function(df, cls) {
  d <- df[df$class == cls, ]
  up   <- sum(d$log2FoldChange > 0)
  down <- sum(d$log2FoldChange < 0)
  data.frame(class = cls, up = up, down = down)
}

df_counts <- rbind(
  count_ud(sig, "TPE"),
  count_ud(sig, "Stress"),
  count_ud(sig, "Other")
)

df_counts

# build matrix for barplot
mat <- t(as.matrix(df_counts[, c("up", "down")]))
colnames(mat) <- df_counts$class
rownames(mat) <- c("Upregulated", "Downregulated")

# optional: save to file
png("/scratch/users/k25119154/cc/single-chromosome-yeast-repro/outputs/rnaseq/fig4b_reproduced.png",
    width = 800, height = 600)

barplot(
  mat,
  beside = FALSE,               # stacked
  col = c("red", "green"),
  ylab = "Number of genes",
  main = "Classification of DE genes (SY14 vs BY4742)",
  legend.text = TRUE,
  args.legend = list(x = "topright", bty = "n")
)

dev.off()

