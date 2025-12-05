#!/usr/bin/env bash

# setting up folders and tools for reproducibility
# ensure this code is ran where the project root is
if [ ! -f ".project_root" ]; then
	echo "Error. Setup script must be ran from project root directory"
	echo "Missing .project_root marker file, aborting"
	exit 1
fi

DIRS=(
    "logs"
    "notebooks"
    "originals"
    "originals/hic"
    "originals/ref"
    "originals/wgs"
    "outputs"
    "outputs/logs"
    "outputs/rnaseq"
    "outputs/rnaseq/fastqc"
    "outputs/wgs"
    "outputs/wgs/fastqc"
    "tools"
)

echo "Checking directory structure"

for d in "${DIRS[@]}"; do
    if [ -d "$d" ]; then
        :
    else
        echo "Missing: $d  (creating)"
        mkdir -p "$d"
    fi
done

if ! command -v conda >/dev/null 2>&1; then
    echo "Error: conda not found in PATH."
    echo "Install Conda or init your shell before running"
    exit 1
fi

echo "Checking conda environments"

ENVS=("genome_align" "seqtools")
YAML_DIR="envs"

#create envs if they are missing with the libs on .yaml


for env in "${ENVS[@]}"; do
    if conda env list | awk '{print $1}' | grep -q "^${env}$"; then
        echo "Environment exists: $env"
    else
        echo "Missing environment: $env"
        YAML_PATH="${YAML_DIR}/${env}.yaml"

        if [ ! -f "$YAML_PATH" ]; then
            echo "Error: YAML file not found for $env at $YAML_PATH"
            exit 1
        fi

        echo "Creating environment $env from $YAML_PATH"
        conda env create -f "$YAML_PATH"
    fi
done

#download and set up external tools
TOOLS_DIR="tools"
echo
echo "Setting up external tools..."

echo -e "\e[1;32mRNA Seq tools:\e[0m"
echo -e "\e[1m  	Bowtie2 2.2.2\e[0m"
echo -e "\e[1m   	RSEM 1.3.0\e[0m"
echo -e "\e[1m   	DESeq2 1.16.1\e[0m"
echo
sleep 5

#make sure PATH exports are only made once
append_once() {
    dir="$1"
    if ! echo "$PATH" | grep -q "$dir" && ! grep -q "$dir" ~/.bashrc 2>/dev/null; then
        echo "export PATH=$(pwd)/${dir}:\$PATH" >> ~/.bashrc
    fi
}

#bowtie

BOWTIE_DIR="${TOOLS_DIR}/bowtie2-2.2.2"
BOWTIE_ZIP="${TOOLS_DIR}/bowtie2-2.2.2-linux-x86_64.zip"
BOWTIE_URL="https://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.2.2/bowtie2-2.2.2-linux-x86_64.zip"

if [ -d "$BOWTIE_DIR" ]; then
    echo "Bowtie2 2.2 already installed"
else
    echo "Installing Bowtie2 2.2"
    wget -O "$BOWTIE_ZIP" "$BOWTIE_URL"
    unzip "$BOWTIE_ZIP" -d "$TOOLS_DIR"
fi

append_once "$BOWTIE_DIR"

#rsem 1.3.0 (built from source)

RSEM_DIR="${TOOLS_DIR}/RSEM-1.3.0"
RSEM_TAR="${TOOLS_DIR}/v1.3.0.tar.gz"
RSEM_URL="https://github.com/deweylab/RSEM/archive/refs/tags/v1.3.0.tar.gz"

if [ -d "$RSEM_DIR" ]; then
    echo "RSEM already installed"
else
    echo "Installing RSEM 1.3.0"
    wget -O "$RSEM_TAR" "$RSEM_URL"
    tar -xzf "$RSEM_TAR" -C "$TOOLS_DIR"
    cd "$RSEM_DIR"
    make
    cd - >/dev/null
fi

append_once "$RSEM_DIR"

#deseq (singularity container)

#check if singularity is available. if not abort
if ! command -v singularity >/dev/null 2>&1; then
    echo "Error: singularity not found. Cannot install DESeq2 container. Maybe check if you're working on a computing node?"
else
    SIF_PATH="${TOOLS_DIR}/bioc_3_5.sif"
    DESEQ_IMG="docker://quay.io/biocontainers/bioconductor-deseq2:1.16.1--r3.4.1_0"

    if [ -f "$SIF_PATH" ]; then
        echo "DESeq2 Singularity image exists"
    else
        echo "Downloading DESeq2 Singularity image"
        singularity pull "$SIF_PATH" "$DESEQ_IMG"
    fi
fi

echo "Setup is complete!"
