#!/usr/bin/env bash

# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
        echo "Error. Setup script must be ran from project root directory"
        echo "Missing .project_root marker file, aborting"
        exit 1
fi


REF_DIR="originals/ref"
mkdir -p "$REF_DIR"
cd "$REF_DIR"

#get the data needed to run this project.
#IMPORTANT!! you need a Biosinio account for this.


#Reference genome:

#raw names
FA_GZ="GCF_000146045.2_R64_genomic.fna.gz"
GTF_GZ="GCF_000146045.2_R64_genomic.gtf.gz"

FA_NCBI="GCF_000146045.2_R64_genomic.fna"
GTF_NCBI="GCF_000146045.2_R64_genomic.gtf"

#my names
FA="S288C.fa"
GTF="S288C.gtf"


FA_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz"
GTF_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.gtf.gz"

#fasta

if [ -f "$FA" ]; then
    :
elif [ -f "$FA_NCBI" ]; then
    echo "FASTA found as NCBI name, renaming"
    mv "$FA_NCBI" "$FA"
else
    echo "FASTA missing, downloading"
    wget -q "$FA_URL"
    gunzip -f "$FA_GZ"
    mv "$FA_NCBI" "$FA"
fi

#gtf

if [ -f "$GTF" ]; then
    :
elif [ -f "$GTF_NCBI" ]; then
    echo "GTF found as NCBI name, renaming"
    mv "$GTF_NCBI" "$GTF"
else
    echo "GTF missing, downloading"
    wget -q "$GTF_URL"
    gunzip -f "$GTF_GZ"
    mv "$GTF_NCBI" "$GTF"
fi


cd - >/dev/null
echo "Reference genome check complete"

#rnaseq files

RNASEQ_DIR="originals/rnaseq"
mkdir -p "$RNASEQ_DIR"


echo
echo "RNA-seq data download (Biosino)"
echo "Enter your Biosino User:"
read -r BIOSINO_EMAIL

if [ -z "$BIOSINO_EMAIL" ]; then
    echo "No email entered. Aborting..."
    exit 1
fi

#source directories
SY14_DIR="/Public/byRun/OER00/OER0002/OER000220/OER00022078"
WT_DIR="/Public/byRun/OER00/OER0000/OER000001/OER00000135"

sftp -P 44398 "${BIOSINO_EMAIL}@fms.biosino.org" <<EOF
ls -l $SY14_DIR
ls -l $WT_DIR
EOF

echo
echo "Do you want to download these files into $RNASEQ_DIR ? (y/n)"
read -r ANS

if [ "$ANS" != "y" ]; then
    echo "Skipping download."
    exit 0
fi

#expected files

FILES=(
    "SY14-1_HCLJ5CCXY_L1_1.clean.fq.gz"
    "SY14-1_HCLJ5CCXY_L1_2.clean.fq.gz"
    "SY14-2_HCLJ5CCXY_L1_1.clean.fq.gz"
    "SY14-2_HCLJ5CCXY_L1_2.clean.fq.gz"
    "SY14-3_HCLJ5CCXY_L1_1.clean.fq.gz"
    "SY14-3_HCLJ5CCXY_L1_2.clean.fq.gz"
    "WT-1_HCLJ5CCXY_L1_1.clean.fq.gz"
    "WT-1_HCLJ5CCXY_L1_2.clean.fq.gz"
    "WT-2_HCLJ5CCXY_L1_1.clean.fq.gz"
    "WT-2_HCLJ5CCXY_L1_2.clean.fq.gz"
    "WT-3_HCLJ5CCXY_L1_1.clean.fq.gz"
    "WT-3_HCLJ5CCXY_L1_2.clean.fq.gz"
)

MISSING_FILES=()

for f in "${FILES[@]}"; do
    if [ ! -f "${RNASEQ_DIR}/${f}" ]; then
        MISSING_FILES+=("$f")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "All RNA-seq FASTQ files are already present. No download needed."
    exit 0
fi

echo "Missing files:"
for f in "${MISSING_FILES[@]}"; do
    echo "  $f"
done

echo
echo "Proceed to download missing files? (y/n)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Aborting download."
    exit 0
fi


SFTP_CMDS=$(mktemp)

echo "lcd $RNASEQ_DIR" >> "$SFTP_CMDS"

# SY14 files
echo "cd $SY14_DIR" >> "$SFTP_CMDS"
for f in "${MISSING_FILES[@]}"; do
    if [[ "$f" == SY14-* ]]; then
        echo "mget $f" >> "$SFTP_CMDS"
    fi
done

# WT files
echo "cd $WT_DIR" >> "$SFTP_CMDS"
for f in "${MISSING_FILES[@]}"; do
    if [[ "$f" == WT-* ]]; then
        echo "mget $f" >> "$SFTP_CMDS"
    fi
done

# Execute SFTP once

SFTP_CMDS=$(mktemp)

echo "lcd $RNASEQ_DIR" >> "$SFTP_CMDS"

# SY14 files
echo "cd $SY14_DIR" >> "$SFTP_CMDS"
for f in "${MISSING_FILES[@]}"; do
    if [[ "$f" == SY14-* ]]; then
        echo "mget $f" >> "$SFTP_CMDS"
    fi
done

# WT files
echo "cd $WT_DIR" >> "$SFTP_CMDS"
for f in "${MISSING_FILES[@]}"; do
    if [[ "$f" == WT-* ]]; then
        echo "mget $f" >> "$SFTP_CMDS"
    fi
done

# Execute SFTP once
sftp -P 44398 -b "$SFTP_CMDS" "${BIOSINO_EMAIL}@fms.biosino.org"

rm "$SFTP_CMDS"

echo "Download complete."
