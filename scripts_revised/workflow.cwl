# What is exactly the output of each files -- figure that out so that you can example out things and connect it
# what exactly is the /var/spool that the chr22 list is being created at? 
#

cwlVerision: cwl:v1.0
class: Workflow
inputs:
  - id: convert_script 
    type: 
  - id: split_script
    type: string
  - id: genome_chunks
    type: int
  - id: number_of_intervals
    type: int
  - id: dictionary
    type:
  - id: list_directory
    type: string
  - id: split_directory
    type: string


outputs: []

steps:
  - id: convert
    run: convert.cwl
    inputs:
      - id: python_script
        source: "#convert_script"
      - id: genome_chunks
        source: "#genome_chunks"
      - id: dictionary
        source: "#dictionary"
      - id: directory
        source: "#list_directory"
    outputs:
      - id: list_out
  - id: split
    run: split.cwl
    inputs:
      - id: python_script
        source: "#split_script"
      - id: number_of_intervals
        source: "#number_of_intervals"
      - id: interval_list
        source: "#convert/list_out"
      - id: directory
        source: "#split_directory"

