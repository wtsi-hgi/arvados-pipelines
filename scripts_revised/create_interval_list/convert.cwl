cwlVersion: v1.0
class: CommandLineTool
baseCommand: python
inputs:
- id: python_script
  type: string
  inputBinding:
    position: 1
- id: intervals
  type: int
  inputBinding:
    position: 2
- id: dictionary
  type: File
  inputBinding:
    position: 3
- id: directory
  type: string
  inputBinding:
    position: 4
outputs: []
