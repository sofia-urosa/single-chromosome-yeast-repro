#!/bin/bash
#SBATCH --job-name=asm_SY14
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

module load openjdk/1.8.0_265-b01-gcc-13.2.0    # canu NEEDS java.

PRJ_DIR="$(pwd)" # this should be run inside the project root.
CANU="${PRJ_DIR}/tools/canu-1.5/Linux-amd64/bin/canu"

READS="${PRJ_DIR}/originals/pacbio/SY14_pacbio.fastq.gz"
OUT_DIR="${PRJ_DIR}/outputs/wgs/assemblies/SY14"

mkdir -p "$OUT_DIR"

echo "[$(date)] Starting SY14 assembly"
echo "Reads: $READS"
echo "Output dir: $OUT_DIR"

echo "Looking for reads:"
ls -lh ${READS} || { echo "ERROR: READS NOT FOUND"; exit 1; }

# same inputs as BY4742
$CANU \
  -p SY14 \
  -d "$OUT_DIR" \
  genomeSize=12m \
  useGrid=false \
  gnuplotTested=true \
  -pacbio-raw $READS

echo "[$(date)] Finished BY4742 assembly"
