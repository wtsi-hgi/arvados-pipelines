$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement

hints:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000
  arv:RuntimeConstraints:
    keep_cache: 1024
    outputDirType: keep_output_dir
  cwltool:LoadListingRequirement:
    loadListing: no_listing
  arv:IntermediateOutput:
      outputTTL: 2592000

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
    run: ../expression-tools/flatten-array-directory.cwl
    in:
      2d-array: consolidate_gvcfs_wrapper/genomicsdb-workspaces
    out: [flattened_array]

  - id: genotype_gvcfs
    run: ../tools/gatk-4.0/GenotypeGVCFs.cwl
    scatter:
      - variant
    scatterMethod: dotproduct
    hints:
      ResourceRequirement:
        ramMin: 16500 # FIXME tool is hard-coded for java to use 12500, plus an additional 4GB for arv-mount 
    in:
      variant: flatten-genomicsdb-workspaces-array/flattened_array
      reference: reference
      output-filename:
        valueFrom: output.g.vcf.gz
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
        valueFrom: output.g.vcf.gz
    out:
      - output


outputs:
  - id: out
    type: File
    outputSource: combine_gvcfs/output
