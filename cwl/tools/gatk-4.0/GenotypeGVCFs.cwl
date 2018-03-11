id: GenotypeGVCFs
cwlVersion: v1.0
baseCommand:
- python3
- /gatk-local-io-wrapper.py
- '["--variant"]' # input paths to copy to tmpdir before starting GATK
- '[]' # output paths to redirect to tmpdir and copy to output dir after GATK finishes
- '["-Xmx16000m","-Xms16000m"]' # FIXME this is hardcoded as a workaround for arv-mount problems '["-XX:MaxRAMFraction=1","-XX:+UnlockExperimentalVMOptions","-XX:+UseCGroupMemoryLimitForHeap"]' # extra java args
- GenotypeGVCFs # GATK command
class: CommandLineTool
doc: |-
  Perform joint genotyping on one or more samples pre-called with HaplotypeCaller

   <p>
   This tool is designed to perform joint genotyping on a single input, which may contain one or many samples. In any
   case, the input samples must possess genotype likelihoods produced by HaplotypeCaller with `-ERC GVCF` or
   `-ERC BP_RESOLUTION`.


   <h3>Input</h3>
   <p>
   The GATK4 GenotypeGVCFs tool can take only one input track.  Options are 1) a single single-sample GVCF 2) a single
   multi-sample GVCF created by CombineGVCFs or 3) a GenomicsDB workspace created by GenomicsDBImport.
   A sample-level GVCF is produced by HaplotypeCaller with the `-ERC GVCF` setting.
   </p>

   <h3>Output</h3>
   <p>
   A final VCF in which all samples have been jointly genotyped.
   </p>

   <h3>Usage example</h3>

   <h4>Perform joint genotyping on a singular sample by providing a single-sample GVCF or on a cohort by providing a combined multi-sample GVCF</h4>
   <pre>
   gatk --java-options "-Xmx4g" GenotypeGVCFs \
     -R Homo_sapiens_assembly38.fasta \
     -V input.g.vcf.gz \
     -O output.vcf.gz
   </pre>

   <h4>Perform joint genotyping on GenomicsDB workspace created with GenomicsDBImport</h4>
   <pre>
   gatk --java-options "-Xmx4g" GenotypeGVCFs \
     -R Homo_sapiens_assembly38.fasta \
     -V gendb://my_database \
     -O output.vcf.gz
   </pre>

   <h3>Caveats</h3>
   <ul>
     <li>Only GVCF files produced by HaplotypeCaller (or CombineGVCFs) can be used as input for this tool. Some other
   programs produce files that they call GVCFs but those lack some important information (accurate genotype likelihoods
   for every position) that GenotypeGVCFs requires for its operation.</li>
     <li>Cannot take multiple GVCF files in one command.</li>
   </ul>

   <h3>Special note on ploidy</h3>
   <p>This tool is able to handle any ploidy (or mix of ploidies) intelligently; there is no need to specify ploidy
   for non-diploid organisms.</p>
temporaryFailCodes: [3, 250]
requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
  expressionLib:
  - |-
    /**
     * File of functions to be added to cwl files
     */

    function generateGATK4BooleanValue(){
        /**
         * Boolean types in GATK 4 are expressed on the command line as --<PREFIX> "true"/"false",
         * so patch here
         */
        if(self === true || self === false){
            return self.toString()
        }

        return self;
    }

    function addTagToArgument(tagObject, argument, prefix){
        var allTags = Array.isArray(tagObject) ? tagObject.join(",") : tagObject;
        return [prefix + ":" + allTags, argument];
    }

    function applyTagsToArgument(prefix, tags){
        /**
         * Function to be used in the field valueFrom of File objects to add gatk tags.
         */

        if(!self){
            return null;
        }
        else if(!tags){
            return generateArrayCmd(prefix);
        }
        else{
            if(Array.isArray(self)){
                if(!Array.isArray(tags) || self.length !== tags.length){
                    throw new TypeError("Argument '" + prefix + "' tag field is invalid");
                }

                var value = self.map(function(element, i) {
                    return addTagToArgument(tags[i], element);
                }).reduce(function(a, b){return a.concat(b)})

                return value;
            }
            else{
                return addTagToArgument(tags, self);
            }
        }
    }

    function generateArrayCmd(prefix){
        /**
         * Function to be used in the field valueFrom of array objects, so that arrays are optional
         * and prefixes are handled properly.
         *
         * The issue that this solves is documented here:
         * https://www.biostars.org/p/258414/#260140
         */
        if(!self){
            return null;
        }

        if(!Array.isArray(self)){
            self = [self];
        }

        var output = [];
        self.forEach(function(element) {
            output.push(prefix);
            output.push(element);
        })

        return output;
    }
- class: DockerRequirement
  dockerPull: mercury/gatk-4.0.0.0-local-io-wrapper:v4
inputs:
- doc: Reference sequence file
  id: reference
  type: File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--reference", inputs['reference_tags']))
  secondaryFiles:
  - .fai
  - ^.dict
- doc: BAM/SAM/CRAM file containing reads
  id: input
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--input", inputs['input_tags']))
  secondaryFiles: .crai
- doc: Threshold number of ambiguous bases. If null, uses threshold fraction; otherwise,
    overrides threshold fraction.
  id: ambig-filter-bases
  type: int?
  inputBinding:
    prefix: --ambig-filter-bases
- doc: Threshold fraction of ambiguous bases
  id: ambig-filter-frac
  type: double?
  inputBinding:
    prefix: --ambig-filter-frac
- doc: Maximum length of fragment (insert size)
  id: max-fragment-length
  type: int?
  inputBinding:
    prefix: --max-fragment-length
- doc: Name of the library to keep
  id: library
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--library"))
- doc: Maximum mapping quality to keep (inclusive)
  id: maximum-mapping-quality
  type: int?
  inputBinding:
    prefix: --maximum-mapping-quality
- doc: Minimum mapping quality to keep (inclusive)
  id: minimum-mapping-quality
  type: int?
  inputBinding:
    prefix: --minimum-mapping-quality
- doc: Allow a read to be filtered out based on having only 1 soft-clipped block.
    By default, both ends must have a soft-clipped block, setting this flag requires
    only 1 soft-clipped block
  id: dont-require-soft-clips-both-ends
  type: boolean?
  inputBinding:
    prefix: --dont-require-soft-clips-both-ends
    valueFrom: $(generateGATK4BooleanValue())
- doc: Minimum number of aligned bases
  id: filter-too-short
  type: int?
  inputBinding:
    prefix: --filter-too-short
- doc: Platform attribute (PL) to match
  id: platform-filter-name
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--platform-filter-name"))
- doc: Platform unit (PU) to filter out
  id: black-listed-lanes
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--black-listed-lanes"))
- doc: The name of the read group to filter out
  id: read-group-black-list
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--read-group-black-list"))
- doc: The name of the read group to keep
  id: keep-read-group
  type: string?
  inputBinding:
    prefix: --keep-read-group
- doc: Keep only reads with length at most equal to the specified value
  id: max-read-length
  type: int?
  inputBinding:
    prefix: --max-read-length
- doc: Keep only reads with length at least equal to the specified value
  id: min-read-length
  type: int?
  inputBinding:
    prefix: --min-read-length
- doc: Keep only reads with this read name
  id: read-name
  type: string?
  inputBinding:
    prefix: --read-name
- doc: Keep only reads on the reverse strand
  id: keep-reverse-strand-only
  type: boolean?
  inputBinding:
    prefix: --keep-reverse-strand-only
    valueFrom: $(generateGATK4BooleanValue())
- doc: The name of the sample(s) to keep, filtering out all others
  id: sample
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--sample"))
- doc: If true, adds a PG tag to created SAM/BAM/CRAM files.
  id: add-output-sam-program-record
  type: boolean?
  inputBinding:
    prefix: --add-output-sam-program-record
    valueFrom: $(generateGATK4BooleanValue())
- doc: If true, adds a command line header line to created VCF files.
  id: add-output-vcf-command-line
  type: boolean?
  inputBinding:
    prefix: --add-output-vcf-command-line
    valueFrom: $(generateGATK4BooleanValue())
- doc: If provided, we will annotate records with the number of alternate alleles
    that were discovered (but not necessarily genotyped) at a given site
  id: annotate-with-num-discovered-alleles
  type: boolean?
  inputBinding:
    prefix: --annotate-with-num-discovered-alleles
    valueFrom: $(generateGATK4BooleanValue())
- doc: One or more specific annotations to add to variant calls
  id: annotation
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--annotation"))
- doc: One or more groups of annotations to apply to variant calls
  id: annotation-group
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--annotation-group"))
- doc: One or more specific annotations to exclude from variant calls
  id: annotations-to-exclude
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--annotations-to-exclude"))
- doc: read one or more arguments files and add them to the command line
  id: arguments_file
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--arguments_file", inputs['arguments_file_tags']))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'arguments_file'
  id: arguments_file_tags
- doc: Size of the cloud-only prefetch buffer (in MB; 0 to disable). Defaults to cloudPrefetchBuffer
    if unset.
  id: cloud-index-prefetch-buffer
  type: int?
  inputBinding:
    prefix: --cloud-index-prefetch-buffer
- doc: Size of the cloud-only prefetch buffer (in MB; 0 to disable).
  id: cloud-prefetch-buffer
  type: int?
  inputBinding:
    prefix: --cloud-prefetch-buffer
- doc: If true, create a BAM/CRAM index when writing a coordinate-sorted BAM/CRAM
    file.
  id: create-output-bam-index
  type: boolean?
  inputBinding:
    prefix: --create-output-bam-index
    valueFrom: $(generateGATK4BooleanValue())
- doc: If true, create a MD5 digest for any BAM/SAM/CRAM file created
  id: create-output-bam-md5
  type: boolean?
  inputBinding:
    prefix: --create-output-bam-md5
    valueFrom: $(generateGATK4BooleanValue())
- doc: If true, create a VCF index when writing a coordinate-sorted VCF file.
  id: create-output-variant-index
  type: boolean?
  inputBinding:
    prefix: --create-output-variant-index
    valueFrom: $(generateGATK4BooleanValue())
- doc: If true, create a a MD5 digest any VCF file created.
  id: create-output-variant-md5
  type: boolean?
  inputBinding:
    prefix: --create-output-variant-md5
    valueFrom: $(generateGATK4BooleanValue())
- doc: dbSNP file
  id: dbsnp
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--dbsnp", inputs['dbsnp_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'dbsnp'
  id: dbsnp_tags
- doc: If true, don't cache bam indexes, this will reduce memory requirements but
    may harm performance if many intervals are specified.  Caching is automatically
    disabled if there are no intervals specified.
  id: disable-bam-index-caching
  type: boolean?
  inputBinding:
    prefix: --disable-bam-index-caching
    valueFrom: $(generateGATK4BooleanValue())
- doc: Read filters to be disabled before analysis
  id: disable-read-filter
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--disable-read-filter"))
- doc: If specified, do not check the sequence dictionaries from our inputs for compatibility.
    Use at your own risk!
  id: disable-sequence-dictionary-validation
  type: boolean?
  inputBinding:
    prefix: --disable-sequence-dictionary-validation
    valueFrom: $(generateGATK4BooleanValue())
- doc: Disable all tool default read filters
  id: disable-tool-default-read-filters
  type: boolean?
  inputBinding:
    prefix: --disable-tool-default-read-filters
    valueFrom: $(generateGATK4BooleanValue())
- doc: One or more genomic intervals to exclude from processing
  id: exclude-intervals
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--exclude-intervals"))
- doc: A configuration file to use with the GATK.
  id: gatk-config-file
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--gatk-config-file", inputs['gatk-config-file_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'gatk-config-file'
  id: gatk-config-file_tags
- doc: If the GCS bucket channel errors out, how many times it will attempt to re-initiate
    the connection
  id: gcs-max-retries
  type: int?
  inputBinding:
    prefix: --gcs-max-retries
- doc: Heterozygosity value used to compute prior likelihoods for any locus.  See
    the GATKDocs for full details on the meaning of this population genetics concept
  id: heterozygosity
  type: double?
  inputBinding:
    prefix: --heterozygosity
- doc: Standard deviation of eterozygosity for SNP and indel calling.
  id: heterozygosity-stdev
  type: double?
  inputBinding:
    prefix: --heterozygosity-stdev
- doc: Heterozygosity for indel calling.  See the GATKDocs for heterozygosity for
    full details on the meaning of this population genetics concept
  id: indel-heterozygosity
  type: double?
  inputBinding:
    prefix: --indel-heterozygosity
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'input'
  id: input_tags
- doc: Input prior for calls
  id: input-prior
  type:
  - 'null'
  - type: array
    items: double
    inputBinding:
      valueFrom: $(null)
  - double
  inputBinding:
    valueFrom: $(generateArrayCmd("--input-prior"))
- doc: Amount of padding (in bp) to add to each interval you are excluding.
  id: interval-exclusion-padding
  type: int?
  inputBinding:
    prefix: --interval-exclusion-padding
- doc: Interval merging rule for abutting intervals
  id: interval-merging-rule
  type:
  - 'null'
  - type: enum
    symbols:
    - ALL
    - OVERLAPPING_ONLY
  inputBinding:
    prefix: --interval-merging-rule
- doc: Amount of padding (in bp) to add to each interval you are including.
  id: interval-padding
  type: int?
  inputBinding:
    prefix: --interval-padding
- doc: Set merging approach to use for combining interval inputs
  id: interval-set-rule
  type:
  - 'null'
  - type: enum
    symbols:
    - UNION
    - INTERSECTION
  inputBinding:
    prefix: --interval-set-rule
- doc: One or more genomic intervals over which to operate
  id: intervals
  type:
  - 'null'
  - type: array
    items:
    - File
    - string
    inputBinding:
      valueFrom: $(null)
  - File
  - string
  inputBinding:
    valueFrom: $(applyTagsToArgument("--intervals", inputs['intervals_tags']))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'intervals'
  id: intervals_tags
- doc: Lenient processing of VCF files
  id: lenient
  type: boolean?
  inputBinding:
    prefix: --lenient
    valueFrom: $(generateGATK4BooleanValue())
- doc: Maximum number of alternate alleles to genotype
  id: max-alternate-alleles
  type: int?
  inputBinding:
    prefix: --max-alternate-alleles
- doc: Maximum number of genotypes to consider at any site
  id: max-genotype-count
  type: int?
  inputBinding:
    prefix: --max-genotype-count
- doc: Restrict variant output to sites that start within provided intervals
  id: only-output-calls-starting-in-intervals
  type: boolean?
  inputBinding:
    prefix: --only-output-calls-starting-in-intervals
    valueFrom: $(generateGATK4BooleanValue())
- doc: File to which variants should be written
  id: output-filename
  type: string
  inputBinding:
    prefix: --output
- doc: Whether to suppress job-summary info on System.err.
  id: QUIET
  type: boolean?
  inputBinding:
    prefix: --QUIET
    valueFrom: $(generateGATK4BooleanValue())
- doc: Read filters to be applied before analysis
  id: read-filter
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--read-filter"))
- doc: Indices to use for the read inputs. If specified, an index must be provided
    for every read input and in the same order as the read inputs. If this argument
    is not specified, the path to the index for each input will be inferred automatically.
  id: read-index
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--read-index"))
- doc: Validation stringency for all SAM/BAM/CRAM/SRA files read by this program.  The
    default stringency value SILENT can improve performance when processing a BAM
    file in which variable-length data (read, qualities, tags) do not otherwise need
    to be decoded.
  id: read-validation-stringency
  type:
  - 'null'
  - type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  inputBinding:
    prefix: --read-validation-stringency
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'reference'
  id: reference_tags
- doc: Ploidy (number of chromosomes) per sample. For pooled data, set to (Number
    of samples in each pool * Sample Ploidy).
  id: sample-ploidy
  type: int?
  inputBinding:
    prefix: --sample-ploidy
- doc: Output traversal statistics every time this many seconds elapse
  id: seconds-between-progress-updates
  type: double?
  inputBinding:
    prefix: --seconds-between-progress-updates
- doc: Use the given sequence dictionary as the master/canonical sequence dictionary.  Must
    be a .dict file.
  id: sequence-dictionary
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--sequence-dictionary", inputs['sequence-dictionary_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'sequence-dictionary'
  id: sequence-dictionary_tags
- doc: display hidden arguments
  id: showHidden
  type: boolean?
  inputBinding:
    prefix: --showHidden
    valueFrom: $(generateGATK4BooleanValue())
- doc: The minimum phred-scaled confidence threshold at which variants should be called
  id: standard-min-confidence-threshold-for-calling
  type: double?
  inputBinding:
    prefix: --standard-min-confidence-threshold-for-calling
- doc: Undocumented option
  id: TMP_DIR
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--TMP_DIR", inputs['TMP_DIR_tags']))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'TMP_DIR'
  id: TMP_DIR_tags
- doc: Whether to use the JdkDeflater (as opposed to IntelDeflater)
  id: use-jdk-deflater
  type: boolean?
  inputBinding:
    prefix: --use-jdk-deflater
    valueFrom: $(generateGATK4BooleanValue())
- doc: Whether to use the JdkInflater (as opposed to IntelInflater)
  id: use-jdk-inflater
  type: boolean?
  inputBinding:
    prefix: --use-jdk-inflater
    valueFrom: $(generateGATK4BooleanValue())
- doc: If provided, we will use the new AF model instead of the so-called exact model
  id: use-new-qual-calculator
  type: boolean?
  inputBinding:
    prefix: --use-new-qual-calculator
    valueFrom: $(generateGATK4BooleanValue())
- doc: A VCF file containing variants
  id: variant
  type:
  - File
  - Directory
  inputBinding:
    prefix: --variant
    valueFrom: ${if(self.class=="File"){return self.path;} else {return "gendb://"+self.path;}}
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'variant'
  id: variant_tags
- doc: Control verbosity of logging.
  id: verbosity
  type:
  - 'null'
  - type: enum
    symbols:
    - ERROR
    - WARNING
    - INFO
    - DEBUG
  inputBinding:
    prefix: --verbosity
- doc: display the version number for this tool
  id: version
  type: boolean?
  inputBinding:
    prefix: --version
    valueFrom: $(generateGATK4BooleanValue())
outputs:
- id: bam-index
  doc: index file generated if create-output-bam-index is true
  type: File?
  outputBinding:
    glob:
    - $(inputs['output-filename']).idx
    - $(inputs['output-filename']).tbi
- id: bam-md5
  doc: md5 file generated if create-output-bam-md5 is true
  type: File?
  outputBinding:
    glob: $(inputs['output-filename']).md5
- id: variant-index
  doc: index file generated if create-output-variant-index is true
  type: File?
  outputBinding:
    glob:
    - $(inputs['output-filename']).idx
    - $(inputs['output-filename']).tbi
- id: variant-md5
  doc: md5 file generated if create-output-variant-md5 is true
  type: File?
  outputBinding:
    glob: $(inputs['output-filename']).md5
- id: output
  doc: Output file corresponding to the input argument output-filename
  type: File
  outputBinding:
    glob: $(inputs['output-filename'])
