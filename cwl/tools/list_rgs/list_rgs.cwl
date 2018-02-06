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
    'BEGIN {
      FS="\t";
    }
    /^@RG/ {
      for(i=1;i<=NF;i++) {
        if($i~/^ID:/) {
          print substr($i,4);
        }
      }
    }' > $(inputs.filename)

inputs:
   
  cram:
    type: File
    doc: |
      Input file with header to be simplified

  filename:
    type: string?
    doc: |
      Output file name of rg list
      

outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.filename)

     
