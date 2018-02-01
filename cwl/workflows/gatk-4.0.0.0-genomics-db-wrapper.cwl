cwlVersion: v1.0
class: Workflow

inputs:
  variant:
    type: File[]
  list_of_intervals:
    type: string[]

steps:
  - id: consolidate_gvcfs
    scatter: intervals
    run: ../tools/GenomicsDBImport-4.0.0.cwl
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
