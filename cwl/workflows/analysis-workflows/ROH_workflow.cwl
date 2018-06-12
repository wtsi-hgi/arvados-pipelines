$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

cwlVersion: v1.0
class: Workflow

# input the script, the array of ROH files and a multisample vcf and scatter 
# the ROH calculations then combine the results (vcf, sample, hets in ROH, all hets, 
# tab separated) to a single output file
# Before running on Arvados the files needed must be in keep, and a yaml with the file array generated.

requirements:
  - class: ScatterFeatureRequirement

inputs:
  - id: script
    type: File
  - id: ROH_chr
    type: File[]
  - id: vcf_file
    type: File
  - id: sample_mapping
    type: File    
    
steps:

  - id: ROH_calc
    scatter:
      - filein_ROH      
    run: ../../tools/roh_comparison/ROH_comparison.cwl
    in:
      script: script
      filein_ROH: ROH_chr
      filein_VCF: vcf_file 
      sample_mapping: sample_mapping       
    out: [output1]

  - id: ROH_combine
    run: ../../tools/roh_comparison/ROH_combine.cwl
    in:
      files:  ROH_calc/output1
    out: [output1] 

outputs:
  - id: stats
    type: File
    outputSource: [ROH_combine/output1]
