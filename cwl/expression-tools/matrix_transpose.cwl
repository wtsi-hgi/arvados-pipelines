cwlVersion: v1.0
class: ExpressionTool
doc: Transpose a given matrix

requirements:
  - class: InlineJavascriptRequirement

expression: |
  $({
    'transposed_array': inputs.array[0].map(function(col, i){return inputs.array.map(function(row){return row[i]})})
  })

# NOTE: this has to use a specific type, due to
# https://github.com/common-workflow-language/cwltool/issues/638

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