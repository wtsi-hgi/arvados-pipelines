cwlVersion: v1.0
class: CommandLineTool
baseCommand: [
  "bash"
]

requirements:
  DockerRequirement:
    dockerPull: mercury/samtools-1.6:v2

inputs:
  script:
    type: File
    inputBinding:
      position: 1
    doc: |
      Script to extract and format the header

  cram:
    type: File
    doc: |
      Input file with header to be simplified
    inputBinding:
      position: 2

  filename:
    type: string?
    doc: |
      Output file name of simplified header file

stdout: $(inputs.filename)
     
outputs:
  stats:
    type: stdout 


doc: |
  About:   Take the reference details from the CRAM Header and output a file
  containing only the SN, LN and M5 keys and values from each @SQ row,
  in the same order as the original. The awk is standard and the samtools 
  dockerfile has it. 
