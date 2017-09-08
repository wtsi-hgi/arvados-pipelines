docker build workflow/dict_to_interval_list -t dict_to_interval_list
docker build workflow/split_interval_list -t split_interval_list
docker build workflow/intersect_intervals -t intersect_intervals

tmp_folder=`mktemp -d`
curl -L $(python get_latest_release.py) > $tmp_folder/gatk_cmdline_tools.zip
unzip -q $tmp_folder/gatk_cmdline_tools.zip -d $tmp_folder
cp $tmp_folder/gatk_cmdline_tools/3.5/cwl/HaplotypeCaller.cwl ./workflow/HaplotypeCaller.cwl
rm -r $tmp_folder
