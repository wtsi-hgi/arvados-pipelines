cwlVersion: v1.0
class: CommandLineTool
hints:
  DockerRequirement:
    dockerPull: mercury/samtools-seq_cache_populate

baseCommand: ['seq_cache_populate.pl']

arguments:
  - prefix: -root
    valueFrom: $(runtime.outdir)
    position: 1

inputs:
  - id: ref_fasta_files
    doc: Reference fasta files
    type: File[]
    inputBinding:
      prefix:
      position: 2

outputs:
  - id: ref_cache
    type: Directory
    outputBinding:
      glob: .
