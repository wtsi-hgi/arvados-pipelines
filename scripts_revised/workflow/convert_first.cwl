cwlVersion: v1.0
class: CommandLineTool
baseCommand: python gatk-create-interval-lists.py --output_dir $(runtime.outdir)
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

inputs:
  - id: dictionary
    type: string
    inputBinding:
      position: 1
      prefix: --path=

outputs:
  - id: out
    type: File
    outputBinding:
      glob: $(runtime.outdir)
    
# stdout: $(inputs.directory.split("/").slice(-1)[0].split(".").slice(0,-1).join("."))/$(inputs.dictionary.basename)

# outputs: []
#  output:
#    type: dict
#    outputBinding:
#     glob: "*.interval_list"


arguments:

