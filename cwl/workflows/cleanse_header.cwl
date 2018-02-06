cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: header
    type: File

steps:
  - id: sam_header_to_json
    run: sam_header_to_json.cwl
    in:
      header: header
    out: [header_json]

  - id: filter_json
    run: jq_json_to_json.cwl
    in:
      json_input: sam_header_to_json/header_json
    out: [json_output]

outputs:
  - id: cleansed_header
    type: File
    outputSource: sam_header_to_json/header_json
