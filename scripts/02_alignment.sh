#!/bin/bash
# ==============================================================================
# Script Name: 02_alignment.sh
#
# Description:
#   This script aligns the trimmed RNA-seq reads to a reference genome.
#   It supports two of the most popular aligners: Hisat2 and STAR.
#   It also includes post-alignment processing using Samtools to convert SAM to 
#   sorted BAM files and index them for visualization in tools like IGV.
#
# Inputs:
#   - Trimmed paired-end FASTQ files from the previous step.
#   - Reference genome index files (must be pre-built for the chosen aligner).
#   - GTF annotation file (highly recommended for STAR).
#
# Outputs:
#   - Sorted BAM files and their corresponding index (.bai) files.
#   - Alignment log files.
#
# Usage:
#   1. Build your reference genome index manually before running this script:
#      - Hisat2: hisat2-build genome.fa reference_index_prefix
#      - STAR: STAR --runMode genomeGenerate --genomeDir ./genome_index ...
#   2. Modify the "USER CONFIGURATION" section below.
#   3. Run the script: bash scripts/02_alignment.sh
# ==============================================================================

set -e

# --- USER CONFIGURATION START: Modify these parameters for your specific data ---
THREADS=8

# Select Aligner: "hisat2" or "star"
ALIGNER="hisat2"

# Directories
TRIM_DATA_DIR="./results/trimmed"
ALIGN_OUT_DIR="./results/aligned"

# Hisat2 Specific Parameters
HISAT2_INDEX="/path/to/your/hisat2_index/reference_prefix"

# STAR Specific Parameters
STAR_INDEX_DIR="/path/to/your/star_index_directory"
# --- USER CONFIGURATION END ---

mkdir -p "$ALIGN_OUT_DIR"

if [ -z "$(ls -A ${TRIM_DATA_DIR}/*_trimmed_R1.fastq 2>/dev/null)" ]; then
    echo "Error: No trimmed .fastq files found in ${TRIM_DATA_DIR}"
    exit 1
fi

cd "$TRIM_DATA_DIR" || exit

for r1 in *_trimmed_R1.fastq; do
    sample=$(basename "$r1" _trimmed_R1.fastq)
    r2="${sample}_trimmed_R2.fastq"
    
    if [ ! -f "$r2" ]; then
        echo "Warning: R2 file for $sample ($r2) not found, skipping..."
        continue
    fi
    
    echo "-> Aligning sample: $sample using $ALIGNER ..."
    
    if [ "$ALIGNER" = "hisat2" ]; then
        # ----------------------------------------------------------------------
        # HISAT2 ALIGNMENT
        # ----------------------------------------------------------------------
        hisat2 -p "$THREADS" \
               -x "$HISAT2_INDEX" \
               -1 "$r1" \
               -2 "$r2" \
               -S "../aligned/${sample}_aligned.sam" \
               2> "../aligned/${sample}_hisat2_summary.txt"
               
        echo "   Converting and sorting SAM to BAM..."
        samtools view -@ "$THREADS" -bS "../aligned/${sample}_aligned.sam" | \
        samtools sort -@ "$THREADS" -o "../aligned/${sample}_sorted.bam"
        
        # Remove intermediate SAM file to save space
        rm "../aligned/${sample}_aligned.sam"
        
    elif [ "$ALIGNER" = "star" ]; then
        # ----------------------------------------------------------------------
        # STAR ALIGNMENT
        # ----------------------------------------------------------------------
        # STAR outputs sorted BAM directly with these parameters
        STAR --runThreadN "$THREADS" \
             --genomeDir "$STAR_INDEX_DIR" \
             --readFilesIn "$r1" "$r2" \
             --outFileNamePrefix "../aligned/${sample}_" \
             --outSAMtype BAM SortedByCoordinate
             
        # Rename STAR output to match standard naming convention
        mv "../aligned/${sample}_Aligned.sortedByCoord.out.bam" "../aligned/${sample}_sorted.bam"
        
    else
        echo "Error: Unknown aligner specified ($ALIGNER). Choose 'hisat2' or 'star'."
        exit 1
    fi
    
    echo "   Indexing BAM file..."
    samtools index -@ "$THREADS" "../aligned/${sample}_sorted.bam"
    
    echo "   $sample alignment complete."
    echo "---------------------------------------------------"
    
done

cd - > /dev/null
echo "=== All Alignments Completed! ==="
