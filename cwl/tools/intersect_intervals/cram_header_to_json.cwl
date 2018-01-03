cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: mercury/sambamba

baseCommand: ['sambamba', 'view', '-H', '-f', 'json']

inputs:
  - id: header
    type: File
    inputBinding:
      position: 1

outputs:
  - id: cleansed_header
    type: File
    outputBinding:
      glob: "cleansed_header.txt"
