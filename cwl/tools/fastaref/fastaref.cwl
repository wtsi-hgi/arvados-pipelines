cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: samtools:fastaref
baseCommand: ['samtools', 'fastaref']

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
  - id: REF_CACHE
    doc: The location of the REF_CACHE enviromental variable, which
      stores a cache of enviromental variables
    type: File?
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
  - id: reference_sequence
    type: File
    outputBinding:
      glob: $(inputs.output_file_name)
