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
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000

inputs:
  - id: library_cram
    type: File
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: reference_dict
    type: File
  - id: reference_fasta
    type: File
  - id: ploidy
    type: int
  - id: include_chromosome_regex
    type: string
    default: "."
  - id: pcr_free
    type: boolean
    default: true
    
steps:
  - id: dict_to_interval_list
    run: ../tools/dict_to_interval_list.cwl
    in:
      dictionary: reference_dict
    out: [interval_list]

  - id: intersect
    run: intersect_intervals.cwl
    in:
      interval_list_A: intersect_file
      interval_list_B: dict_to_interval_list/interval_list
    out: [intersected_interval_list]

  - id: filter_interval_list
    run: ../tools/filter_interval_list.cwl
    in:
      interval_list: intersect/intersected_interval_list
      chromosome_regex: include_chromosome_regex
    out:
      - output

  - id: split_interval_list
    run: ../tools/split_interval_list.cwl
    in:
      number_of_intervals: chunks
      interval_list: filter_interval_list/output
    out:
      - interval_lists

  - id: haplotype_caller
    scatter:
      - intervals
    hints:
      ResourceRequirement:
        ramMin: 6000
        coresMin: 1
        tmpdirMin: 1000
    run: ../tools/gatk-4.0/HaplotypeCaller.cwl
    in:
      reference: reference_fasta
      input: library_cram
      intervals: split_interval_list/interval_lists
      # num_cpu_threads_per_data_thread:
      #   valueFrom: ${ return 1 }
      # num_threads:
      #   valueFrom: ${ return 1 }
      add-output-vcf-command-line:
        valueFrom: $( false )
      annotation:
        valueFrom: $(["DepthPerAlleleBySample","StrandBiasBySample"])
      emit-ref-confidence:
        valueFrom: GVCF
      sample-ploidy: ploidy
      pcr-indel-model:
        source: pcr_free
        valueFrom: ${ if(self) { return "NONE" } else { return "CONSERVATIVE" }}
      verbosity:
        valueFrom: INFO
      create-output-variant-index:
        valueFrom: $( true )
      create-output-variant-md5:
        valueFrom: $( true )
      output-filename:
        valueFrom: $(inputs.input.nameroot)_$(inputs.intervals.nameroot).g.vcf.gz
    out:
      - output
      - variant-index
      - variant-md5

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
  - id: gvcf_files
    type: File[]
    outputSource: combine_haplotype_index/file_with_secondary_files
  - id: intervals
    type: File[]
    outputSource: split_interval_list/interval_lists

