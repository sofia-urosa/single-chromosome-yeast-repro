#!/bin/bash
#SBATCH --job-name=illumina_vcf
#SBATCH --output=outputs/logs/illumina_%j.out
#SBATCH --error=outputs/logs/illumina_%j.err
#SBATCH --partition=cpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G

set -euo pipefail

if [ ! -f ".project_root" ]; then
    echo "ERROR: must run from project root"
    exit 1
fi

PRJ_DIR=$(pwd)

source /software/spackages_v0_21_prod/apps/linux-ubuntu22.04-zen2/gcc-13.2.0/anaconda3-2022.10-5wy43yh5crcsmws4afls5thwoskzarhe/etc/profile.d/conda.sh
conda activate seqtools

module load bcftools/1.12-gcc-13.2.0-python-3.11.6

REF="${PRJ_DIR}/originals/ref/S288C.fa"
FASTQ_DIR="${PRJ_DIR}/originals/wgs/fastqc"
OUT="${PRJ_DIR}/outputs/illumina_align"

mkdir -p "$OUT"
mkdir -p "$OUT/isec"

if [ ! -f "${REF}.bwt" ]; then
    bwa index "$REF"
    samtools faidx "$REF"
fi

align_variant_call(){
	SAMPLE=$1
	R1=$2
	R2=$3

	echo "Processing $SAMPLE"
	bwa mem -t 16 "$REF" "$R1" "$R2" | samtools sort -@16 -o "$OUT/${SAMPLE}.bam"
	samtools index "$OUT/${SAMPLE}.bam"

	bcftools mpileup -Ou -f "$REF" "$OUT/${SAMPLE}.bam" | bcftools call -mv -Oz -o "$OUT/${SAMPLE}.vcf.gz"
	bcftools index "$OUT/${SAMPLE}.vcf.gz"
}

align_variant_call WT "$FASTQ_DIR/OED00007363_WT_NGS_R1.fastq.gz" "$FASTQ_DIR/OED00007352_WT_NGS_R2.fastq.gz"
align_variant_call SY14 "$FASTQ_DIR/OED00007361_SY14_NGS_R1.fastq.gz" "$FASTQ_DIR/OED00007345_SY14_NGS_R2.fastq.gz"

bcftools isec -p "$OUT/isec" "$OUT/SY14.vcf.gz" "$OUT/WT.vcf.gz"
#0000 = variants in SY14
#0001 = variants in WT
#002 = variants in both
SY14_var="$OUT/isec/0000.vcf"

echo "SY14 SNPs:"
bcftools view -v snps "$SY14_var" | grep -vc '^#'

echo "SY14 INDELS:"
bcftools view -v indels "$SY14_var" | grep -vc '^#'
echo "Done"
