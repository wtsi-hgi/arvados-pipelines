cwlVersion: v1.0
class: CommandLineTool
baseCommand: [
  "bash",
  "/interval_list_to_json.sh"
]
hints:
  DockerRequirement:
    dockerImageId: interval_list_to_json

stdout: stdout_file

inputs:
  - id: interval_list_file
    type: File
    inputBinding:
      position: 1

outputs:
  - id: list_of_intervals
    type: string[]
    outputBinding:
      glob: stdout_file
      loadContents: true
      # NOTE: this cannot be done any other way, other than this
      outputEval: $(JSON.parse(self[0].contents))
