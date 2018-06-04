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
      input files of known ROH for each chromosome (truth set) \
      format RG	[2]Sample	[3]Chromosome	[4]Start	[5]End	[6]Length (bp)	[7]Number of markers	[8]Quality (average fwd-bwd phred score)
      
  filein_VCF:
    type: File
    inputBinding:
      position: 3
    doc: |
      input vcf, from variant caller being tested

  sample_mapping:
    type: File
    inputBinding:
      position: 4
    doc: |
      map sample names between vcf and ROH truth set


stdout: $(inputs.filein_VCF.nameroot)_$(inputs.filein_ROH.nameroot)_stats.txt

outputs:
  output:
    type: stdout

doc: | 
    Run script to calculate het calls in known region of homozygosity (ROH)
