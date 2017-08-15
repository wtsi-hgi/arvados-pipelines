cwlVersion: v1.0
class: Workflow
inputs:
  - id: interval_list_A
    type: File
  - id: interval_list_B
    type: File


steps:
  - id: il_to_bed_A
    run: il_to_bed.cwl
    in:
      input: interval_list_A
    out: 
      - bed_file
      - header

  - id: il_to_bed_B
    run: il_to_bed.cwl
    in:
      input: interval_list_B
    out: 
      - bed_file
      - header

  - id: header_check
    run: header_check.cwl
    in:
      a: "#il_to_bed_A/header"
      b: "#il_to_bed_B/header"
    out: []

  - id: intersect
    run: ../bedtools_intersect/bedtools_intersect.cwl
    in:
      a: "#il_to_bed_A/bed_file"
      b: "#il_to_bed_B/bed_file"
    out: 
      - intersect_output

  - id: bed_to_il
    run: bed_to_il.cwl
    in:
      input: "#intersect/intersect_output"
      header: "#il_to_bed_A/header"
    out: 
      - interval_list

outputs:
  - id: out
    type: File
    outputSource: "#bed_to_il/interval_list"
