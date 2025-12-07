#!/bin/bash

#SBATCH --job-name=HiC_bwa
#SBATCH --output=logs/hic_bwa_%j.out
#SBATCH --error=logs/hic_bwa_%j.err
#SBATCH --partition=cpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

conda activate seqtools

REF="originals/ref/S288C.fa"
FASTQ_DIR="originals/hic"
OUT_DIR="outputs/hic/align"

mkdir -p "$OUT_DIR"

if [ ! -f "${REF}.bwt" ]; then
    echo "Indexing reference"
    bwa index "$REF"
fi

for r1 in "$FASTQ_DIR"/*_R1*.fastq.gz; do
    [ -e "$r1" ] || continue

    sample=$(basename "$r1" | sed 's/_R1.*//')
    r2="{FASTQ_DIR}/${sample}_R2.fastq.gz"

    if [ ! -f "$r2" ]; then
        echo "Missing R2 for $sample, skipping"
        continue
    fi

    outbam="${OUT_DIR}/${sample}.hic.bam"
    sorted="${OUT_DIR}/${sample}.hic.sorted.bam"

    echo "processing sample $sample"

    bwa mem -5 -t 8 "$REF" "$r1" "$r2" | samtools view -bS - > "$outbam"

    samtools sort -@ 8 -o "$sorted" "$outbam"
    samtools index "$sorted"
    rm "$outbam"

    echo "$sorted Done"
done