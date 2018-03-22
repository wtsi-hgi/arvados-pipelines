cwlVersion: v1.0
class: CommandLineTool

requirements:
- class: DockerRequirement
  dockerPull: mercury/bcftools-1.6:v2

inputs:
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: --threads
    doc: 'Number of extra output compression threads [0]'
  vcf:
    type: File
    inputBinding:
      position: 2
  output_filename:
    type: string
    inputBinding:
      position: 1
      prefix: -o
      valueFrom: "$(runtime.outdir)/$(self)"
    
outputs:
  index:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)

baseCommand:
- bcftools
- index
- -t

doc: |
  About: Creates index for bgzip compressed VCF/BCF files for random access
         using TBI (tabix index) index files, which support chromosome
         lengths up to 2^29.
