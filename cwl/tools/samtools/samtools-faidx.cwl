#!/usr/bin/env cwl-runner
#
# To use it as stand alone tool. The working directory should not have input .fa file
#    example: "./samtools-faidx.cwl --input=./test-files/mm10.fa"
# As part of a workflow should be no problem at all

cwlVersion: v1.0
class: CommandLineTool

requirements:
- $import: samtools-docker.yml
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entry: $(inputs.input)
    entryname: $(inputs.input.basename)
inputs:
  input:
    type: File
    doc: <file.fa|file.fa.gz>
  region:
    type: string?
    inputBinding:
      position: 2

outputs:
  index:
    type: File
    outputBinding:
      glob: $(inputs.input.basename).fai

baseCommand:
- samtools
- faidx

arguments:
- valueFrom: $(inputs.input.basename)
  position: 1
