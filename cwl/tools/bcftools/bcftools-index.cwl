cwlVersion: v1.0
class: CommandLineTool

requirements:
- class: DockerRequirement
  dockerPull: mercury/bcftools-1.6:v2

inputs:
  tbi_output:
    type: boolean?
    inputBinding:
      position: 1
      prefix: -t
    doc: 'Produce .tbi (instead of .csi) index'
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

doc: |
  About: Creates index for bgzip compressed VCF/BCF files for random access.
         CSI (coordinate-sorted index) is created by default. The CSI format
         supports indexing of chromosomes up to length 2^31. TBI (tabix index)
         index files, which support chromosome lengths up to 2^29, can be
         created by using the -t/--tbi option or using the tabix program
         packaged with htslib. When loading an index file, bcftools will try
         the CSI first and then the TBI.

