cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InitialWorkDirRequirement
    listing: |
      $(inputs.secondary_files.concat([inputs.main_file]).map(function(file){
          return {
            entry: file,
            entryname: file.basename
          }
        }))
  - class: InlineJavascriptRequirement

doc: Step to put secondary input files in the same folder as a main file
inputs:
  main_file:
    type: File
  secondary_files:
    type: File[]
baseCommand: echo
outputs:
  file_with_secondary_files:
    outputBinding:
      glob: $(inputs.main_file.basename)
    secondaryFiles: $(inputs.secondary_files.map(function(file){return file.basename}))
    type: File
