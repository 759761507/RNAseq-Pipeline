#!/bin/bash
# ==============================================================================
# Script Name: 03_quantification.sh
#
# Description:
#   This script performs gene-level quantification using featureCounts from 
#   the subread package. It takes the sorted BAM files generated in the 
#   alignment step and counts how many reads map to each gene based on a 
#   provided GTF annotation file.
#
# Inputs:
#   - Sorted BAM files from the alignment step (*_sorted.bam).
#   - GTF annotation file (MUST match the reference genome used for alignment).
#
# Outputs:
#   - A single raw count matrix (counts.txt) containing counts for all samples.
#   - A summary file (counts.txt.summary) showing mapping statistics.
#
# Usage:
#   1. Modify the parameters in the "USER CONFIGURATION" section below.
#   2. Run the script: bash scripts/03_quantification.sh
# ==============================================================================

set -e

# --- USER CONFIGURATION START: Modify these parameters for your specific data ---
THREADS=8

# Important: The GTF file must match the reference genome used in step 02
GTF_FILE="/path/to/your/annotation.gtf"

# Directories
ALIGN_DATA_DIR="./results/aligned"
QUANT_OUT_DIR="./results/quantification"

# Output file name
OUTPUT_COUNTS="${QUANT_OUT_DIR}/counts.txt"
# --- USER CONFIGURATION END ---

mkdir -p "$QUANT_OUT_DIR"

if [ -z "$(ls -A ${ALIGN_DATA_DIR}/*_sorted.bam 2>/dev/null)" ]; then
    echo "Error: No sorted .bam files found in ${ALIGN_DATA_DIR}"
    exit 1
fi

echo "-> Starting gene quantification with featureCounts..."

# featureCounts can process multiple BAM files at once to generate a single matrix
# We construct a list of all BAM files to pass to the command
BAM_FILES=$(ls ${ALIGN_DATA_DIR}/*_sorted.bam)

# Run featureCounts
# Note: 
# -p specifies paired-end data. Remove it if you have single-end data.
# -B requires both ends to be successfully aligned (for paired-end).
# -C requires the reads to be uniquely mapped.
# -T specifies the number of threads.
# -a specifies the annotation file.
# -o specifies the output file name.

featureCounts \
    -T "$THREADS" \
    -p \
    -B \
    -C \
    -a "$GTF_FILE" \
    -o "$OUTPUT_COUNTS" \
    $BAM_FILES

echo "-> Quantification complete."
echo "   Count matrix saved to: $OUTPUT_COUNTS"
echo "   Summary stats saved to: ${OUTPUT_COUNTS}.summary"
echo "---------------------------------------------------"
echo "=== Quantification Completed! ==="
