cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: ScatterFeatureRequirement

inputs:
  - id: library_cram
    type: File[]
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
      ref_path_dir: ref_fasta_files
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
      library_cram: library_cram
      chunks: chunks
      intersect_file: intersect_file
      reference_fasta: cram_get_fasta/reference_fasta
      reference_dict: cram_get_fasta/reference_dict
      ploidy: 2
    out:
      - gvcf_files
      - intervals
      

outputs:
  - id: gvcf_files
    type: File
    outputSource: haplotype_caller/gvcf_file
  - id: intervals
    type: File[]
    outputSource: haplotype_caller/intervals
