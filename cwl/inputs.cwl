analysis_type: HaplotypeCaller
reference_sequence:
   class: File
   path: /home/pkarnati/cwltests/chr22_cwl_test.fa 
refIndex:
   class: File
   path: /home/pkarnati/cwltests/chr22_cwl_test.fa.fai
refDict:
   class: File
   path: /home/pkarnati/cwltests/chr22_cwl_test.fa.dict
input_file: #must be BAM or CRAM
   class: File
   path: /home/pkarnati/cwltests/chr22_cwl_test.cram
dict_file:
   class: File
   path: /home/pkarnati/interval_list/wgs-split-dict-200/hs37d5.dict
out: out.g.vcf.gz
intervals: [chr22:10591400-10591500, chr22:10591500-10591645]
  # items:
  #   - class: File
  #     path: /home/pkarnati/Desktop/interval_list_data/chr_22/chr22_cwl_test.interval_list.1_of_20.interval_list
  #   - class: File
  #     path: /home/pkarnati/Desktop/interval_list_data/chr_22/chr22_cwl_test.interval_list.2_of_20.interval_list
  #   - class: File
  #     path: /home/pkarnati/Desktop/interval_list_data/chr_22/chr22_cwl_test.interval_list.3_of_20.interval_list
  #   - class: File
  #     path: /home/pkarnati/Desktop/interval_list_data/chr_22/chr22_cwl_test.interval_list.4_of_20.interval_list
  #   - class: File
  #     path: /home/pkarnati/Desktop/interval_list_data/chr_22/chr22_cwl_test.interval_list.5_of_20.interval_list    
interval_files: []