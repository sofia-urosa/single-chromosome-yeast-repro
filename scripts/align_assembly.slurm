#!/bin/bash
#SBATCH --job-name=align
#SBATCH --output=outputs/logs/align_%j.out
#SBATCH --error=outputs/logs/align_%j.err
#SBATCH --partition=cpu
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G

set -euo pipefail

# setting up folders and tools for reproducibility
# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
        echo "Error. Setup script must be ran from project root directory"
        echo "Missing .project_root marker file, aborting"
        exit 1
fi

# activate env with LAST
source /software/spackages_v0_21_prod/apps/linux-ubuntu22.04-zen2/gcc-13.2.0/anaconda3-2022.10-5wy43yh5crcsmws4afls5thwoskzarhe/etc/profile.d/conda.sh
conda activate genome_align

PRJ_DIR="$(pwd)" # this should be run inside the project root.

REF="${PRJ_DIR}/originals/ref/S288C.fa"
OUT="${PRJ_DIR}/outputs/wgs"

BY="${PRJ_DIR}/outputs/wgs/assemblies/BY4742/BY4742.contigs.fasta"
SY="${PRJ_DIR}/outputs/wgs/assemblies/SY14/SY14.contigs.fasta"

echo "Indexing S288C"
lastdb -P16 "${OUT}/S288C_db" "$REF"

echo "Aligning BY4742 to S288C"
# align:
lastal -P16 "${OUT}/S288C_db" "$BY" > "${OUT}/BY4742_S288C.maf"
# remove redundant alignments, choose best unique placement -> alignment map
last-split "${OUT}/BY4742_S288C.maf" > "${OUT}/BY4742_S288C.split.maf"
# produce a simplified table for circos
maf-convert tab "${OUT}/BY4742_S288C.split.maf" > "${OUT}/BY4742_S288C.tab"

echo "Aligning SY14 to S288C"
# align:
lastal -P16 "${OUT}/S288C_db" "$SY" > "${OUT}/SY14_S288C.maf"
# remove redundant alignments, choose best unique placement -> alignment map
last-split "${OUT}/SY14_S288C.maf" > "${OUT}/SY14_S288C.split.maf"
# produce a simplified table for circos
maf-convert tab "${OUT}/SY14_S288C.split.maf" > "${OUT}/SY14_S288C.tab"

# circos needs:
# ref_chr   ref_start   ref_end   query_chr   query_start   query_end
# chrI      10000       20000     BY_contig1  50000         60000

# LAST columns (relevant):
#   $2 = reference chromosome
#   $3 = reference start
#   $4 = aligned length on reference
#   $7 = query contig
#   $8 = query start
#   $9 = aligned length on query

awk '
    # Skip LAST header and comment lines
    /^#/ { next }

    {
        # Reference side
        ref_chr   = $2
        ref_start = $3
        ref_end   = $3 + $4     # LAST reports alignment length, not end coord

        # Query side (BY4742 or SY14 contigs)
        qry_chr   = $7
        qry_start = $8
        qry_end   = $8 + $9     # same logic: compute end coordinate

        # Circos wants: ref_chr  ref_start  ref_end   qry_chr  qry_start  qry_end
        print ref_chr, ref_start, ref_end, qry_chr, qry_start, qry_end
    }
' OFS="\t" outputs/wgs/SY14_S288C.tab \
> outputs/wgs/SY14_S288C.links.txt


awk '
    !/^#/ {
        ref=$2;
        ref_start=$3;
        ref_end=$3 + $4;

        qry=$7;
        qry_start=$8;
        qry_end=$8 + $9;

        print ref, ref_start, ref_end, qry, qry_start, qry_end
    }
' OFS="\t" outputs/wgs/BY4742_S288C.tab \
> outputs/wgs/BY4742_S288C.links.txt
