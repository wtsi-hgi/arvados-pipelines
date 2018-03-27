cwlVersion: v1.0
class: CommandLineTool

baseCommand: irobotclient

$namespaces:
  arv: "http://arvados.org/cwl#"   # Arvados support and api token integration 'work in progress'

requirements:

  - class: arv:APIRequirement

  - class: DockerRequirement
    dockerPull: mercury/irobot-client

arguments:
  - position: 2
    valueFrom: $(runtime.outdir)

inputs:

  - id: input_file
    type: string
    inputBinding:
      position: 1

  - id: irobot_url
    type: ["null", string]
    inputBinding:
      prefix: -u
      position: 3

  - id: arvados_token
    type: ["null", string]
    inputBinding:
      prefix: --arvados_token
      position: 4

  - id: basic_username
    type: ["null", string]
    inputBinding:
      prefix: --basic_username
      position: 5

  - id: basic_password
    type: ["null", string]
    inputBinding:
      prefix: --basic_password
      position: 6

  - id: force
    type: ["null", boolean]
    inputBinding:
      prefix: -f
      position: 7

  - id: no_index
    type: ["null", boolean]
    inputBinding:
      prefix: --no_index
      position: 8

outputs:

  - id: output
    type: File[]
    outputBinding:
      glob: 
        - "*.cram*"
        - "*.bam*"
