$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: ScatterFeatureRequirement

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
  - id: library_crams
    type: File[]
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]
  - id: haploid_chromosome_regex
    type: string
    default: "^(chr)?Y$"

steps:

  - id: haplotype_caller
    scatter:
      - library_cram
    run: gatk-4.0.0.0-library-cram-to-gvcfs.cwl
    in:
      library_cram: library_crams
      chunks: chunks
      intersect_file: intersect_file
      ref_fasta_files: ref_fasta_files
      haploid_chromosome_regex: haploid_chromosome_regex
    out:
      - gvcf_files
      - intervals
      - reference

  - id: genotype_gvcf
    run: gatk-4.0.0.0-genotype-gvcf.cwl
    in:
      gvcf_files: haplotype_caller/gvcf_files
      intervals:
        source: haplotype_caller/intervals
        valueFrom: $(self[0])
      reference:
        source: haplotype_caller/reference
        valueFrom: $(self[0])
    out:
       - out

outputs:
  - id: output
    type: File
    outputSource: genotype_gvcf/out

