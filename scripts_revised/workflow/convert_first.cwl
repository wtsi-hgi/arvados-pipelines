cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/gatk-create-interval-lists.py']
requirements:
  - class: InlineJavascriptRequirement
hints:
  DockerRequirement:
      dockerPull: convert:latest
# inputs:
#   - id: dictionary
#     type: File
#     inputBinding:
#       position: 1
#       prefix: --path=


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
  - id: out
    type: File
    outputBinding:
      glob: "*.interval_list"
    
# stdout: $(inputs.directory.split("/").slice(-1)[0].split(".").slice(0,-1).join("."))/$(inputs.dictionary.basename)

# outputs: []
#  output:
#    type: dict
#    outputBinding:
#     glob: "*.interval_list"


