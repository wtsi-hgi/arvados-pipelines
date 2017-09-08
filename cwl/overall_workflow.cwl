cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: reference_sequence
    type: File
  - id: refIndex
    type: File
  - id: refDict
    type: File
  - id: input_file
    type: File
  - id: dict_file
    type: File
  - id: chunks
    type: int
  - id: analysis_type
    type: string
    default: HaplotypeCaller
  - id: intersect_file
    type: File

steps:
  - id: dict_to_interval_list
    run: workflow/dict_to_interval_list/dict_to_interval_list.cwl
    in:
      dictionary: dict_file
    out: [interval_list]

  - id: intersect
    run: workflow/intersect_intervals/intersect_intervals.cwl
    in:
      interval_list_A: intersect_file
      interval_list_B: dict_to_interval_list/interval_list
    out: [intersected_interval_list]

  - id: split_interval_list
    run: workflow/split_interval_list/split_interval_list.cwl
    in:
      number_of_intervals: chunks
      interval_list: dict_to_interval_list/interval_list
    out: [interval_lists]

  - id: haplotype_caller
    requirements:
      - class: ScatterFeatureRequirement
    scatter: intervals
    run: workflow/HaplotypeCaller.cwl
    in:
      reference_sequence: reference_sequence
      refIndex: refIndex
      refDict: refDict
      input_file: input_file
      intervals: split_interval_list/interval_lists
      analysis_type: analysis_type
    out: [outOutput]

outputs: 
  - id: gvcf_file
    type: File[]
    outputSource: haplotype_caller/outOutput