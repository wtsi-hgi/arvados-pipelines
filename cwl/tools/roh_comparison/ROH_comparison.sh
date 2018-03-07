#!/bin/bash
set -e
set -u
set -o pipefail

# Input:
#   a 'truth set' of ROH regions for a sample (already known) 
#   a combined vcf including the same sample.

# Output:
#   a measure of the 'correctness' of the vcfs in those regions, based on the 
#   number of heterozygous calls 
#   in regions known to be homozygous, compared to all heterozygous calls
#   This is called from an analysis workflow to process a set of sample bed files in parallel 
#   against the same vcf file
#   Original use: vareval project (to compare variant callers)

# Checks that should have been done before calling this:    
# The sample names match in both files. 
# Both files use the same reference genome (and chromosome names match)

# vcf is standard format, multisample
# truthset format is bed: [1]Chromosome	[2]Start [3]End	[4]name

# commandline './ROH_comparison <truthDir> <experimentalvcf>'
truthROH=$1
expVCF=$2

# Truthset files are in one directory and named by sample, as <sample>_roh_hg38.bed
 
# There are bcftools view options to take out specific samples -S sample file

#echo -e "sample"'\t'"ROHHets"'\t'"AllHets"
#echo $f
sample=$(basename $truthROH | xargs |  cut -d '_' -f 1) # filename and trim whitespace
#echo $sample

# get single sample vcf
bcftools view -s $sample $expVCF  | \
# apply filters if set
bcftools view -f PASS,. | \
# take only heterozygous calls
bcftools view -g het  > "hets_$sample.vcf"
# compress
bcftools view -Oz -o "hets_$sample.vcf.gz" "hets_$sample.vcf"
# index
bcftools index "hets_$sample.vcf.gz"
  
# find het calls in ROH regions
bcftools view -R $truthROH "hets_$sample.vcf.gz" > "hets_in_ROH_$sample.vcf" 
h="$(bcftools view -H hets_in_ROH_$sample.vcf | wc -l)"
g="$(bcftools view -H hets_$sample.vcf | wc -l)"
  
#output
echo -e "$expVCF"'\t'"$sample"'\t'"$h"'\t'"$g"

#cleanup (left from when it was a loop, probably not needed)
rm hets_$sample.vcf
rm hets_$sample.vcf.gz
rm hets_in_ROH_$sample.vcf 
rm *.csi   







