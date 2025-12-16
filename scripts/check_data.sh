cd "$REF_DIR"

#get the data needed to run this project.
#IMPORTANT!! you need a Biosinio account for this.

check_filelist(){
    local DIR="$1"
    shift
    local FILES=("$@")

    local MISSING_FILES=()

    for f in "${FILES[@]}"; do
        if [ ! -f "${DIR}/${f}" ]; then
        MISSING_FILES+=("$f")
        fi
    done

    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        echo "All files are already present"
        exit 0
    fi

    echo "Missing files in "${DIR}":"
    for f in "${MISSING_FILES[@]}"; do
        echo "  - $f"
    done

    return 1
}

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

#check if files exist before downloading them
#expected files

RNA_FILES=(
    "OED00023578_SY14-1_HCLJ5CCXY_L1_2.clean.fq.gz"
    "OED00023582_SY14-1_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00023581_SY14-2_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00023577_SY14-2_HCLJ5CCXY_L1_2.clean.fq.gz"
    "OED00023579_SY14-3_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00023580_SY14-3_HCLJ5CCXY_L1_2.clean.fq.gz"
    "OED00025297_WT-1_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00025294_WT-1_HCLJ5CCXY_L1_2.clean.fq.gz"
    "OED00025301_WT-2_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00025292_WT-2_HCLJ5CCXY_L1_2.clean.fq.gz"
    "OED00025298_WT-3_HCLJ5CCXY_L1_1.clean.fq.gz"
    "OED00025299_WT-3_HCLJ5CCXY_L1_2.clean.fq.gz"
)

SHORTSEQ_DIR="originals/wgs/illumina_seq"

SHORTSEQ_FILES=(
    "OED00007344_WT_Rep1_1.fastq.gz"
    "OED00007345_SY14_NGS_R2.fastq.gz"
    "OED00007347_WT_Rep2_1.fastq.gz"
    "OED00007348_WT_Rep1_2.fastq.gz"
    "OED00007349_WT_Rep2_2.fastq.gz"
    "OED00007352_WT_NGS_R2.fastq.gz"
    "OED00007361_SY14_NGS_R1.fastq.gz"
    "OED00007363_WT_NGS_R1.fastq.gz"
)

LONGSEQ_DIR="originals/pacbio"

LONGSEQ_FILES=(
    "BY4742_WT_1.fastq.gz"
    "BY4742_WT_2.fastq.gz"
    "SY14_pacbio.fastq.gz"
)

mkdir -p "$RNASEQ_DIR" "$SHORTSEQ_DIR" "$LONGSEQ_DIR"

check_filelist "$RNASEQ_DIR" "${RNA_FILES[@]}"
check_filelist "$SHORTSEQ_DIR" "${SHORTSEQ_FILES[@]}"
check_filelist "$LONGSEQ_DIR" "${LONGSEQ_FILES[@]}"

echo "Please download the missing files from biosinio."
