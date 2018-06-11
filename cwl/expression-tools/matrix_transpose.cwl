cwlVersion: v1.0
class: CommandLineTool
doc: Transpose a given matrix

requirements:
  InitialWorkDirRequirement:
    listing:
      - entryname: inputs.json
        entry: '{"array": $(inputs.array)}'

baseCommand:
  - python
  - -c
  - |
      import json

      with open("inputs.json") as inputs_file:
        matrix = json.load(inputs_file)["array"]

      with open("cwl.output.json", "w") as output_file:
        output_file.write(json.dumps({
          "transposed_array": zip(*matrix)
        }))

inputs:
  - id: array
    type:
      type: array
      items:
        type: array
        items: File

outputs:
  - id: transposed_array
    type:
      type: array
      items:
        type: array
        items: File