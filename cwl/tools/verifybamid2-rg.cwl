cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: mercury/verifybamid2-1.0.2-samtools-1.6:v4

baseCommand: ['verifybamid_rg']

inputs:
  - id: cram
    doc: Input cram file
    type: File
    inputBinding:
      prefix: --cram-file
  - id: rg
    doc: Read group
    type: string
    inputBinding:
      prefix: --rg
  - id: ref
    type: File
    inputBinding:
      prefix: --ref-file
  - id: svdset
    doc: SVD set to use
    type: string
    default: hgdp.10k
    inputBinding:
      prefix: --svd-set

outputs: []
