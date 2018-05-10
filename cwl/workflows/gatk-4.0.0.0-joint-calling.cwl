$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement

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
  - id: output_filename
    doc: The name of the output VCF to produce
    type: string
    default: output.vcf.gz

steps:
  # Transpose the gvcf_files matrix to obtain lists which all have one interval list
  - id: transpose_gvcf_files_list
    run: ../expression-tools/matrix_transpose.cwl
    in:
      array: gvcf_files
    out: [transposed_array]

  - id: genomicsdbimport-and-genotype-gvcfs-per-interval-list
    scatter:
      - variants
      - interval_list
    scatterMethod: dotproduct
    run: gatk-4.0.0.0-genomics-db-and-genotypegvcfs-per-interval-list.cwl
    in:
      variants: transpose_gvcf_files_list/transposed_array
      interval_list: intervals
      reference: reference
    out: [multisample-gvcf-outputs]

  - id: flatten-multisample-gvcf-outputs
    run: ../expression-tools/flatten-array-file.cwl
    in:
      2d-array: genomicsdbimport-and-genotype-gvcfs-per-interval-list/multisample-gvcf-outputs
    out: [flattened_array]

  - id: concat_multisample_gvcfs
    run: ../tools/bcftools/bcftools-concat.cwl
    hints:
      ResourceRequirement:
        ramMin: 60000
        coresMin: 8
        tmpdirMin: 1000
      arv:RuntimeConstraints:
        keep_cache: 32768
    in:
      vcfs: flatten-multisample-gvcf-outputs/flattened_array
      filename: output_filename
      output_type:
        valueFrom: "z"
      threads:
        default: 8
    out:
      - output

  - id: index_multisample_gvcfs_csi
    run: ../tools/bcftools/bcftools-index.cwl
    hints:
      ResourceRequirement:
        coresMin: 8
        ramMin: 4000
        tmpdirMin: 1000
    in:
      vcf: concat_multisample_gvcfs/output
      threads:
        default: 8
      output_filename:
        source: concat_multisample_gvcfs/output
        valueFrom: $(self.basename).csi
    out:
      - index

  - id: index_multisample_gvcfs_tbi
    run: ../tools/bcftools/bcftools-index-tbi.cwl
    hints:
      ResourceRequirement:
        coresMin: 8
        ramMin: 4000
        tmpdirMin: 1000
    in:
      vcf: concat_multisample_gvcfs/output
      threads:
        default: 8
      output_filename:
        source: concat_multisample_gvcfs/output
        valueFrom: $(self.basename).tbi
    out:
      - index

  - id: combine_multisample_gvcf_indices
    run: ../expression-tools/combine_files.cwl
    in:
      main_file: concat_multisample_gvcfs/output
      secondary_files:
        - index_multisample_gvcfs_csi/index
        - index_multisample_gvcfs_tbi/index
    out: [file_with_secondary_files]

outputs:
  - id: out
    type: File
    outputSource: combine_multisample_gvcf_indices/file_with_secondary_files
