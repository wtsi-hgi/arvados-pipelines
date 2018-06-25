#!/usr/bin/env cwl-runner
#
# To use it as stand alone tool. The working directory should not have input .fa file
#    example: "./samtools-faidx.cwl --input=./test-files/mm10.fa"
# As part of a workflow should be no problem at all

cwlVersion: v1.0
class: CommandLineTool

arguments:
  - bash
  - -c
  - ln -s $(inputs.fasta.path) $(inputs.fasta.basename) && exec "$@"
  - bash
  - samtools
  - faidx

requirements:
- class: DockerRequirement
  dockerPull: mercury/samtools-1.6:v2
- class: InlineJavascriptRequirement

inputs:
  fasta:
    type: File
    doc: <file.fa|file.fa.gz>
    inputBinding:
      valueFrom: $(inputs.fasta.basename)
      position: 1
  region:
    type: string?
    inputBinding:
      position: 2

outputs:
  fasta_index:
    type: File
    outputBinding:
      glob: $(inputs.fasta.basename).fai
