cwlVersion: v1.0
class: ExpressionTool
doc: Transpose a given matrix

expression: "$({'transposed_array': inputs.array[0].map(function(col, i) => array.map(row => row[i]))})"

inputs:
  id: array
  type:
    type: array
    items:
      type: array
      items: Any
outputs:
  id: transposed_array
  type:
    type: array
    items:
      type: array
      items: Any