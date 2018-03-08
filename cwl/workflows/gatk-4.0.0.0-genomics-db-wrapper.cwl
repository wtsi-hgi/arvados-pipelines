cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement

hints:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000

inputs:
  variant:
    type: File[]
  list_of_intervals:
    type: string[]

steps:
  - id: consolidate_gvcfs
    scatter: intervals
    run: ../tools/gatk-4.0/GenomicsDBImport.cwl
    in:
      variant: variant
      intervals: list_of_intervals
      genomicsdb-workspace-path:
        default: "genomicsdb"
    out:
      - genomicsdb-workspace

outputs:
  - id: genomicsdb-workspaces
    type: Directory[]
    outputSource: consolidate_gvcfs/genomicsdb-workspace
