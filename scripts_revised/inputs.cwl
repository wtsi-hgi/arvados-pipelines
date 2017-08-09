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
chunks: 200
out: out.gvcf.gz