cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/dict_to_interval_list.py']
hints:
  DockerRequirement:
    dockerPull: mercury/dict-to-interval-list:v1

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
  - id: interval_list
    type: File
    outputBinding:
      glob: "*.interval_list"
