cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  - id: input_cram
    type: File
  - id: ref_fasta_files
    type: File[]

steps:
  - id: samtools_seq_cache_populate
    run: ../tools/samtools_seq_cache_populate/samtools_seq_cache_populate.cwl
    in:
      ref_fasta_files: ref_fasta_files
    out: [ref_cache]

  - id: samtools_fastaref
    run: ../tools/fastaref/fastaref.cwl
    in:
      ref_path_dir: samtools_seq_cache_populate/ref_cache
      output_file_name:
        default: "reference.fa"
      input: input_cram
    out: [reference_fasta]

  - id: samtools_faidx
    run: ../tools/samtools/samtools-faidx.cwl
    in:
      fasta: samtools_fastaref/reference_fasta
    out: [fasta_index]

  - id: samtools_dict
    run: ../tools/samtools/samtools-dict.cwl
    in:
      output:
        default: "reference.dict"
      fasta: samtools_fastaref/reference_fasta
    out: [fasta_dict]

outputs:
  - id: reference_fasta
    type: File
    outputSource: samtools_fastaref/reference_fasta
  - id: reference_index
    type: File
    outputSource: samtools_faidx/fasta_index
  - id: reference_dict
    type: File
    outputSource: samtools_dict/fasta_dict

