cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

inputs:
  - id: input_cram
    type: File
  - id: ref_path_dir
    type: Directory

steps:
  - id: samtools_fastaref
    run: ../tools/fastaref/fastaref.cwl
    in:
      ref_path_dir: ref_path_dir
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

