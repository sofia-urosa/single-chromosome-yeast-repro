#!/usr/bin/env bash

# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
        echo "Error. Setup script must be ran from project root directory"
        echo "Missing .project_root marker file, aborting"
        exit 1
fi

#log
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

TS=$(date +"%Y-%m-%d_%H-%M-%S")

LOG_FILE="${LOG_DIR}/rnaseq_pipeline_${TS}.log"
exec > >(tee -a "$LOG_FILE") 2>&1


# RNA Seq

REF_DIR="originals/ref"
BOWTIE_DIR="tools/bowtie2-2.2.2"
RSEM_DIR="tools/RSEM-1.3.0"

OUT_DIR="outputs/rnaseq"
BOWTIE_OUT="${OUT_DIR}/index"
RSEM_OUT="${OUT_DIR}/rsem"

mkdir -p "$BOWTIE_OUT" "$RSEM_OUT"

FASTA="${REF_DIR}/S288C.fa"
GTF="${REF_DIR}/S288C.gtf"

BOWTIE_PREFIX="${BOWTIE_OUT}/S288C"
RSEM_PREFIX="${RSEM_OUT}/S288C_rsem"

#Build index if missing with Bowtie
if ls "${BOWTIE_PREFIX}".*.bt2 >/dev/null 2>&1; then
    echo "Bowtie2 index already exists at $BOWTIE_OUT"
else
    echo "Building Bowtie2 v2.2.2 index"
    "${BOWTIE_DIR}/bowtie2-build" "$FASTA" "$BOWTIE_PREFIX"
fi

#rsem

if [ -f "${RSEM_PREFIX}.grp" ]; then
    echo "RSEM reference already exists at $RSEM_OUT"
else
    echo "Building RSEM v1.3.0 reference"

    "${RSEM_DIR}/rsem-prepare-reference" \
        --bowtie2 \
        --bowtie2-path "$BOWTIE_DIR" \
        --gtf "$GTF" \
        "$FASTA" \
        "$RSEM_PREFIX"
fi
