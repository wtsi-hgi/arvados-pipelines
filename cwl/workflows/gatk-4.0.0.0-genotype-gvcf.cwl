cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement

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
    doc: The reference file for all the samples
    type: File


steps:
  # Transpose the gvcf_files matrix to obtain lists which all have one interval
  - id: transpose_gvcf_files_list
    run: ../expression-tools/matrix_transpose.cwl
    in:
      array: gvcf_files
    out: [transposed_array]
  - id: interval_list_to_cwl_list
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
    in:
      variant: transpose_gvcf_files_list/transposed_array
      list_of_intervals: interval_list_to_cwl_list/list_of_intervals
    out: [genomicsdb-workspaces]
  - id: flatten-genomicsdb-workspaces-array
    run: ../expression-tools/flatten-array.cwl
    in:
      2d-array: consolidate_gvcfs_wrapper/genomicsdb-workspaces
    out: [flattened_array]
  - id: genotype_gvcfs
    run: ../tools/GenotypeGVCFs-4.0.0.cwl
    scatter:
      - variant
    scatterMethod: dotproduct
    in:
      variant: flatten-genomicsdb-workspaces-array/flattened_array
      reference: reference
      output-filename:
        valueFrom: output.gvcf
    out:
      - output
      - variant-index
  - id: combine_gvcf_index
    scatter:
      - main_file
      - secondary_files
    scatterMethod: dotproduct
    in:
      main_file: genotype_gvcfs/output
      secondary_files: genotype_gvcfs/variant-index
    out:
      [file_with_secondary_files]
    run: ../expression-tools/combine_files.cwl
  - id: combine_gvcfs
    run: ../tools/bcftools/bcftools-concat.cwl
    in:
      vcfs: combine_gvcf_index/file_with_secondary_files
      filename:
        valueFrom: output.gvcf
    out:
      - output


outputs:
  - id: out
    type: File
    outputSource: combine_gvcfs/output