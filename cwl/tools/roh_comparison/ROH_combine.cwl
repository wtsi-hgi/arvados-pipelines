cwlVersion: v1.0
class: CommandLineTool

baseCommand:
    - "cat"

requirements:
  DockerRequirement:
    dockerPull:  mercury/bcftools-1.6:v2

inputs:
  
  files:
    type: File[]
    inputBinding:
      position: 1
    doc: |
      array of stats files to be concatenated which should all come from the same vcf 

stdout: allstats.txt

outputs:
  stats:
    type: stdout

doc: | 
    Concatenate text files
