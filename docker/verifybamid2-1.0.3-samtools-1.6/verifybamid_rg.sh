#!/bin/bash

set -euf -o pipefail

# Process command line args
TEMP=$(getopt -o c:r:f:s: --long cram-file:,rg:,ref-file:,svd-set: \
     -n 'verifybamid_rg' -- "$@")
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"

while true ; do
        case "$1" in
                -c|--cram-file) cram_file=$2 ; shift 2 ;;
                -r|--rg) rg=$2 ; shift 2 ;;
                -f|--ref-file) ref_file=$2 ; shift 2 ;;
                -s|--svd-set) svd_set=$2 ; shift 2 ;;
                --) shift ; break ;;
                *) echo "Unrecognised option: $1" ; exit 1 ;;
        esac
done
if [[ -n "${1+x}" ]]; then
    echo "Unexpected arguments remaining after option processing: ${1}"
    exit 1
fi

if [[ -z "${cram_file+x}" ]]; then
    echo "--cram-file must be specified"
    exit 1
fi

if [[ -z "${rg+x}" ]]; then
    echo "--rg must be specified"
    exit 1
fi

if [[ -z "${ref_file+x}" ]]; then
    echo "--ref-file must be specified"
    exit 1
fi

if [[ -z "${svd_set+x}" ]]; then
    echo "--svd-set must be specified"
    exit 1
fi

exclude_rgs=$(samtools view -H "${cram_file}" | awk 'BEGIN {FS="\t"; found=0; rg="'${rg}'";} $1=="@RG" {for(i=1; i<=NF; i++){if($i~/^ID:/){split($i,rg_id,":"); have_rg=rg_id[2]; if(have_rg==rg){found=1;} else {print have_rg;}}}} END {if(found==0){print "RG not found"; exit 1;} else {exit 0;}}')

assembly=$(samtools view -H "${cram_file}" | awk 'BEGIN {FS="\t"} $1=="@SQ" {for(i=1; i<=NF; i++){if($i~/^AS:/){split($i,sq_as,":"); as=sq_as[2]; match(as,/[0-9]+/); ases[substr(as,RSTART,RLENGTH)]=1;}}} END {for(as in ases){print as}}')

svd_prefix="/resource/${svd_set}.b${assembly}.vcf.gz.dat"
bed_file="${svd_prefix}.bed"
ud_file="${svd_prefix}.UD"
mu_file="${svd_prefix}.mu"

output_file="$(basename ${cram_file} .cram).verifybamid2"

VerifyBamID --PileupFile <(samtools mpileup -G <(echo "${exclude_rgs}") -f "${ref_file}" -l "${bed_file}" "${cram_file}") --UDPath "${ud_file}" --BedPath "${bed_file}" --MeanPath "${mu_file}" --Reference "${ref_file}" --Output "${output_file}"

alpha=$(awk 'BEGIN { FS=":" } $1=="Alpha" { print $2 }' ${output_file}.out)
if [[ -n "${alpha}" ]]; then
    echo "Output has Alpha value ${alpha}"
else
    echo "Output missing Alpha value"
    echo "Output was:"
    cat "${output_file}.out"
    exit 1
fi
