cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs:
  - id: reference_sequence
    type: File
  - id: refIndex
    type: File
  - id: refDict
    type: File
  - id: input_file
    type: File
  - id: out
    type: File
  - id: intervals
    type: File
  - id: chunks
    type: int
  - id: dict_file
    type: File
  - id: analysis_type
    type: string
    default: HaplotypeCaller

steps:
  - id: convert_and_split
    run: workflow/workflow.cwl
    in:
      genome_chunks: chunks
      dict: dict_file
    out: [out]
  - id: haplo
    requirements:
      - class: ScatterFeatureRequirement
    scatter: convert_and_split/out
    run: HaplotypeCaller.cwl
    in:
      reference_sequence: reference_sequence
      refIndex: refIndex
      refDict: refDict
      input_file: input_file
      intervals: convert_and_split/out
      analysis_type: analysis_type
    out: [out]

# outputs:
#   - id: out
#     type: File[]
#     outputSource: "#haplo/out"

outputs: []