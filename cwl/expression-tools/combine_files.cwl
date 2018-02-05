cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InitialWorkDirRequirement
    listing: |
      ${
        var secondaryFiles = inputs.secondary_files;
        if(!Array.isArray(secondaryFiles)) secondaryFiles = [secondaryFiles];

        return secondaryFiles.concat([inputs.main_file]).map(function(file){
          return {
            entry: file,
            entryname: file.basename
          }
        })}
  - class: InlineJavascriptRequirement

doc: Step to put secondary input files in the same folder as a main file
inputs:
  main_file:
    type: File
  secondary_files:
    type:
      - File
      - File[]
baseCommand: echo
outputs:
  file_with_secondary_files:
    outputBinding:
      glob: $(inputs.main_file.basename)
    secondaryFiles: '$(Array.isArray(inputs.secondary_files) ? inputs.secondary_files.map(function(file){return file.basename}) : inputs.secondary_files.basename)'
    type: File
