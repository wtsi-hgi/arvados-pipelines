cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['python', '/split_interval_list.py']
requirements:
  - class: InlineJavascriptRequirement
hints:
 DockerRequirement:
   dockerPull: split_interval_list:latest

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
    type:
      type: array
      items: File
    outputBinding:
      glob: "*.*_of_*.interval_list"
      outputEval: |
        ${
          var files={};
          var output=[];
          var re = /^.*[.]([0-9]+)_of_[0-9]+[.]interval_list$/;
          for (var i = 0; i < self.length; ++i) {
            var fn = self[i].basename
            var result = re.exec(fn);
            if (result === null) {
              throw new Error('Unexpected filename in output ' + fn);
            } else {
              var index = result[1];
              console.log("have index " + index + " for filename " + fn);
            }
            files[index] = self[i];
          }
          var sorted_indices = Object.keys(files);
          sorted_indices.sort(function(a,b){return parseInt(a) - parseInt(b);});
          for (index of sorted_indices) {
            output.push(files[index]);
          }
          return output;
        }