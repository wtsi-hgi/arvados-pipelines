cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: mercury/samtools-fastaref
baseCommand: ['samtools', 'fastaref']

requirements:
  EnvVarRequirement:
    envDef:
      REF_PATH: $(inputs.ref_cache_dir.path)/%2s/%2s/%s
      
inputs:
  - id: output_file_name
    doc: Output file name
    type: string?
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
  - id: ref_cache_dir
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
