cwlVersion: v1.0
class: Workflow 
inputs:
  - id: dict2list_script
    type: string
  - id: genome_chunks
    type: int
  - id: dictionary
    type: File
  - id: list_directory
    type: string
  - id: split_script
    type: string
  - id: num_intervals
    type: int
  - id: split_data_directory
    type: string

outputs: []

###############SOME KIND OF LOOP FUNCTION REQUIRED BC CREATES 200 ############
steps:
  - id: dict_to_list
    run: convert.cwl
    inputs:
      - id: python_script
        source: "#dict2list_script"
      - id: genome_chunks
        source: "#genome_chunks"
      - id: dictionary
        source: "#dictionary"
      - id: directory
        source: "#list_directory"
    outputs:
      - id: interval_list

 - id: split_interval
   run: split_interval.cwl
   inputs:
     - id: python_script
       source: "#split_script"
     - id: number_of_intervals:
       source: "#num_intervals"
     - id: interval_list
       source: "#dict_to_list/interval_list"
     - id: output_directory
       source: "#split_data_directory"
   outputs: []
