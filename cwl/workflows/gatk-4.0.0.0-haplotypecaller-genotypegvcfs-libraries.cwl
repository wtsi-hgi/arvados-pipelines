cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: library_crams
    type: File[]
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]
  - id: MAPQ_cap
    type: int

steps:
  - id: haplotype_caller
    requirements:
      - class: ScatterFeatureRequirement
    scatter:
      - library_cram
    run: gatk-4.0.0.0-haplotypecaller.cwl
    in:
      library_cram: library_crams
      chunks: chunks
      intersect_file: intersect_file
      ref_fasta_files: ref_fasta_files
      MAPQ_cap: MAPQ_cap
    out:
      - gvcf_file
      - intervals
      - reference
  - id: genotype_gvcf
    requirements:
      - class: StepInputExpressionRequirement
    run: gatk-4.0.0.0-genotype-gvcf.cwl
    in:
      gvcf_files: haplotype_caller/gvcf_file
      intervals:
        source: haplotype_caller/intervals
        valueFrom: $(self[0])
      reference: haplotype_caller/reference
    out:
       - out


outputs:
  - id: output
    type:
      type: array
      items: File
    outputSource: genotype_gvcf/out

