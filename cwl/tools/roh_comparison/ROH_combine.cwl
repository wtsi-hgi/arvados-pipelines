cwlVersion: v1.0
class: CommandLineTool

baseCommand:
   - "bash"
    

requirements:
  DockerRequirement:
    dockerPull:  mercury/bcftools-1.6:v2

inputs:
  script:
    type: File
    inputBinding:
      position: 1
    doc: |
      Script to calculate combine vcfs by sample (file names start with sample)

  
  files:
    type:
      type: array
      items:
        type: array
        items: File
    inputBinding:
      position: 1
    doc: |
      array of arrays of vcf files to be concatenated by sample (which should all come from the same original vcf )

#stdout: stdout.txt

outputs:
  output1:
    type: File
    outputBinding:
      glob: all_hets_in_ROH*.vcf


doc: | 
    Concatenate vcfs to one per sample
