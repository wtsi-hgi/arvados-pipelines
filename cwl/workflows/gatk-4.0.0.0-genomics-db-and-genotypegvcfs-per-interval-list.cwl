$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

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
  variants:
    type: File[]
  interval_list:
    type: File
  reference:
    type: File

steps:
  - id: interval_list_to_cwl_list
    run: ../tools/interval_list_to_json/interval_list_to_json.cwl
    in:
      interval_list_file: interval_list
    out:
      - list_of_intervals

  - id: gatk_4.0.0.0_genomics_db_and_genotypegvcfs_per_interval
    scatter: interval
    run: gatk-4.0.0.0-genomics-db-and-genotypegvcfs-per-interval.cwl
    in:
      variants: variants
      interval: interval_list_to_cwl_list/list_of_intervals
      reference: reference
    out:
      - multisample-gvcf-output

outputs:
  - id: multisample-gvcf-outputs
    type: File[]
    outputSource: gatk_4.0.0.0_genomics_db_and_genotypegvcfs_per_interval/multisample-gvcf-output
