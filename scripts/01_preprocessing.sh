#!/bin/bash
# ==============================================================================
# Script Name: 01_preprocessing.sh
#
# Description:
#   This script performs the initial preprocessing steps for bulk RNA-seq data.
#   It executes two main tasks:
#   1. Quality Control (QC): Runs FastQC on raw FASTQ files to assess read quality.
#   2. Trimming: Uses Cutadapt to remove adapter sequences and filter out 
#      low-quality reads and short sequences.
#
# Inputs:
#   - Raw paired-end FASTQ files (e.g., *_R1.fastq, *_R2.fastq) located in 
#     the directory specified by RAW_DATA_DIR.
#
# Outputs:
#   - FastQC HTML reports and zip files in QC_OUT_DIR.
#   - Trimmed FASTQ files in TRIM_OUT_DIR.
#   - Individual Cutadapt log files for each sample in TRIM_OUT_DIR.
#
# Usage:
#   1. Modify the parameters in the "USER CONFIGURATION" section below.
#   2. Run the script: bash scripts/01_preprocessing.sh
# ==============================================================================

set -e

# --- USER CONFIGURATION START: Modify these parameters for your specific data ---
THREADS=8                                            
ADAPTER_R1="AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"       
ADAPTER_R2="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA"      
MIN_LEN=20                                           
QUALITY=20                                           

RAW_DATA_DIR="./data"                                
QC_OUT_DIR="./qc_reports"                            
TRIM_OUT_DIR="./results/trimmed"                     
# --- USER CONFIGURATION END ---

mkdir -p "$QC_OUT_DIR" "$TRIM_OUT_DIR"

if [ -z "$(ls -A ${RAW_DATA_DIR}/*.fastq 2>/dev/null)" ]; then
    echo "Error: No .fastq files found in ${RAW_DATA_DIR}"
    exit 1
fi

fastqc -t "$THREADS" -o "$QC_OUT_DIR" "$RAW_DATA_DIR"/*.fastq

cd "$RAW_DATA_DIR" || exit

for r1 in *_R1.fastq; do
    sample=$(basename "$r1" _R1.fastq)
    r2="${sample}_R2.fastq"
    
    if [ ! -f "$r2" ]; then
        echo "Warning: R2 file for $sample ($r2) not found, skipping..."
        continue
    fi
    
    cutadapt \
        -a "$ADAPTER_R1" \
        -A "$ADAPTER_R2" \
        -o "../${TRIM_OUT_DIR}/${sample}_trimmed_R1.fastq" \
        -p "../${TRIM_OUT_DIR}/${sample}_trimmed_R2.fastq" \
        -m "$MIN_LEN" \
        -q "$QUALITY" \
        -j "$THREADS" \
        "$r1" "$r2" > "../${TRIM_OUT_DIR}/${sample}_cutadapt_log.txt"
        
done

cd - > /dev/null
