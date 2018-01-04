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

steps:
  - id: haplotype_caller
    requirements:
      - class: ScatterFeatureRequirement
    scatter:
      - library_cram
    run: gatk-3.8-haplotypecaller.cwl
    in:
      library_cram: library_crams
      chunks: chunks
      intersect_file: intersect_file
      ref_fasta_files: ref_fasta_files
    out: [gvcf_file]

outputs:
  - id: gvcf_file
    type:
      type: array
      items:
        - type: array
          items: File
    outputSource: haplotype_caller/gvcf_file

