cwlVersion: v1.0
class: CommandLineTool
baseCommand: [
  "bash",
  "-c"
]

requirements:
  - class: DockerRequirement
    dockerPull: mercury/samtools-1.6:v2
  - class: InlineJavascriptRequirement

arguments:
  - >
    samtools view -H $(inputs.cram.path) | awk
    'BEGIN {
      FS="\\t";
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
    type: string
    default: rg_list.sam
    doc: |
      Output file name of rg list

outputs:
  rg_values:
    type: string[]
    outputBinding:
      loadContents: true
      glob: $(inputs.filename)
      outputEval: $(self[0].contents.split("\n").slice(0, -1))
