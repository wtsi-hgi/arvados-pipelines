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
      Script to calculate het calls in known region of homozygosity (ROH), 
      for comparison of variant callers

  filein_ROH:
    type: File
    inputBinding:
      position: 2
    doc: |
      input file of known ROH for a sample (truth set)
      
  filein_VCF:
    type: File
    inputBinding:
      position: 3
    doc: |
      input vcf, from variant caller being tested

  

stdout: $(inputs.filein_VCF.nameroot)_$(inputs.filein_ROH.nameroot)_stats.txt

outputs:
  output:
    type: stdout

doc: | 
    Run script to calculate het calls in known region of homozygosity (ROH)
