cwlVersion: v1.0
class: CommandLineTool
baseCommand: python
requirements:
- class: InlineJavascriptRequirement
inputs:
- id: python_script
  type: string
  inputBinding:
    position: 1
- id: dictionary
  type: File
  inputBinding:
    position: 3
- id: directory
  type: string
  inputBinding:
    position: 4

outputs:
- id: out
  type: File
  outputBinding:
    glob: $(inputs.directory)/$(inputs.dictionary.basename)
    
# stdout: $(inputs.directory.split("/").slice(-1)[0].split(".").slice(0,-1).join("."))/$(inputs.dictionary.basename)

# outputs: []
#  output:
#    type: dict
#    outputBinding:
#     glob: "*.interval_list"

