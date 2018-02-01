cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: gvcf_files
    doc: Array of array of GVCF files. Each inner array contains vcfs called for the corresponding interval\
      in the interval input. The outer array represents each sample.
    type:
      type: array
      items:
        type: array
        items: File
  - id: intervals
    doc: List of intervals_list files
    type: File[]
  - id: reference
    doc: List of reference files
    type: File[]


steps:
  # Transpose the gvcf_files matrix to obtain lists which all have one interval
  - id: transpose_gvcf_files_list
    run: ../expression-tools/matrix_transpose.cwl
    in:
      array: gvcf_files
    out: [transposed_array]
  - id: interval_list_to_cwl_list
    requirements:
      - class: ScatterFeatureRequirement
    run: ../tools/interval_list_to_json/interval_list_to_json.cwl
    scatter: interval_list_file
    in:
      interval_list_file: intervals
    out:
      - list_of_intervals
  - id: consolidate_gvcfs_wrapper
    scatter:
      - variant
      - list_of_intervals
    scatterMethod: dotproduct
    run: gatk-4.0.0.0-genomics-db-wrapper.cwl
    requirements:
      - class: ScatterFeatureRequirement
    in:
      variant: transpose_gvcf_files_list/transposed_array
      list_of_intervals: interval_list_to_cwl_list/list_of_intervals
    out: [genomicsdb-workspaces]
  - id: flattern-genomicsdb-workspaces-array
    run: ../expression-tools/flattern-array.cwl
    in:
      2d-array: consolidate_gvcfs_wrapper/genomicsdb-workspaces
    out: [flatterned_array]
  - id: genotype_gvcfs
    run: ../tools/GenotypeGVCFs-4.0.0.cwl
    requirements:
      - class: ScatterFeatureRequirement
    scatter:
      - variant
      - reference
    scatterMethod: dotproduct
    in:
      variant: flattern-genomicsdb-workspaces-array/flatterned_array
      reference: reference
      output-filename:
        valueFrom: output.gvcf
    out:
      - output

outputs:
  - id: out
    type: File[]
    outputSource: genotype_gvcfs/output