cwlVersion: v1.0
class: Workflow

inputs:
  - id: interval_list_A
    type: File
  - id: interval_list_B
    type: File

steps:
  - id: interval_list_to_bed_A
    run: ../tools/intersect_intervals/interval_list_to_bed.cwl
    in:
      input: interval_list_A
    out:
      - bed_file
      - header

  - id: interval_list_to_bed_B
    run: ../tools/intersect_intervals/interval_list_to_bed.cwl
    in:
      input: interval_list_B
    out:
      - bed_file
      - header

  # - id: header_check
  #   run: header_check.cwl
  #   in:
  #     header_A: interval_list_to_bed_A/header
  #     header_B: interval_list_to_bed_B/header
  #   out: []

  - id: intersect
    run: ../tools/bedtools/bedtools-intersect.cwl
    in:
      a: interval_list_to_bed_A/bed_file
      b: interval_list_to_bed_B/bed_file
    out:
      - intersect_output

  - id: bed_to_interval_list
    run: ../tools/intersect_intervals/bed_to_interval_list.cwl
    in:
      input: intersect/intersect_output
      header: interval_list_to_bed_A/header
    out:
      - interval_list

outputs:
  - id: intersected_interval_list
    type: File
    outputSource: bed_to_interval_list/interval_list
