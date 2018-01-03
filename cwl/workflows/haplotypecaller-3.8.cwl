cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  - id: library_cram
    type: File
  - id: reference_sequence
    type: File
  - id: chunks
    type: int
  - id: intersect_file
    type: File

steps:
  # - id: samtools_fastaref
  #   run: ../tools/fastaref/fastaref.cwl
  #   in:
  #     output_file_name:
  #       default: "reference.fa"
  #     input: library_cram
  #   out: [reference_sequence]

  - id: samtools_faidx
    run: ../tools/samtools/samtools-faidx.cwl
    in:
#      input: samtools_fastaref/reference_sequence
      input: reference_sequence
    out: [index]

  - id: samtools_dict
    run: ../tools/samtools/samtools-dict.cwl
    in:
      output:
        default: "reference.dict"
#      input: samtools_fastaref/reference_sequence
      input: reference_sequence
    out: [dict]

  - id: dict_to_interval_list
    run: ../tools/dict_to_interval_list/dict_to_interval_list.cwl
    in:
      dictionary: samtools_dict/dict
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

  - id: combine_sequence_files
    in:
#      reference: samtools_fastaref/reference_sequence
      reference: reference_sequence
      index: samtools_faidx/index
      dict: samtools_dict/dict
    out:
      [reference_with_files]
    run:
      class: CommandLineTool
      doc: Step to put the reference, dict and index in the same folder
      inputs:
        reference: File
        index: File
        dict: File
      baseCommand: echo
      outputs:
        reference_with_files:
          outputBinding:
            glob: ${
              console.log(inputs);
              return inputs.reference.basename;
              }
          secondaryFiles:
            - $(inputs.index.basename)
            - $(inputs.dict.basename)
          type: File
      requirements:
        InitialWorkDirRequirement:
          listing:
            - entry: $(inputs.reference)
              entryname: $(inputs.reference.basename)
            - entry: $(inputs.index)
              entryname: $(inputs.reference.basename).fai
            - entry: $(inputs.dict)
              entryname: $(inputs.reference.nameroot).dict

  - id: haplotype_caller
    requirements:
      - class: ScatterFeatureRequirement
    scatter:
      - intervals
    run: ../tools/HaplotypeCaller-3.8.cwl
    in:
      reference_sequence: combine_sequence_files/reference_with_files
      input_file: library_cram
      intervals: split_interval_list/interval_lists
      num_cpu_threads_per_data_thread:
        valueFrom: ${ return 1 }
      num_threads:
        valueFrom: ${ return 1 }
      no_cmdline_in_header:
        valueFrom: ${ return true }
      annotation:
        valueFrom: $(["StrandAlleleCountsBySample", "StrandBiasBySample"])
      emitRefConfidence:
        valueFrom: GVCF
      variant_index_type:
        valueFrom: LINEAR
      variant_index_parameter:
        valueFrom: ${ return 128000 }
      sample_ploidy:
        valueFrom: ${ return 2 }
      logging_level:
        valueFrom: INFO
      out:
        valueFrom: $(inputs.input_file.nameroot)_$(inputs.intervals.nameroot).g.vcf.gz
    out: [outOutput]

outputs:
  - id: gvcf_file
    type: File[]
    outputSource: haplotype_caller/outOutput