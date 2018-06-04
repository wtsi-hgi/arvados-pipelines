#!/bin/bash
set -e
set -u
set -o pipefail

# Input:
#   a 'truth set' of ROH regions in samples for a chromosome (already known) 
#   a combined vcf including the same sample.

# Output:
#   a measure of the 'correctness' of the vcfs in those regions, based on the 
#   number of heterozygous calls 
#   in regions known to be homozygous, compared to all heterozygous calls
#   This is called from an analysis workflow to process a set of truth ROH files in parallel 
#   against the same vcf file
#   Original use: vareval project (to compare variant callers)

# Checks that should have been done before calling this:    
# The sample names match in both files. (In the original case they are prefixed with sc_autozyg
# in the truth set but not in the vcf)
# Both files use the same reference genome (and chromosome names match)

# vcf is standard format, multisample
# truthset format is format RG	[2]Sample	[3]Chromosome	[4]Start	[5]End	
# [6]Length (bp)	[7]Number of markers	[8]Quality (average fwd-bwd phred score)

# commandline './ROH_comparison <truthDir> <experimentalvcf> <samplemappings>'
truthROH=$1
expVCF=$2
sampleMap=$3

# Truthset files are in one directory and named by chromosome, eg chr1.ROHs.txt 
# There are bcftools view options to take out specific samples -S sample file
chromosome=$(basename $truthROH)
echo $chromosome

#echo -e "sample"'\t'"ROHHets"'\t'"AllHets"
#echo $f
#sample=$(basename $truthROH | xargs |  cut -d '_' -f 1) # filename and trim whitespace
# get samples 
bcftools query -l $expVCF > temp_samples.txt
#echo $sample
while read sample; do
    echo $sample
    # is the sample in the chromosome truth set?
    echo "Here" 
    s=$(grep "$sample" "$sampleMap")
    echo $s
    # the second value which starts with sc_ is the one we want
    for word in $s 
    do
        real_sample=$word
    done
    echo $real_sample
    a=$(grep -c "$real_sample" "$truthROH")
    echo "count is" $a
    if [ $a = 0 ]
    then
     echo $sample not found
    fi
    echo "x"
    # Make a bed file for that sample truth set chrom start end
    grep $real_sample $truthROH | cut -f3-5  > $sample.bed
    # get single sample vcf#
    echo "xx"
    bcftools view -s $sample $expVCF  | \
    # apply filters if set   
    bcftools view -f PASS,. | \
    # take only heterozygous calls
    bcftools view -g het  > hets_"$sample"_"$chromosome".vcf
    # compress
     echo "xxx"
    bcftools view -Oz -o hets_"$sample"_"$chromosome".vcf.gz hets_"$sample"_"$chromosome".vcf
    # index
    bcftools index hets_"$sample"_"$chromosome".vcf.gz
    
    # find het calls in ROH regions
    echo "xxxx"
    bcftools view -R "$sample".bed hets_"$sample"_"$chromosome".vcf.gz > hets_in_ROH_"$sample"_"$chromosome".vcf 
    h="$(bcftools view -H hets_in_ROH_"$sample"_"$chromosome".vcf | wc -l)"
    g="$(bcftools view -H hets_"$sample"_"$chromosome".vcf | wc -l)"
    
    #output
    echo -e "$chromosome"'\t'"$expVCF"'\t'"$sample"'\t'"$h"'\t'"$g"

done < temp_samples.txt
#cleanup (left from when it was a loop, probably not needed)
#rm hets_$sample.vcf
#rm hets_$sample.vcf.gz
#rm hets_in_ROH_$sample.vcf 
#rm *.csi   







