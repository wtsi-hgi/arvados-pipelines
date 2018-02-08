cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement

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

  - id: get_capmq_ref_cache
    run: ../tools/samtools_seq_cache_populate.cwl
    in:
      ref_fasta_files:
        source: reference_fasta
        valueFrom: $([self])
    out:
      - ref_cache

  - id: capmq
    run: ../tools/capmq.cwl
    in:
      input_file: library_cram
      ref_path_dir: get_capmq_ref_cache/ref_cache
      readgroup_caps_file: get_read_group_caps/read_group_caps_file
      use_max_contamination:
        default: True
      minimum_MAPQ:
        default: 20
      output_filename:
        source: library_cram
        valueFrom: $(self.nameroot).capmq.cram
      htslib_output_options:
        valueFrom: cram
    out: [capped_file]

  - id: cram_index
    run: ../tools/samtools/samtools-index.cwl
    in:
      input: capmq/capped_file
    out:
      - cram_index

  - id: combine_cram_index
    run: ../expression-tools/combine_files.cwl
    in:
      main_file: capmq/capped_file
      secondary_files: cram_index/cram_index
    out:
      - file_with_secondary_files

outputs:
  - id: capped_file
    type: File
    outputSource: combine_cram_index/file_with_secondary_files
