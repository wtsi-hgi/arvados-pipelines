cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: mercury/verifybamid2-1.0.2-samtools-1.6:v3

baseCommand: ['verifybamid_rg']

inputs:
  - id: cram-file
    doc: Input cram file
    type: File
    inputBinding:
      prefix: --cram-file
  - id: rg
    doc: Read group
    type: string
    inputBinding:
      prefix: --rg
  - id: ref-file
    type: File
    inputBinding:
      prefix: --ref-file
  - id: svd-prefix
    type: string
    inputBinding:
      prefix: --svd-prefix

outputs: []
