#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
requirements:
- class: DockerRequirement
  dockerPull: mercury/samtools-1.6:v2
- class: InlineJavascriptRequirement

inputs:
  input:
    type: File
    doc: Input bam file.
    inputBinding:
      position: 0
  output_filename:
    type: string?
    default: ""
    inputBinding:
      position: 1
      valueFrom: $(self || inputs.input.basename + ".crai")
    doc: Filename of the the output file
  generate_bai_index:
    type: boolean?
    doc: Generate BAI-format index for BAM files [default]
    inputBinding:
      prefix: -b
  generate_csi_index:
    type: boolean?
    doc: Generate CSI-format index for BAM files
    inputBinding:
      prefix: -c
  minimum_interval_size:
    type: int?
    inputBinding:
      prefix: -m
  number_of_threads:
    type: int?
    inputBinding:
      prefix: -@

outputs:
  cram_index:
    type: File
    outputBinding:
      glob: $(inputs.output_filename || inputs.input.basename + ".crai")

baseCommand: [samtools, index]
