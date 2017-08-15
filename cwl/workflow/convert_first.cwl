cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/scripts/gatk-create-interval-lists.py']
requirements:
  - class: InlineJavascriptRequirement
hints:
  DockerRequirement:
    dockerPull: arvados_pipeline_python:latest

arguments:
  - prefix: "--output_dir"
    valueFrom: $(runtime.outdir)

inputs:
  - id: dictionary
    type: File
    inputBinding:
      position: 1
      prefix: --path
      itemSeparator: ' '

outputs:
  - id: interval_list
    type: File
    outputBinding:
      glob: "*.interval_list"
