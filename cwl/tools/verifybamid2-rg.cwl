cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: mercury/verifybamid2-1.0.4-samtools-1.6:v3

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
    # secondaryFiles:
    #   - .fai
      # this tool generates fai files if they aren't specified, but
      # it's better if they're already there
  - id: svdset
    doc: SVD set to use
    type: string
    default: hgdp.100k
    inputBinding:
      prefix: --svd-set

outputs:
  - id: out-file
    type: File
    outputBinding:
      glob: "*.out"
