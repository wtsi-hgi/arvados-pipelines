#!/bin/bash

keep_pdh=$1

jq 'walk(if type == "object" then with_entries(if .key == "location" then .value |= "keep:'${keep_pdh}'/"+. else . end ) else . end )'
