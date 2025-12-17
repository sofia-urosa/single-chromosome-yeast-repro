library(pheatmap)

mat <- read.csv("outputs/rnaseq/expression_analysis/hm.csv", header = TRUE, check.names = FALSE)

rownames(mat) <- mat$gene_id
mat$gene_id <- NULL

mat <- as.matrix(mat)

colSums(is.na(mat))
sum(is.infinite(mat))

png("outputs/rnaseq/fig/heatmap_transcriptome.png",width = 2400, height = 2000, res = 300)

pheatmap(
  mat,
  scale = "none",
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean",
  color = colorRampPalette(c("blue", "green", "yellow", "red"))(100),
  show_rownames = FALSE,
  main = "Heatmap of transcriptome profiles"
)

dev.off()


# pearson correlation

cor_mat <- cor(mat, method = "pearson")

#save
png("outputs/rnaseq/fig/pearson_correlation.png",
    width = 2400, height = 2000, res = 300)

pheatmap(
  cor_mat,
  clustering_method = "complete",
  color = colorRampPalette(c("navy", "white", "firebrick"))(100),
  display_numbers = TRUE,        # shows the 0.97, 0.98 values
  number_format = "%.3f",        # round to 2 decimal places
  main = "Pearson correlation",
  number_color = "white"
)

dev.off()