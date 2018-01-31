cwlVersion: v1.0
class: Workflow

inputs:
  varient:
    type: File[]
  list_of_intervals:
    type: string[]

steps:
  - id: consolidate_gvcfs
    scatter: interval
    run: ../tools/GenomicsDBImport-4.0.0.cwl
    in:
      variant: varient
      interval: list_of_intervals
      genomicsdb-workspace-path: /genomicsdb
    out:
      - genomicsdb-workspace

output:
  - id: genomicsdb-workspace
    type: Directory
    outputSource: consolidate_gvcfs/genomicsdb-workspace