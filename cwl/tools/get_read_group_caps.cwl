cwlVersion: v1.0
class: ExpressionTool

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: read_group
    type: string
  - id: verify_bam_id_file
    type: File
    inputBinding:
      loadContents: true

expression: |
  ${
    var fileContents = inputs.verify_bam_id_file.contents;
    var capValue = parseFloat(fileContents.slice((fileContents.search("Alpha:") + "Alpha:".length)));
    return {
      read_groups_caps: {
        read_group: inputs.read_group,
        cap_value: capValue
      }
    }
  }

outputs:
  - id: read_groups_caps
    type:
      type: record
      fields:
        - name: read_group
          type: string
        - name: cap_value
          type: float

