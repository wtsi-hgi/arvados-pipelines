#!/bin/bash

set -euf -o pipefail

docker build tools/dict_to_interval_list -t dict_to_interval_list
docker build tools/split_interval_list -t split_interval_list
docker build tools/intersect_intervals -t intersect_intervals
