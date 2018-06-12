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
# truthset format is  [1]RG	[2]Sample	[3]Chromosome	[4]Start	[5]End	
# [6]Length (bp)	[7]Number of markers	[8]Quality (average fwd-bwd phred score)
# and chromosomes are just numbers

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
# List files for concat step
files="" 
while read sample; do
    echo $sample
    # is the sample in the chromosome truth set?
   
    s=$(grep "$sample" "$sampleMap")
    echo $s
    # the second value which starts with sc_ is the one we want
    for word in $s 
    do
        real_sample=$word
    done
   
    a=$(grep -c "$real_sample" "$truthROH")
   
    if [ $a = 0 ]
    then
     echo $sample not found
    fi
    
    # Make a bed file for that sample truth set chrom start end
    grep $real_sample $truthROH | cut -f3-5  > $sample.tmp
    # Transform the chromosome naming from 1 to chr1 (for a check, test if necessary before permanent use)
    awk '{$1 = "chr"$1; print}' $sample.tmp > $sample.tmp2
    awk '$1=$1' FS=" " OFS="\t" $sample.tmp2 > $sample.bed

    # get single sample vcf#    
    bcftools view -s $sample $expVCF  | \
    # apply filters if set   
    bcftools view -f PASS,. | \
    # take only heterozygous calls
    bcftools view -g het  > hets_"$sample"_"$chromosome".vcf
    # compress   
    bcftools view -Oz -o hets_"$sample"_"$chromosome".vcf.gz hets_"$sample"_"$chromosome".vcf
    # index
    bcftools index hets_"$sample"_"$chromosome".vcf.gz
    
    # find het calls in ROH regions   
    bcftools view -R "$sample".bed hets_"$sample"_"$chromosome".vcf.gz > hets_in_ROH_"$sample"_"$chromosome".vcf 
    # compress
    bcftools view -Oz -o hets_in_ROH_"$sample"_"$chromosome".vcf.gz hets_in_ROH_"$sample"_"$chromosome".vcf
    # index 
    bcftools index hets_in_ROH_"$sample"_"$chromosome".vcf.gz

    files+=" "
    files+=hets_in_ROH_"$sample"_"$chromosome".vcf.gz
    # Next lines give counts, for now output actual vcfs. 
    #h="$(bcftools view -H hets_in_ROH_"$sample"_"$chromosome".vcf | wc -l)"
    #g="$(bcftools view -H hets_"$sample"_"$chromosome".vcf | wc -l)"

    
    
    #output
    #echo -e "$chromosome"'\t'"$expVCF"'\t'"$sample"'\t'"$h"'\t'"$g"
   

done < temp_samples.txt

# combine to one file per chromosome, to be collected in cwl
    bcftools  merge  $files > output_"$chromosome".vcf

#cleanup (probably not needed in docker)
#rm hets_$sample.vcf
#rm hets_$sample.vcf.gz
#rm hets_in_ROH_$sample.vcf 
#rm *.csi   







