#!/bin/bash
set -e
set -u
set -o pipefail

# Input:
#   a set of vcf files named hets_in_ROH_"$sample"_"$chromosome".ROHs.txt.vcf.gz

# Output:
#   a set of vcf files per sample, for all chromosomes


# commandline './ROH_combine '<filenames>'


# List files for concat step
samples=""
files=""
for arg    # "in $@" is implied
    do
    #make lists of files and samples
        #echo $arg
        sample="$(bcftools query -l $arg)" 
        #echo xx $sample 
        files="$files $arg"
        
        if echo "$samples" | grep -q "$sample"; then
            echo "matched";
        else
            samples="$samples $sample";
        fi

        #echo $samples
        #echo $files
   done

   # use lists of files and samples to make a vcf per sample
for s in $samples
do
    #echo $s
    samplefiles=""
    for f in $files 
       do
        if echo "$f" | grep -q "$s"; then
           samplefiles="$samplefiles $f"
        fi
       done
    echo $samplefiles   
    bcftools concat $samplefiles > all_hets_in_ROH_$sample.vcf

done
    
   










