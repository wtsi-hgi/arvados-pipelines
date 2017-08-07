# What is exactly the output of each files -- figure that out so that you can example out things and connect it
# what exactly is the /var/spool that the chr22 list is being created at? 
#

cwlVersion: v1.0
class: Workflow
inputs:
  - id: genome_chunks
    type: int
  - id: dict
    type: File
  - id: split_directory
    type: string


outputs: []

steps:
  - id: convert
    run: convert_first.cwl
    in:
      dictionary: dict
    out: [out]
  - id: split
    run: split_interval_first.cwl
    in:
      number_of_intervals: genome_chunks
      interval_list: convert/out
      output_directory: split_directory
    out: [outf]

