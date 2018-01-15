cwlVersion: v1.0
class: CommandLineTool
hints:
 DockerRequirement:
   dockerPull: mercury/sambamba

baseCommand: ['sambamba', 'view', '-S', '-H', '-f', 'json', '-o', 'header.json']

inputs:
  - id: header
    type: File
    inputBinding:
      position: 1

outputs:
  - id: header_json
    type: File
    outputBinding:
      glob: header.json
