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
      FS="\\t";
      OFS="\\t";
    } 
    $1=="@HD" {
      print;
    }
    $1=="@SQ" {
      for(i=2; i<=NF; i++) {
        if($i~/^SN:/) {
          sn=$i;
        } else if($i~/^LN:/) {
          ln=$i;
        } else if($i~/^M5:/) {
          m5=$i;
        }
      }; 
      print $1, sn, ln, m5;
    }' 

inputs:
  cram:
    type: File
    doc: |
      Input file with header to be simplified

  filename:
    type: string?
    doc: |
      Output file name of simplified header file

stdout: $(inputs.filename)
     
outputs:
  stats:
    type: stdout 


doc: |
  About:   Take the reference details from the CRAM Header and output a file
  containing only the SN, LN and M5 keys and values from each @SQ row,
  in the same order as the original. The awk is standard and the samtools 
  dockerfile has it. 
