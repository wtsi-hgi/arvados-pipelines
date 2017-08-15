cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: arvados_pipeline_python:latest
baseCommand: ['python', '/scripts/il_to_bed.py']

inputs:
  - id: input
    type: File
    inputBinding:
      prefix: --input

outputs:
  - id: bed_file
    type: File
    outputBinding:
      glob: "output.bed"
  - id: header
    type: File
    outputBinding:
      glob: "header.txt"
