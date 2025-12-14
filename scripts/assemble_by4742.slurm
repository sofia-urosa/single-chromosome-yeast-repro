#!/bin/bash
#SBATCH --job-name=asm_BY4742
#SBATCH --output=outputs/logs/asm_BY4742_%j.out
#SBATCH --error=outputs/logs/asm_BY4742_%j.err
#SBATCH --partition=cpu
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

set -euo pipefail

# setting up folders and tools for reproducibility
# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
        echo "Error. Setup script must be ran from project root directory"
        echo "Missing .project_root marker file, aborting"
        exit 1
fi

module load openjdk/1.8.0_265-b01-gcc-13.2.0 	# canu NEEDS java.

PRJ_DIR="/scratch/users/k25119154/cc/single-chromosome-yeast-repro"
CANU="${PRJ_DIR}/tools/canu-1.5/Linux-amd64/bin/canu"

READS="${PRJ_DIR}/originals/pacbio/BY4742_WT_*.fastq.gz" # * because we have 2!
OUT_DIR="${PRJ_DIR}/outputs/wgs/assemblies/BY4742"

mkdir -p "$OUT_DIR"

echo "[$(date)] Starting BY4742 assembly"
echo "Reads: $READS"
echo "Output dir: $OUT_DIR"

echo "Looking for reads:"
ls -lh ${READS} || { echo "ERROR: READS NOT FOUND"; exit 1; }

$CANU \
  -p BY4742 \
  -d "$OUT_DIR" \
  genomeSize=12m \ 		# expected genome size (estimate coverage)
  useGrid=false \
  gnuplotTested=true \		# we had problems with this and libraries so we set as true to skip checks
  -pacbio-raw $READS		# raw (uncorrected) PacBio reads in FASTQ

echo "[$(date)] Finished BY4742 assembly"
