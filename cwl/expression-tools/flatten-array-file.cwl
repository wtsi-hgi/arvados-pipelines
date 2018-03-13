cwlVersion: v1.0
class: ExpressionTool
doc: Transpose a given array

requirements:
  - class: InlineJavascriptRequirement

expression: "$({'flattened_array': [].concat.apply([], inputs['2d-array'])})"

inputs:
  - id: 2d-array
    type:
      type: array
      items:
        type: array
        items: File

outputs:
  - id: flattened_array
    type:
      type: array
      items: File
