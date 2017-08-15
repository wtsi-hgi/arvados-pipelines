cwlVersion: v1.0
class: Workflow
inputs:
  - id: genome_chunks
    type: int
  - id: dict
    type: File


steps:
  - id: convert
    run: convert_first.cwl
    in:
      dictionary: dict
    out: 
      - interval_list
  - id: split
    run: split_interval_first.cwl
    in:
      number_of_intervals: genome_chunks
      interval_list: convert/interval_list
    out: 
      - split_interval_lists

outputs:
  - id: out
    type: File[]
    outputSource: "#split/split_interval_lists"
