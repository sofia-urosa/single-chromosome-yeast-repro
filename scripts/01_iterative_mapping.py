# Script for Hi-C data iterative mapping
# Should be running in the Conda environment hic_env_02

import os
import logging
from hiclib import mapping
from mirnylib import h5dict, genome

logging.basicConfig(level=logging.DEBUG)

# paths
FASTQ1 = '/scratch/grp/msc_appbio/Group20_ABCC/originals/hic/SY14_HiC_Rep1_1.fastq.gz'
FASTQ2 = '/scratch/grp/msc_appbio/Group20_ABCC/originals/hic/SY14_HiC_Rep1_2.fastq.gz'
BOWTIE = '/software/spackages_v0_21_prod/apps/linux-ubuntu22.04-zen2/gcc-13.2.0/bowtie2-2.5.1-ac3cxzvaqiga23xqqiain2bycgjnfkyr/bin/bowtie2'
BT_INDEX = '/scratch/grp/msc_appbio/Group20_ABCC/Hi-C_project/HiC-Pro/hiclib-legacy/hiclib-legacy/SY14/SY14'
GENOME_DIR = '/scratch/grp/msc_appbio/Group20_ABCC/Hi-C_project/HiC-Pro/hiclib-legacy/hiclib-legacy/SY14_genome'

TMPDIR = 'tmp'
if not os.path.exists(TMPDIR):
    os.mkdir(TMPDIR)

# A. Mapping read 1
mapping.iterative_mapping(
    bowtie_path=BOWTIE,
    bowtie_index_path=BT_INDEX,
    fastq_path=FASTQ1,
    out_sam_path='SY14_1.bam',
    min_seq_len=25,
    len_step=5,
    seq_start=0,
    seq_end=100,
    nthreads=4,
    temp_dir=TMPDIR,
    bowtie_flags='--very-sensitive'
)

# B. Mapping read 2
mapping.iterative_mapping(
    bowtie_path=BOWTIE,
    bowtie_index_path=BT_INDEX,
    fastq_path=FASTQ2,
    out_sam_path='SY14_2.bam',
    min_seq_len=25,
    len_step=5,
    seq_start=0,
    seq_end=100,
    nthreads=4,
    temp_dir=TMPDIR,
    bowtie_flags='--very-sensitive'
)

# C. Parse mapped reads and assign restriction fragments
mapped_reads = h5dict.h5dict('mapped_reads.hdf5', mode='w')
genome_db = genome.Genome(GENOME_DIR, readChrms=['#', 'X'])

mapping.parse_sam(
    sam_basename1='SY14_1.bam',
    sam_basename2='SY14_2.bam',
    out_dict=mapped_reads,
    genome_db=genome_db,
    enzyme_name='MboI'
)
