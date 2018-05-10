$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

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
  interval:
    type: string
  reference:
    type: File

steps:
  - id: genomics_db_import_gvcfs
    run: ../tools/gatk-4.0/GenomicsDBImport.cwl
    hints:
      ResourceRequirement:
        coresMin: 6 # reader-threads + 1
        ramMin: 18000 # currently hard-coded for Java to use 4g, leaving 4g+ for TileDB (see Caveats above) and another 10g for arv-mount's large memory consumption when reading lots of collections
        tmpdirMin: 1000
      arv:RuntimeConstraints:
        keep_cache: 1280 # 64 * (4 * reader-threads)
    in:
      variant: variants
      genomicsdb-workspace-path:
        default: "genomicsdb"
      batch-size:
        default: 50
      intervals: interval
      reader-threads:
        default: 5 # does not scale well past 5
      interval-padding:
        default: 500
    out:
      - genomicsdb-workspace

  - id: genotype_gvcfs
    run: ../tools/gatk-4.0/GenotypeGVCFs.cwl
    hints:
      ResourceRequirement:
        ramMin: 20000 # FIXME tool is hard-coded for java to use 16000, plus an additional 4GB for arv-mount 
        coresMin: 1
        tmpdirMin: 1000
    in:
      reference: reference
      output-filename:
        valueFrom: output.g.vcf.gz
      # TODO: Should we add a dbsnp option?
      only-output-calls-starting-in-intervals:
        default: true
      use-new-qual-calculator:
        default: true
      variant: genomics_db_import_gvcfs/genomicsdb-workspace
      intervals: interval
      create-output-variant-index:
        default: true
    out:
      - output
      - variant-index

  - id: multisample_gvcf_output_with_index
    in:
      main_file: genotype_gvcfs/output
      secondary_files: genotype_gvcfs/variant-index
    out:
      - file_with_secondary_files
    run: ../expression-tools/combine_files.cwl

outputs:
  - id: multisample-gvcf-output
    type: File
    outputSource: multisample_gvcf_output_with_index/file_with_secondary_files
