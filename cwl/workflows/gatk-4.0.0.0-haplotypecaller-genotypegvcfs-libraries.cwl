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
  - id: output_basename
    type: string
    default: output
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
      - gvcf_files_diploid
      - intervals_diploid
      - gvcf_files_haploid
      - intervals_haploid
      - reference

  - id: joint_calling_diploid
    run: gatk-4.0.0.0-joint-calling.cwl
    in:
      gvcf_files: haplotype_caller/gvcf_files_diploid
      intervals:
        source: haplotype_caller/intervals_diploid
        valueFrom: $(self[0])
      reference:
        source: haplotype_caller/reference
        valueFrom: $(self[0])
      output_filename:
        source: output_basename
        valueFrom: $(self).diploid.vcf.gz
    out:
       - out

  - id: joint_calling_haploid
    run: gatk-4.0.0.0-joint-calling.cwl
    in:
      gvcf_files: haplotype_caller/gvcf_files_haploid
      intervals:
        source: haplotype_caller/intervals_haploid
        valueFrom: $(self[0])
      reference:
        source: haplotype_caller/reference
        valueFrom: $(self[0])
      output_filename:
        source: output_basename
        valueFrom: $(self).haploid.vcf.gz
    out:
       - out

outputs:
  - id: output_diploid
    type: File
    outputSource: joint_calling_diploid/out
  - id: output_haploid
    type: File
    outputSource: joint_calling_haploid/out

