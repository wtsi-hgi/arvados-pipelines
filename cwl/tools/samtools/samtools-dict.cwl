#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
- $import: samtools-docker.yml
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entry: $(inputs.input)
    entryname: $(inputs.input.path.split('/').slice(-1)[0])
inputs:
  input:
    type: File
    doc: <file.fa|file.fa.gz>
    inputBinding:
      position: 1
  assembly:
    type: string?
    inputBinding:
      prefix: -a
  no-header:
    type: boolean?
    inputBinding:
      prefix: -H
  species:
    type: string?
    inputBinding:
      prefix: -s
  uri:
    type: string?
    inputBinding:
      prefix: -u
  output:
    # make this required, as we need the user to specify the file location
    type: string
    inputBinding:
      prefix: -o

outputs:
  dict:
    type: File
    outputBinding:
      glob: $(inputs.output)

baseCommand:
- samtools
- dict

