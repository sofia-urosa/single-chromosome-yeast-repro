#!/bin/bash

set -euo pipefail

# setting up folders and tools for reproducibility
# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
        echo "Error. Setup script must be ran from project root directory"
        echo "Missing .project_root marker file, aborting"
        exit 1
fi

source /software/spackages_v0_21_prod/apps/linux-ubuntu22.04-zen2/gcc-13.2.0/anaconda3-2022.10-5wy43yh5crcsmws4afls5thwoskzarhe/etc/profile.d/conda.sh
conda activate seqtools

PRJ_DIR="$(pwd)"
OUT="${PRJ_DIR}/outputs/wgs/SY14_BY4742"
mkdir -p "${OUT}"

BY="${PRJ_DIR}/outputs/wgs/assemblies/BY4742/BY4742.contigs.fasta"
SY="${PRJ_DIR}/outputs/wgs/assemblies/SY14/SY14.contigs.fasta"

echo "Extracting SY14 main contig (BIG one)"
samtools faidx "$SY"
samtools faidx "$SY" tig00000001 > "${OUT}/SY14.big.fasta"

conda deactivate
conda activate genome_align

echo "Building LAST database for BY4742"
lastdb -P8 "${OUT}/BY_db" "$BY"

echo "LAST alignment SY14 -> BY4742"
lastal -P8 "${OUT}/BY_db" "${OUT}/SY14.big.fasta" > "${OUT}/SY14_BY4742.maf"

last-split "${OUT}/SY14_BY4742.maf" > "${OUT}/SY14_BY4742.split.maf"

#output for circos
maf-convert tab "${OUT}/SY14_BY4742.split.maf" > "${OUT}/SY14_BY4742.links.tab"

echo "Done. results can be found in ${OUT}"
