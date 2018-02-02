cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement

hints:
  ResourceRequirement:
    ramMin: 100
    coresMin: 1
    tmpdirMin: 1000

inputs:
  - id: library_cram
    type: File
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]
  - id: MAPQ_cap
    type: int

steps:
  - id: capmq
    run: ../tools/capmq/capmq.cwl
    in:
      input_file: library_cram
      MAPQ_cap: MAPQ_cap
    out: [capped_file]

  - id: get_cram_index
    run: ../tools/samtools/samtools-index.cwl
    in:
      input: capmq/capped_file
    out: [cram_index]

  - id: cram_get_fasta
    run: cram-get-fasta.cwl
    in:
      input_cram: library_cram
      ref_fasta_files: ref_fasta_files
    out:
      - reference_fasta
      - reference_index
      - reference_dict

  - id: dict_to_interval_list
    run: ../tools/dict_to_interval_list/dict_to_interval_list.cwl
    in:
      dictionary: cram_get_fasta/reference_dict
    out: [interval_list]

  - id: intersect
    run: ../tools/intersect_intervals/intersect_intervals.cwl
    in:
      interval_list_A: intersect_file
      interval_list_B: dict_to_interval_list/interval_list
    out: [intersected_interval_list]

  - id: split_interval_list
    run: ../tools/split_interval_list/split_interval_list.cwl
    in:
      number_of_intervals: chunks
      interval_list: intersect/intersected_interval_list
    out:
      - interval_lists

  - id: combine_reference_files
    in:
      main_file: cram_get_fasta/reference_fasta
      secondary_files:
        - cram_get_fasta/reference_index
        - cram_get_fasta/reference_dict
    out:
      [file_with_secondary_files]
    run: ../expression-tools/combine_files.cwl

  - id: combine_cram_files
    in:
      main_file: capmq/capped_file
      secondary_files:
        source:
          - get_cram_index/cram_index
          - cram_get_fasta/reference_index
        linkMerge: merge_nested
    out:
      [file_with_secondary_files]
    run: ../expression-tools/combine_files.cwl

  - id: haplotype_caller
    requirements:
      - class: ScatterFeatureRequirement
    scatter:
      - intervals
    hints:
      ResourceRequirement:
        ramMin: 8500
    run: ../tools/HaplotypeCaller-4.0.0.cwl
    in:
      reference: combine_reference_files/file_with_secondary_files
      input: combine_cram_files/file_with_secondary_files
      intervals: split_interval_list/interval_lists
      # Below are already set to their default value
      # num_cpu_threads_per_data_thread:
      #   valueFrom: ${ return 1 }
      # num_threads:
      #   valueFrom: ${ return 1 }
      add-output-vcf-command-line:
        valueFrom: ${return true }
      # Removed StrandAlleleCountsBySample in gatk 4
      annotation:
        valueFrom: $(["StrandBiasBySample"])
      emit-ref-confidence:
        valueFrom: GVCF
      # I think below isn't needed in GATK 4 anymore
      # variant_index_type:
      #   valueFrom: LINEAR
      # variant_index_parameter:
      #   valueFrom: ${ return 128000 }

      # Below is already set to the default value
      # sample-ploidy:
      #   valueFrom: ${ return 2 }
      # verbosity:
      #   valueFrom: INFO
      output-filename:
        valueFrom: $(inputs.input.nameroot)_$(inputs.intervals.nameroot).g.vcf.gz
    out:
      - output
      - variant-index
  - id: combine_haplotype_index
    scatter:
      - main_file
      - secondary_files
    scatterMethod: dotproduct
    in:
      main_file: haplotype_caller/output
      secondary_files: haplotype_caller/variant-index
    out:
      [file_with_secondary_files]
    run: ../expression-tools/combine_files.cwl

outputs:
  - id: gvcf_file
    type: File[]
    outputSource: combine_haplotype_index/file_with_secondary_files
  - id: gvcf_index
    type: File[]
    outputSource: haplotype_caller/variant-index
  - id: intervals
    type: File[]
    outputSource: split_interval_list/interval_lists
  - id: reference
    type: File
    outputSource: combine_reference_files/file_with_secondary_files
