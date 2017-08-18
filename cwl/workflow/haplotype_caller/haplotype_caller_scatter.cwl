# Runs HaplotypeCaller on each of the split intervals

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
          prefix: --intervals # This need to be exactly the same as the input
        type: array
  - id: analysis_type
    type: string

steps:
  - id: haplotype_scatter
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

outputs: []