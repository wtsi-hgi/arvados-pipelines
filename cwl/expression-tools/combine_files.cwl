cwlVersion: v1.0
class: ExpressionTool

requirements:
  - class: InlineJavascriptRequirement

expression: '
  ${
    inputs.main_file.secondaryFiles = Array.isArray(inputs.secondary_files) ? inputs.secondary_files : [inputs.secondary_files];

    return {
      "file_with_secondary_files": inputs.main_file
    }
  }
'

doc: Step to put secondary input files in the same folder as a main file
inputs:
  main_file:
    type: File
  secondary_files:
    type:
      - File
      - File[]
outputs:
  file_with_secondary_files:
    type: File
