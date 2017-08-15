cwlVersion: v1.0
class: Workflow
inputs:
  - id: genome_chunks
    type: int
  - id: dict
    type: File


steps:
  - id: dict_to_interval_list
    run: dict_to_interval_list/dict_to_interval_list.cwl
    in:
      dictionary: dict
    out: 
      - interval_list
  - id: split_interval_list
    run: split_interval_list/split_interval_list.cwl
    in:
      number_of_intervals: genome_chunks
      interval_list: convert/interval_list
    out: 
      - split_interval_lists

outputs:
  - id: out
    type: File[]
    outputSource: "#split_interval_list/split_interval_lists"
