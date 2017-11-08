cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: ubuntu:latest
baseCommand: ['cmp']

inputs:
  - id: a
    type: File
    inputBinding:
      position: 1
  - id: b
    type: File
    inputBinding:
      position: 2

outputs: []