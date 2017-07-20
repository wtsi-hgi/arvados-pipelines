cwlVersion: v1.0
class: CommandLineTool
baseCommand: /home/pkarnati/arvados-pipelines/scripts_revised/split_interval_list/gatk-split-interval-list.py

inputs:
#  script:
#    type: File
  inp:
    type: File
    inputBinding:
      position: 2
  genome_chunks:
    type: int
    inputBinding:
      position: 1
  path:
    type: string
    inputBinding:
      position: 3

outputs: []


arguments:
  shellQuote: false
  valueFrom: [$(inputs.genome_chunks), $(inputs.inp), $(inputs.path)]