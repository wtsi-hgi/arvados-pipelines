#!/usr/bin/env cwl-runner
#
# To use it as stand alone tool. The working directory should not have input .fa file
#    example: "./samtools-faidx.cwl --input=./test-files/mm10.fa"
# As part of a workflow should be no problem at all

cwlVersion: v1.0
class: CommandLineTool

requirements:
- class: DockerRequirement
  dockerPull: mercury/samtools-1.6:v2
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entry: $(inputs.fasta)
    entryname: $(inputs.fasta.basename)

inputs:
  fasta:
    type: File
    doc: <file.fa|file.fa.gz>
  region:
    type: string?
    inputBinding:
      position: 2

outputs:
  fasta_index:
    type: File
    outputBinding:
      glob: $(inputs.fasta.basename).fai

baseCommand:
- samtools
- faidx

arguments:
- valueFrom: $(inputs.fasta.basename)
  position: 1
