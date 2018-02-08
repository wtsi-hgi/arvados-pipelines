cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: mercury/get-read-group-caps:v3

baseCommand:
  - python
  - /get_read_group_caps.py

inputs:
  - id: read_groups
    type:
      type: array
      items: string
      inputBinding:
        prefix: --read_groups
  - id: verify_bam_id_files
    type:
      type: array
      items: File
      inputBinding:
        prefix: --verify_bam_id_files

outputs:
  - id: read_group_caps_file
    type: File
    outputBinding:
      glob: "caps_file"
