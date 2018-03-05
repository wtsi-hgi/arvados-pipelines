#!/bin/bash

gvcf_focruuids=$1

gvcf_fopdhs="$(basename ${gvcf_focruuids} .focruuids).fopdhs"

vcf_input_json="$(basename ${gvcf_focruuids} .focruuids).vcf_input.json"

for cr in $(cat "${gvcf_focruuids}"); do
    coll=$(arv get ${cr} | jq -r  'select(.state=="Final") | .output_uuid')
    arv collection list -f '[["uuid","=","'${coll}'"]]' -s '["portable_data_hash"]' -l 1 -c none | jq -r '.items[0].portable_data_hash'
done > "${gvcf_fopdhs}"

# get first file cwl_output_json
first_pdh=$(head -n1 "${gvcf_fopdhs}")
first_cwl_output_json=$(arv keep get "${first_pdh}/cwl.output.json" | ./json_keepify_locations.sh "${first_pdh}")
# get first reference file
first_reference_json=$(echo "${first_cwl_output_json}" | jq '.reference')
# get first intervals json
first_intervals_json=$(echo "${first_cwl_output_json}" | jq '.intervals')

for pdh in $(cat "${gvcf_fopdhs}"); do
    cwl_output_json=$(arv keep get "${pdh}/cwl.output.json" | ./json_keepify_locations.sh "${pdh}")
    # get gvcf_files for this sample
    gvcf_files=$(echo "${cwl_output_json}" | jq '.gvcf_files')
    echo "${gvcf_files}"
done | jq -s '{"gvcf_files": ., "intervals": '"${first_intervals_json}"', "reference": '"${first_reference_json}"'}' > "${vcf_input_json}"

