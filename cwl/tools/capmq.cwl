cwlVersion: v1.0
class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: mercury/capmq:v1
  - class: EnvVarRequirement
    envDef:
      REF_PATH: $(inputs.ref_path_dir.path)/%2s/%2s/%s
  - class: InlineJavascriptRequirement
baseCommand: ['capmq']

inputs:
  - id: ref_path_dir
    type: Directory?
  - id: input_file
    inputBinding:
      position: 1
    type: File
  - id: output_filename
    default: ""
    inputBinding:
      position: 2
      valueFrom: $(self || inputs.input_file.basename)
    type: string
  - id: MAPQ_cap
    inputBinding:
      prefix: -C
    type: int?
    doc: "Cap MAPQ at max (default: 255)"
  - id: dont_store_in_omi_aux_tag
    inputBinding:
      prefix: -S
    type: boolean?
    doc: Do not store original MAPQ in om:i aux tag
  - id: restore_mapq
    inputBinding:
      prefix: -r
    doc: Restore original MAPQ from om:i aux tag
    type: boolean?
  - id: verbose
    inputBinding:
      prefix: -v
    doc: verbose
    type: boolean?
  - id: readgroup_caps
    inputBinding:
      prefix: -g
    doc: |
        Cap MAPQ for read group IDs.
        This can be specified more than once, and if specified
        will override the -C paramater for those read groups.
    type:
      - 'null'
      - type: array
        items:
          type: record
          fields:
            - name: read_group
              type: string
            - name: cap_value
              type: float
        inputBinding:
          valueFrom: $(self.map(function (item){return item.read_group + ":" + item.cap_value}))
  - id: readgroup_caps_file
    inputBinding:
      prefix: -G
    doc: As for -g, but group ID/max value pairs are read from a tab delimited file.
    type: File?
  - id: use_max_contamination
    inputBinding:
      prefix: -f
    type: boolean?
    doc: |
        The values to -C, -g or in the file specified with -G
        are NOT maximum MAPQ scores, but estimated fraction of
        contamination (e) from which to calculate the maximum
        MAPQ as int(10*log10(1/e)).
  - id: minimum_MAPQ
    inputBinding:
      prefix: -m
    type: int?
    doc: |
        Minimum MAPQ. Do not set the calculated quality
        to less than this value. Only used with -f
        (default: 0)
  - id: htslib_input_options
    # NOTE: the input of this should be a map type, but the the expected syntax
    # (record with no field property) of this in cwl doesn't work in most cwl implementations
    # See: https://github.com/common-workflow-language/cwltool/issues/608
    type:
      - string
      - 'null'
    inputBinding:
      prefix: -I
    doc: |
      Input format and format-options.
      This is passed in through a object which has fields of the options set
      plus a compulsory file_format to set the file format.
  - id: htslib_output_options
    type:
      - string
      - 'null'
    inputBinding:
      prefix: -O
    doc: |
      Output format and format-options [SAM].
      This is passed in through a object which has fields of the options set
      plus a compulsory file_format to set the file format.

outputs:
  - id: capped_file
    type: File
    outputBinding:
      glob: $(inputs.output_filename || inputs.input_file.basename)
