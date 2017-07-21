cwlVersion: v1.0
class: CommandLineTool
baseCommand: python
inputs:
 - id: python_script
   type: string
   inputBinding:
     position: 1
 - id: number_of_intervals
   type: int
   inputBinding: 
     position: 2
 - id: interval_list
   type: File
   inputBinding:
     position: 3
 - id: output_directory
   type: string
   inputBinding:
     position: 4
hints:
  DockerRequirement:
    dockerPull: interval_list:latest
outputs: []
