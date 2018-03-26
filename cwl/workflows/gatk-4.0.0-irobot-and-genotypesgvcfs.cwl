$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

hints:
  "cwltool:Secrets":
    secrets: [arvados_token, basic_password]

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
  - id: no_index
    type: boolean
  - id: chunks
    type: int
  - id: intersect_file
    type: File
  - id: ref_fasta_files
    type: File[]
  - id: output_basename
    type: string
    default: output
  - id: haploid_chromosome_regex
    type: string
    default: "^(chr)?Y$"

steps:
  
  - id: get_date_from_irods
    run: ../tools/irobot.cwl
    in:
      input_file: input_file
      irobot_url: irobot_url
      arvados_token: arvados_token
      basic_username: basic_username
      basic_password: basic_password
      force: force
      no_index: no_index
    out:
      - output

  - id: haplotype_caller
    run: gatk-4.0.0.0-haplotypecaller-genotypegvcfs-libraries.cwl
    in:
      library_crams: get_date_from_irods/output
      chunks: chunks
      intersect_file: intersect_file
      ref_fasta_files: ref_fasta_files
      output_basename: output_basename
      haploid_chromosome_regex: haploid_chromosome_regex
    out:
      - output_diploid
      - output_haploid

outputs:
  - id: output_diploid
    type: File
    outputSource: haplotype_caller/output_diploid
  - id: output_haploid
    type: File
    outputSource: haplotype_caller/output_diploid
      