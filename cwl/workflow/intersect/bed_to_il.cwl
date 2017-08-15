cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: arvados_pipeline_python:latest
baseCommand: ['python', '/scripts/bed_to_il.py']

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
