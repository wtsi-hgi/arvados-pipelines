cwlVersion: v1.0
class: CommandLineTool
baseCommand: python gatk-split-interval-list.py
hints:
 DockerRequirement:
   dockerPull: split:latest
inputs:
 - id: number_of_intervals
   type: int
   inputBinding: 
     position: 1
 - id: interval_list
   type: File
   inputBinding:
     position: 2
 - id: output_directory
   type: string
   inputBinding:
     position: 3
outputs: []
