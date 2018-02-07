cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: header_A
    type: File
  - id: header_B
    type: File

steps:
  - id: cleanse_header_A
    run: cleanse_header.cwl
    in:
      header: header_A
    out:
      - cleansed_header

  - id: cleanse_header_B
    run: cleanse_header.cwl
    in:
      header: header_B
    out:
      - cleansed_header

  - id: cmp
    run: cmp.cwl
    in:
      a: cleanse_header_A/cleansed_header
      b: cleanse_header_B/cleansed_header
    out: []

outputs: []