tmp_folder=`mktemp -d`
curl -L $(python get_latest_release.py) > $tmp_folder/gatk_cmdline_tools.zip
unzip $tmp_folder/gatk_cmdline_tools.zip -d $tmp_folder
cp $tmp_folder/gatk_cmdline_tools/3.5/cwl/HaplotypeCaller.cwl ./HaplotypeCaller.cwl
rm -r $tmp_folder
