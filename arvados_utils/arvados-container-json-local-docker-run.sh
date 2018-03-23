#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.6rc1
module add hgi/parallel/20140922
module add hgi/arvados-sdk-cli/git-hgi-integration-20160223-af537c70

container_json_file=$1 # container.json file downloaded from an arvados container request log collection
jobs=$2 # number of parallel jobs
local_path=$3 # local_path under which to download keep files
docker_image=$4 # docker image to run

cat ${container_json_file} | jq -r '.mounts[] | select(.kind == "collection" and (.path | length) > 0 and (.portable_data_hash | length) > 0) | .portable_data_hash + "\t" + .path' > ${container_json_file}.collection_mounts.tsv

collection_mounts_tsv="${container_json_file}.collection_mounts.tsv"
mount_count=$(cat ${collection_mounts_tsv} | wc -l)
keep_prefix="${local_path}/keep"
mkdir -p "${keep_prefix}"
keep_prefix_abs=$(cd ${keep_prefix} && pwd)

echo "Have ${mount_count} collection_mounts, ensuring directories exist under ${keep_prefix}"
parallel --progress --bar --eta --jobs ${jobs} --colsep '\t' mkdir -p ${keep_prefix}/{1} :::: ${container_json_file}.collection_mounts.tsv

echo "Downloading data from keep into ${keep_prefix}"
parallel --progress --bar --eta --jobs ${jobs} --colsep '\t' arv keep get {1}/{2} ${keep_prefix}/{1}/{2} :::: ${container_json_file}.collection_mounts.tsv

echo "Touching all downloaded files to set all mtimes equal to keep_prefix"
parallel --progress --bar --eta --jobs ${jobs} --colsep '\t' touch -r "${keep_prefix}" ${keep_prefix}/{1}/{2} :::: ${container_json_file}.collection_mounts.tsv

# TODO could optionally map wriable collections and tmp paths here
#writable_paths=$(cat ${container_json_file} | jq -r '.mounts | to_entries | .[] | select(.value.kind == "collection" and .value.writable == true) | .key')
#tmp_paths=$(cat ${container_json_file} | jq -r '.mounts | to_entries | .[] | select(.value.kind == "tmp") | .key')
docker_bind_mount_args=$(cat ${container_json_file} | jq -r '.mounts | to_entries | .[] | select(.value.kind == "collection" and (.value.path | length) > 0 and (.value.portable_data_hash | length) > 0) | " -v '${keep_prefix_abs}'/" + .value.portable_data_hash + "/" + .value.path + ":" + .key')

# Get command to be run 
command=$(cat ${container_json_file} | jq -r '.command[]')

# Get environment docker args
docker_run_env_args=$(cat ${container_json_file} | jq -r '.environment | to_entries | .[] | " -e " + .key + "=" + .value')

# Get container image to run it in
#docker_image_keep_pdh=$(cat ${container_json_file} | jq -r '.container_image')
#docker_image_tar_file=$(arv keep ls ${docker_image_keep_pdh})
#if [[ $(echo "${docker_image_tar_file}" | wc -l) -ne 1 ]]; then
#    echo "ERROR: docker image keep collection ${docker_image_keep_pdh} had an unexpected number of files"
#    exit 1
#fi
#docker_image_locator="${docker_image_keep_pdh}/$(basename ${docker_image_tar_file})"
#echo "Loading docker image from ${docker_image_locator}"
#arv keep get "${docker_image_locator}" | docker load

echo "Calling docker run"
docker run -it ${docker_run_env_args} ${docker_bind_mount_args} ${docker_image} ${command}
