cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: library_cram
    type: File
  - id: reference_fasta
    type: File

steps:
  - id: get_rg_values
    run: ../tools/list_rgs.cwl
    in:
      cram: library_cram
    out:
      - rg_values

  - id: verify_bam_id
    run: ../tools/verifybamid2-rg.cwl
    scatter: rg
    scatterMethod: dotproduct
    in:
      cram: library_cram
      rg: get_rg_values/rg_values
      ref: reference_fasta
    out:
      - out-file

  - id: get_read_group_caps
    run: ../tools/get_read_group_caps.cwl
    in:
      read_groups: get_rg_values/rg_values
      verify_bam_id_files: verify_bam_id/out-file
    out:
      - read_group_caps_file

  - id: capmq
    run: ../tools/capmq.cwl
    in:
      input_file: library_cram
      reference_fasta: reference_fasta
      readgroup_caps_file: get_read_group_caps/read_group_caps_file
    out: [capped_file]

outputs:
  - id: capped_file
    type: File
    outputSource: capmq/capped_file
