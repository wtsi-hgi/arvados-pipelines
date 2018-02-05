cwlVersion: v1.0
class: CommandLineTool
baseCommand: [
  "bash",
  "-c"
]
  
requirements:
  DockerRequirement:
    dockerPull: mercury/samtools-1.6:v2

arguments:
  - >
    samtools view -H $(inputs.cram.path) | awk 
    '$1=="@HD" {print} $1=="@SQ" {out=$1; 
    for(i=2; i<=NF; i++){if($i~/^(SN|LN|M5):/){out=out"\t"$i;}}; 
    print out;}' 
    > $(inputs.filename)

# samtools view -H $(inputs.cram.path) | awk '$1=="@HD" {print} $1=="@SQ" {out=$1; for(i=2; i<=NF; i++){if($i~/^(SN|LN|M5):/){out=out"\t"$i;}}; print out;}' 

inputs:
   
  cram:
    type: File
    doc: |
      Input file with header to be simplified

  filename:
    type: string?
      

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.filename)

     
doc: |
  About:   Take the reference details from the CRAM Header and output a file
  containing only the SN, LN and M5 keys and values from each @SQ row,
  in the same order as the original. The awk is standard and the samtools 
  dockerfile has it. The filename is test.test

  
