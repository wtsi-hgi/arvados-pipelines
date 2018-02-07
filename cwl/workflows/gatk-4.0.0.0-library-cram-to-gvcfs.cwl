cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  - id: library_cram
    type: File
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]

steps:
  - id: cram_get_fasta
    run: cram-get-fasta.cwl
    in:
      input_cram: library_cram
      ref_fasta_files: ref_fasta_files
    out:
      - reference_fasta
      - reference_dict

  - id: cap_crams
    run: capmq.cwl
    in:
      library_cram: library_cram
      reference_fasta: cram_get_fasta/reference_fasta
    out:
      - capped_file

  - id: haplotype_caller
    run: gatk-4.0.0.0-haplotypecaller.cwl
    in:
      library_cram: cap_crams/capped_file
      chunks: chunks
      intersect_file: intersect_file
      reference_fasta: cram_get_fasta/reference_fasta
      reference_dict: cram_get_fasta/reference_dict
      ploidy:
        default: 2
    out:
      - gvcf_files
      - intervals

  - id: haplotype_caller_haploid
    run: gatk-4.0.0.0-haplotypecaller.cwl
    in:
      library_cram: cap_crams/capped_file
      chunks:
        default: 1
      intersect_file: intersect_file
      reference_fasta: cram_get_fasta/reference_fasta
      reference_dict: cram_get_fasta/reference_dict
      ploidy:
        default: 1
      include_chromosome_regex:
        default: "^(chr)?Y$"
    out:
      - gvcf_files
      - intervals

outputs:
  - id: gvcf_files
    type: File[]
    linkMerge: merge_flattened
    outputSource:
      - haplotype_caller/gvcf_files
      - haplotype_caller_haploid/gvcf_files
  - id: intervals
    type: File[]
    linkMerge: merge_flattened
    outputSource:
      - haplotype_caller/intervals
      - haplotype_caller_haploid/intervals
  - id: reference
    type: File
    outputSource: cram_get_fasta/reference_fasta
