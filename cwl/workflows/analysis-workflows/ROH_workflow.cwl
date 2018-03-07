cwlVersion: v1.0
class: Workflow

# input the script, the array of sample files and a multisample vcf and scatter 
# the ROH calculations then combine the results (vcf, sample, hets in ROH, all hets, 
# tab separated) to a single output file

requirements:
  - class: ScatterFeatureRequirement


inputs:
  - id: script
    type: File
  - id: ROH_beds
    type: File[]
  - id: vcf_file
    type: File
    
steps:

  - id: ROH_calc
    scatter:
      - filein_ROH      
    run: ROH_comparison.cwl
    in:
      script: script
      filein_ROH: ROH_beds
      filein_VCF: vcf_file          
    out: [output]

  - id: ROH_combine
    run: ROH_combine.cwl
    in:
      files:  ROH_calc/output
    out: [stats] 

outputs:
  - id: stats
    type: File
    outputSource: [ROH_combine/stats]
