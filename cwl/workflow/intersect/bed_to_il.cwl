cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: intersect:latest
baseCommand: ['python', '/bed_to_il.py']

inputs:
  - id: input
    type: File
    inputBinding:
      prefix: --input
  - id: header
    type: File
    inputBinding:
      prefix: --header

outputs:
  - id: interval_list
    type: File
    outputBinding:
      glob: "output.bed"
