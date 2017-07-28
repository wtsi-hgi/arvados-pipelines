# What is exactly the output of each files -- figure that out so that you can example out things and connect it
# what exactly is the /var/spool that the chr22 list is being created at? 
#

cwlVersion: v1.0
class: Workflow
inputs:
  - id: convert_script 
    type: string
  - id: split_script
    type: string
  - id: genome_chunks
    type: int
  - id: dictionary
    type: File
  - id: list_directory
    type: string
  - id: split_directory
    type: string


outputs: []

steps:
  - id: convert
    run: convertfirst.cwl
    in:
      python_script: convert_script
      dictionary: dictionary
      directory: list_directory
    out: [out]
  - id: split
    run: split_interval_first.cwl
    in:
      python_script: split_script
      number_of_intervals: genome_chunks
      interval_list: convert/out
      output_directory: split_directory
    out: []

