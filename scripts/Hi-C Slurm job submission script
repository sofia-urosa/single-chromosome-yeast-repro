#!/bin/bash

# Reset environment
module purge

# Load required system tools
module load bowtie2/2.5.1-gcc-13.2.0-python-3.11.6
module unload python
module load samtools
module unload python

echo "successfully loaded tools"

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate /scratch/grp/msc_appbio/Group20_ABCC/envs/hiclib_env_02

echo "successfully activate environment"

# Set PYTHONPATH for hiclib + mirnylib
cd /scratch/grp/msc_appbio/Group20_ABCC/Hi-C_project/HiC-Pro/hiclib-legacy/hiclib-legacy
export PYTHONPATH=$(pwd)/src:$(pwd)/mirnylib-legacy:$PYTHONPATH

echo "targeted python version used"

Do this one quick check inside the Slurm script, before running your script:
which python
python - <<EOF
import sys
print(sys.path)
EOF

# Run mapping
python scripts/01_iterative_mapping.py

echo "done"
