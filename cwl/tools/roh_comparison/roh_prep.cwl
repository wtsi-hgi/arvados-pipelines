#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

baseCommand: []
   


requirements:
  - class: DockerRequirement
    dockerPull:  mercury/bcftools-1.6:v2
  - class: InitialWorkDirRequirement
    listing:
        - $(inputs.executable)

inputs:
  - id: executable
    type: File   
    inputBinding:
      position: 1
      prefix: ./
      separate: false
      valueFrom: $(self.basename)
      
  - id: ROH_chr
    type: File
    inputBinding:
      position: 2
      separate: false
      prefix: -roh=
  - id: vcf_file
    type: File
    inputBinding:
      position: 3
      separate: false
      prefix: -vcf=
  - id: sample_mapping
    type: File
    inputBinding:
      position: 4
      separate: false
      prefix: -map= 

#stdout: stdout.txt

outputs:
  output1:
    type: File
    outputBinding:
      glob: het*.vcf


doc: | 
    produce vcfs of het calls in known ROH regions as part of assessment
