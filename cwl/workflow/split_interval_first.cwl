cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/scripts/gatk-split-interval-list.py']
hints:
 DockerRequirement:
   dockerPull: arvados_pipeline_python:latest

inputs:
 - id: number_of_intervals
   type: int
   inputBinding: 
     position: 1
     prefix: --chunks
 - id: interval_list
   type: File
   inputBinding:
     position: 2
     prefix: --path

arguments:
  - prefix: "--output_dir"
    valueFrom: $(runtime.outdir)

outputs:
  - id: split_interval_lists
    type: File[]
    outputBinding:
      glob: "*"
