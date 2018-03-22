$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

inputs:
  - id: input_file
    type: string
  - id: irobot_url
    type: string
  - id: arvados_token
    type: string
  - id: basic_username
    type: string
  - id: basic_password
    type: string
  - id: force
    type: boolean
  - id: id: no_index
    type: boolean

outputs:
  - id: output
    type: File

steps:
  
  - id: get_date_from_irods
    run: irobot_wrapper.cwl
    in:
      input_file: input_file
      irobot_url: irobot_url
      arvados_token: arvados_token
      basic_username: basic_username
      basic_password: basic_password
      force: force
      no_index: no_index
    out:
      - library_crams

  - id: haplotype_caller
    run: gatk-4.0.0.0-haplotypecaller-genotypegvcfs-libraries.cwl
    in:
      library_crams: library_crams
    out:
      - out

outputs:
  - id: output
    type: File
    outputSource: haplotype_caller/out
      