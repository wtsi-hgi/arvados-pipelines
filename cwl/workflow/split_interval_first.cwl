cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/gatk-split-interval-list.py']
requirements:
  - class: InlineJavascriptRequirement
hints:
 DockerRequirement:
   dockerPull: split:latest
inputs:
 - id: number_of_intervals
   type: int
   inputBinding: 
     position: 1
     prefix: --chunks
 - id: interval_list
   type: File
   inputBinding:
     position: 2
     prefix: --path

arguments:
  - prefix: "--output_dir"
    valueFrom: $(runtime.outdir)

outputs:
  - id: outf
    type: File[]
    outputBinding:
      glob: "*"
