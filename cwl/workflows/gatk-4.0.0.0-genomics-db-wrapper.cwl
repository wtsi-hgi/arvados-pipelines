$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement

hints:
  ResourceRequirement:
    ramMin: 4000
    coresMin: 1
    tmpdirMin: 1000
  arv:RuntimeConstraints:
    keep_cache: 1024
    outputDirType: keep_output_dir
  cwltool:LoadListingRequirement:
    loadListing: no_listing
  arv:IntermediateOutput:
      outputTTL: 2592000

inputs:
  variant:
    type: File[]
  list_of_intervals:
    type: string[]

steps:
  - id: consolidate_gvcfs
    scatter: intervals
    run: ../tools/gatk-4.0/GenomicsDBImport.cwl
    hints:
      arv:RuntimeConstraints:
        keep_cache: 1280 # 64 * (4 * reader-threads)
    in:
      variant: variant
      genomicsdb-workspace-path:
        default: "genomicsdb"
      batch-size:
	default: "50"
      intervals: list_of_intervals
      reader-threads:
	default: "5" # does not scale well past 5
      interval-padding:
	default: "500"
    out:
      - genomicsdb-workspace

outputs:
  - id: genomicsdb-workspaces
    type: Directory[]
    outputSource: consolidate_gvcfs/genomicsdb-workspace
