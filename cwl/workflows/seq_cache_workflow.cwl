$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"
cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement

hints:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000
  arv:RuntimeConstraints:
    keep_cache: 1024
    outputDirType: keep_output_dir
  arv:IntermediateOutput:
      outputTTL: 2592000
  cwltool:LoadListingRequirement:
    loadListing: no_listing

inputs:
  - id: ref_fasta_files
    type: File[]

steps:
  - id: samtools_seq_cache_populate
    run: ../tools/samtools_seq_cache_populate.cwl
    in:
      ref_fasta_files: ref_fasta_files
    out: [ref_cache]
    hints:
      ResourceRequirement:
        ramMin: 100000
        coresMin: 1
        tmpdirMin: 1000

outputs:
  - id: ref_cache
    type: Directory
    outputSource: samtools_seq_cache_populate/ref_cache


