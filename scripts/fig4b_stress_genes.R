# fig 4b classifies  differentially expressed genes in SY14 compared to BY4742 into:
#   TPE (Telomere Position Effect) -> genes very close to telomeres
#   Stress-response genes -> genes involved in cellular stress pathways
#   Other

# this code does it by:
#   1. Which genes are differentially expressed?
#   2. Where are they? 
#   3. Are they related to a stress pathway?

# when fusing all of chromosomes together, one of the mechanisms affected
# is related to TPE (Telomere proximity effect) - we want to know how many
# of the sig. expressed genes got up or down regulated

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

# fai -> chromosome size (lenght)
fai <- read.table(
  file.path("originals/ref/S288C.fa.fai"),
  header = FALSE,
  stringsAsFactors = FALSE
)

colnames(fai) <- c("chr", "length", "offset", "linelen", "linebytes")
chr_len <- setNames(fai$length, fai$chr)


gene_table$chr_len <- chr_len[gene_table$chr]

# calculate 'base' position of gene
gene_table$mid <- (gene_table$start + gene_table$end)/2

# distance to 'nearest' telomere
gene_table$dist_to_telo <- pmin(gene_table$mid -1, gene_table$chr_len - gene_table$mid)

summary(gene_table$dist_to_telo)

# merge by gene id so we have chr, start, end, distance to telomere
res_annot <- merge(res, gene_table[, c("gene_id", "chr", "start", "end", "dist_to_telo")], by = "gene_id", all.x = TRUE)

#filter by significant genes according to paper
sig <- subset(res_annot,
              abs(log2FoldChange) >= 1 & padj < 0.001)

head(res_annot)

# define cutoff - how many bases is 'close' to a telomere? 
cutoff <- 10000

sig$tpe_flag <- !is.na(sig$dist_to_telo) & sig$dist_to_telo <= cutoff

table(sig$tpe_flag)
  
### authors do not define how they got the stress genes
# so we use the GO ontology
# we need: go_id, orf
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
  # find lines that have id: GO: and name:
  id_line <- block[grep("^id: GO:", block)]
  name_line <- block[grep("^name:", block)]
  
  # Skip malformed terms
  if (length(id_line) != 1 || length(name_line) != 1) next
  
  #remove id and name pfefixes
  go_id <- sub("^id: ", "", id_line)
  go_name <- sub("^name: ", "", name_line)
  
  #build a go mapping table
  GO_IDs   <- c(GO_IDs, go_id)
  GO_names <- c(GO_names, go_name)
}

go_map <- data.frame(
  GO_ID = GO_IDs,
  GO_name = GO_names,
  stringsAsFactors = FALSE
)

# we use the gaf file to connect to the go file using go_id. 
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
# "YGR149W|glycerophosphocholine acyltransferase" -> split by |
extract_orf <- function(x) {
  if (is.na(x) || x == "") return(NA)
  strsplit(x, "\\|")[[1]][1]
}

# we'll attempt to find all genes related to stress
gaf$ORF <- vapply(gaf$V11, extract_orf, character(1))

colnames(gaf)[5] <- "GO_ID"

# Merge
# orf -> go_id -> go_name
gaf2 <- merge(
  gaf[, c("ORF", "GO_ID")],
  go_map,
  by = "GO_ID",
  all.x = TRUE
)

# define "stress-related gene" as any ORF whose GO_name contains "stress"
# (best attempt- paper authors didnt specify how they did it)
stress_rows <- grep("stress", gaf2$GO_name, ignore.case = TRUE)
stress_genes <- unique(gaf2$ORF[stress_rows])

# stress_flag = true
sig$stress_flag <- sig$gene_id %in% stress_genes

# assign class (TPE, stress or other)
sig$class <- ifelse(sig$tpe_flag, "TPE",
                    ifelse(sig$stress_flag, "Stress", "Other"))

table(sig$class)

# regulation
#   - up   = log2FoldChange > 0
#   - down = log2FoldChange < 0
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

# build matrix for barplot (col = class, row=up down)
mat <- t(as.matrix(df_counts[, c("up", "down")]))
colnames(mat) <- df_counts$class
rownames(mat) <- c("Upregulated", "Downregulated")

cols <- c("red3", "green4")

# save to file
png("outputs/rnaseq/fig4b_reproduced.png",
    width = 800, height = 600)

barplot(
  mat,
  beside = FALSE,               # stacked
  col = cols,
  ylab = "Number of genes",
  main = "Classification of DE genes (SY14 vs BY4742)",
  ylim = c(0, max(colSums(mat)) * 1.25)
  
)

legend(
  "bottom",
  inset = -0.15,
  horiz = TRUE,
  legend = c("Upregulated", "Downregulated"),
  fill = cols,
  bty = "n",
  cex = 1.2,
  xpd = TRUE
)
dev.off()

