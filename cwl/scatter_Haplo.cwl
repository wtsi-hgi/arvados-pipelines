cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  - id: reference_sequence
    type: File
  - id: refIndex
    type: File
  - id: refDict
    type: File
  - id: input_file
    type: File
  - id: out
    type: string
  - id: intervals
    type:
      - label: list_of_file_or_string
        items:
          - File
          - string
        inputBinding:
          prefix: --intervals
        type: array
  - id: analysis_type
    type: string

steps:
  - id: haplo
    in:
      reference_sequence: reference_sequence
      refIndex: refIndex
      refDict: refDict
      intervals: intervals
      input_file: input_file
      out: out
      analysis_type: analysis_type
    out: []
    scatter: intervals
    run: HaplotypeCaller.cwl

# outputs:
#   - id: out
#     type: File[]
#     outputSource: "#haplo/output"

outputs: []