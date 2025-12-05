#!/bin/bash
#SBATCH --job-name=RNAseq_RSEM_ALL
#SBATCH --output=logs/rna_seq_rsem_%j.out
#SBATCH --error=logs/rna_seq_rsem_%j.err
#SBATCH --time=04:00:00        
#SBATCH --mem=16G               # 16 GB RAM
#SBATCH --cpus-per-task=6       # 6 threads

# Load modules or activate environment if needed (uncomment and edit if needed)
# module load bowtie2/2.2.2
# module load rsem/1.3.0
# source activate your_conda_env

# Set paths to tools
BOWTIE2_PATH=/cephfs/volumes/hpc_data_grp/msc_appbio/70e465a3-ea70-4bd6-b919-9da7af124271/Group20_ABCC/tools/bowtie2-2.2.2
RSEM_PATH=/cephfs/volumes/hpc_data_grp/msc_appbio/70e465a3-ea70-4bd6-b919-9da7af124271/Group20_ABCC/tools/RSEM-1.3.0

# Reference
REF=outputs/rnaseq/ref/yeast_R64

# Sample commands

## WT samples
$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00025297_WT-1_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00025294_WT-1_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/WT_1

$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00025301_WT-2_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00025292_WT-2_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/WT_2

$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00025298_WT-3_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00025299_WT-3_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/WT_3

## SY14 samples
$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00023582_SY14-1_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00023578_SY14-1_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/SY14_1

$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00023581_SY14-2_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00023577_SY14-2_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/SY14_2

$RSEM_PATH/rsem-calculate-expression -p 6 \
  --paired-end --bowtie2 --bowtie2-path $BOWTIE2_PATH \
  originals/rnaseq/lib/OED00023579_SY14-3_HCLJ5CCXY_L1_1.clean.fq.gz \
  originals/rnaseq/lib/OED00023580_SY14-3_HCLJ5CCXY_L1_2.clean.fq.gz \
  $REF outputs/rnaseq/quant/SY14_3

echo "RNA-seq pipeline completed at $(date)"
