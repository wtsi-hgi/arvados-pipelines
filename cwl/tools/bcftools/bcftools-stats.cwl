class: CommandLineTool
cwlVersion: v1.0
id: bcftools_stats
baseCommand:
  - bcftools
  - stats
 
inputs:
  input_vcf:
    type: File
    inputBinding:
      position: 1 

  statsfile:
    type: string 
    doc: Output file name of stats file
   

  allele_frequency_bins_list:
    type: string[]?       
    inputBinding:    
      prefix: --af-bins
    doc: comma separated list of allele frequency bins (e.g. 0.1,0.5,1)  

  allele_frequency_bins_file:
    type: File?       
    inputBinding:    
      prefix: --af-bins
    doc: file listing the allele frequency bins one per line (e.g. 0.1\n0.5\n1)

  allele_frequency_tag:
    type: string?       
    inputBinding:    
      prefix: --af-tag
    doc: allele frequency INFO tag to use for binning. By default the allele frequency is estimated from AC/AN, if available, or directly from the genotypes (GT) if not.

  first_allele_only:
    type: boolean?       
    inputBinding:    
      prefix: "-1"
    doc: consider only the 1st alternate allele at multiallelic sites  

  collapse:
    type: string?       
    inputBinding:    
      prefix: -c
    doc: snps|indels|both|all|some|none  See common options.

  depth:
    type: string?       
    inputBinding:    
      prefix: -d
    doc: min, max, size of bin comma separated

  debug:
    type: boolean?       
    inputBinding:    
      prefix: --debug
    doc: produce verbose per-site and per-sample output  

  exclude:
    type: string?      
    inputBinding:    
      prefix: -e
    doc: exclude sites for which EXPRESSION is true. For valid expressions see http://www.htslib.org/doc/bcftools-1.6.html#expressions.

  exons:
    type: File?      
    inputBinding:    
      prefix: -E
    doc: tab-delimited file with exons for indel frameshifts statistics. The columns of the file are CHR, FROM, TO, with 1-based, inclusive, positions. The file is BGZF-compressed and indexed with tabix  

  apply_filters:
    type: string[]?       
    inputBinding:    
      prefix: -f
    doc: Skip sites where FILTER column does not contain any of the strings listed in the input. For example, to include only sites which have no filters set, use -f .,PASS.

  fasta_ref:
    type: File?       
    inputBinding:    
      prefix: -F
    doc: faidx indexed reference sequence file to determine INDEL context    

  exclude:
    type: string?      
    inputBinding:    
      prefix: -e
    doc: include only sites for which expression (the input string) is true. For valid expressions see http://www.htslib.org/doc/bcftools-1.6.html#expressions.


  split_by_ID:
    type: boolean?   
    inputBinding:    
      prefix: -I
    doc: collect stats separately for sites which have the ID column set ("known sites") or which do not have the ID column set ("novel sites").  

  regions:
    type: string?       
    inputBinding:    
      prefix: -r
    doc: Comma-separated list of regions, see also -R, --regions-file. Note that -r cannot be used in combination with -R.  

  regions_file:
    type: File?       
    inputBinding:    
      prefix: -R
    doc: Regions can be specified either on command line or in a VCF, BED, or tab-delimited file (the default).   

  sample_list:
    type: string?       
    inputBinding:    
      prefix: -s 
    doc: Comma-separated list of samples to include or exclude if prefixed with "^". The sample order is updated to reflect that given on the command line.   

  sample_list_file:
    type: File?    
    inputBinding:
      prefix: -S 
    doc: File of sample names to include or exclude if prefixed with "^". One sample per line.  

  targets_chr: 
    type: string?       
    inputBinding:    
      prefix: -t 
    doc:    

  targets_file:
    type: File?    
    inputBinding:
      prefix: -T  
    doc: 

  user_tstv:
    type: string?    
    inputBinding:
      prefix: -u  
    doc: collect Ts/Tv stats for any tag using the given binning [0:1:100] <TAG[:min:max:n]>

  verbose:
    type: string?    
    inputBinding:
        prefix: -v
    doc: produce verbose per-site and per-sample output
   
  
stdout: $(inputs.statsfile)
     
outputs:
  stats:
    type: stdout

requirements:
  - class: DockerRequirement
    dockerPull: 'mercury/bcftools-1.6:v2'
    
doc: |
  About:   wrapper for bcftools 1.6 stats command 
  http://www.htslib.org/doc/bcftools-1.6.html#stats
  
label: bcftools-stats




