#!/usr/bin/env bash

#SBATCH --job-name=HiC_bwa
#SBATCH --output=logs/hic_bwa_%j.out
#SBATCH --error=logs/hic_bwa_%j.err
#SBATCH --partition=cpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

set -euxo pipefail

echo "sourcing conda"
source /software/spackages_v0_21_prod/apps/linux-ubuntu22.04-zen2/gcc-13.2.0/anaconda3-2022.10-5wy43yh5crcsmws4afls5thwoskzarhe/etc/profile.d/conda.sh
conda activate seqtools
echo "sourced"

REF="originals/ref/S288C.fa"
FASTQ_DIR="originals/hic"
OUT_DIR="outputs/hic/align"

mkdir -p "$OUT_DIR"

if [ ! -f "${REF}.bwt" ]; then
    echo "Indexing reference"
    bwa index "$REF"
fi

echo "Flag1"
for sample in BY4742 SY14; do
    for lib in R1 R2; do

        r1="${FASTQ_DIR}/${sample}_${lib}_1.fastq.gz"
        r2="${FASTQ_DIR}/${sample}_${lib}_2.fastq.gz"
        out_bam="${OUT_DIR}/${sample}_${lib}.bam"

    if [[ ! -f "$r1" || ! -f "$r2" ]]; then
        echo "Missing FASTQC files for $sample $lib, skipping"
        continue
    fi

    echo "Aligning $sample $lib"
    echo "  R1 = $r1"
    echo "  R2 = $r2"

    bwa mem -t "$SLURM_CPUS_PER_TASK" "$REF" "$r1" "$r2" | samtools view -bS - > | samtools sort -@ "$SLURM_CPUS_PER_TASK" -o "$out_bam" -
    samtools index "$out_bam"
    rm "$outbam"

    echo "$sample $lib done"
    done
done

