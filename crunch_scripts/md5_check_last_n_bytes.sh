#!/bin/bash

set -euf -o pipefail

input=$1
md5sum=$2
n=$3

dd if="${input}" bs=1 count=29 skip=$(( $(stat -c "%s" "${input}")-${n} )) 2> /dev/null | md5sum -c ${md5sum} --status
