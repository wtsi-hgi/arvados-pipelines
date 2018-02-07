cwlVersion: v1.0
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: mercury/samtools-fastaref
  EnvVarRequirement:
    envDef:
      REF_PATH: $(inputs.ref_path_dir.path)/%2s/%2s/%s

baseCommand: ['samtools', 'fastaref']

inputs:
  - id: output_file_name
    doc: Output file name
    type: string?
    default: reference.fa
    inputBinding:
      prefix: -o
  - id: keys
    doc: Output the specified keys into the fasta file
    inputBinding:
      prefix: -k
      itemSeparator: ","
    type:
      - "null"
      - type: array
        items: string
  # TODO: make the overall workflow work with this uncommented
  - id: ref_path_dir
    type: Directory
  - id: max_line_length
    doc: Maximum length of outputted lines
    type: int?
    inputBinding:
      prefix: -l
  - id: input
    doc: Input sam/bam/cram file
    type: File
    inputBinding:
      position: 1 # Make this the last argument

outputs:
  - id: reference_fasta
    type: File
    outputBinding:
      glob: $(inputs.output_file_name)
