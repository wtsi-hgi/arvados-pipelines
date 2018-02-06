cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: ScatterFeatureRequirement

inputs:
  - id: library_crams
    type: File[]
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]
steps:
  - id: haplotype_caller
    scatter:
      - library_cram
    run: gatk-4.0.0.0-haplotypecaller.cwl
    in:
      library_cram: library_crams
      chunks: chunks
      intersect_file: intersect_file
      ref_fasta_files: ref_fasta_files
    out:
      - gvcf_file
      - intervals
      - reference
  - id: genotype_gvcf
    run: gatk-4.0.0.0-genotype-gvcf.cwl
    in:
      gvcf_files: haplotype_caller/gvcf_file
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

