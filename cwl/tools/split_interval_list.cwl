cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/split_interval_list.py']
requirements:
  - class: InlineJavascriptRequirement
hints:
 DockerRequirement:
   dockerPull: mercury/split-interval-list:v1

inputs:
 - id: number_of_intervals
   type: int
   inputBinding:
     position: 1
     prefix: --chunks
 - id: interval_list
   type: File
   inputBinding:
     position: 2
     prefix: --path

arguments:
  - prefix: "--output_dir"
    valueFrom: $(runtime.outdir)

outputs:
  - id: interval_lists
    type: File[]
    outputBinding:
      glob: "*.*_of_*.interval_list"
      outputEval: |
        ${
          var files={};
          var output=[];
          var re = /^.*[.]([0-9]+)_of_[0-9]+[.]interval_list$/;
          if (self.length == 0) {
            return output;
          }
          for (var i = 0; i < self.length; ++i) {
            var fn = self[i].basename
            var result = re.exec(fn);
            if (result === null) {
              throw new Error("Unexpected filename in output " + fn);
            } else {
              var index = result[1];
            }
            files[index] = self[i];
          }
          var sorted_indices = Object.keys(files);
          sorted_indices.sort(function(a,b){return parseInt(a) - parseInt(b);});
          for (var i = 0; i < sorted_indices.length; ++i) {
           index = sorted_indices[i];
            output.push(files[index]);
          }
          return output;
        }

