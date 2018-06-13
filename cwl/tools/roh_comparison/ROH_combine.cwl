cwlVersion: v1.0
class: CommandLineTool

baseCommand:
    - "bcftools"
    - "concat"

requirements:
  DockerRequirement:
    dockerPull:  mercury/bcftools-1.6:v2

arguments:
  - prefix: "-o"
    valueFrom: "final.vcf"


inputs:
  
  files:
    type: File[]
    inputBinding:
      position: 1
    doc: |
      array of vcf files to be concatenated (which should all come from the same original vcf )

#stdout: stdout.txt

outputs:
  output1:
    type: File
    outputBinding:
      glob: final*.vcf


doc: | 
    Concatenate vcfs
