cwlVersion: v1.0
class: CommandLineTool
baseCommand: [
  "bash",
  "-c"
]

requirements:
  DockerRequirement:
    dockerPull: ubuntu:14.04

arguments:
  - >
    cat "$(inputs.interval_list.path)" | awk 
    'BEGIN {
      FS="\\t";
    }
    /^@/ || $1~/$(inputs.chromosome_regex)/ {
      print;
    }' > $(inputs.output_filename)

inputs:
  interval_list:
    type: File

  output_filename:
    default: filtered_interval_list.interval_list
    type: string

  chromosome_regex:
    type: string

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)
