cwl:tool: workflows/haplotypecaller-3.8.cwl
chunks: 200
intersect_file:
  class: File
  location: keep:0209730ab274aa4adce0557580fa6c64+90/wgs_calling_regions.hg38.interval_list
library_cram:
  class: File
  location: keep:60600a17e61eca9d3c9cae4a9a57a038+14190/14841632.CCXX.paired310.c95d2edaac.cram
ref_fasta_files:
  - $import: sanger_human_references.yaml
