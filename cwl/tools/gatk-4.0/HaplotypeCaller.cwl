id: HaplotypeCaller
cwlVersion: v1.0
baseCommand:
- python3
- /gatk-local-io-wrapper.py
- '[]' # input paths to copy to tmpdir before starting GATK
- '[]' # output paths to redirect to tmpdir and copy to output dir after GATK finishes
- '["-XX:MaxRAMFraction=1","-XX:+UnlockExperimentalVMOptions","-XX:+UseCGroupMemoryLimitForHeap"]' # extra java args
- HaplotypeCaller # GATK Command
class: CommandLineTool
doc: |-
  Call germline SNPs and indels via local re-assembly of haplotypes

   <p>The HaplotypeCaller is capable of calling SNPs and indels simultaneously via local de-novo assembly of haplotypes in an active region. In other words, whenever the program encounters a region showing signs of variation, it discards the existing mapping information and completely reassembles the reads in that region. This allows the HaplotypeCaller to be more accurate when calling regions that are traditionally difficult to call, for example when they contain different types of variants close to each other. It also makes the HaplotypeCaller much better at calling indels than position-based callers like UnifiedGenotyper.</p>

   <p>In the GVCF workflow used for scalable variant calling in DNA sequence data, HaplotypeCaller runs per-sample to generate an intermediate GVCF (not to be used in final analysis), which can then be used in GenotypeGVCFs for joint genotyping of multiple samples in a very efficient way. The GVCF workflow enables rapid incremental processing of samples as they roll off the sequencer, as well as scaling to very large cohort sizes (e.g. the 92K exomes of ExAC).</p>

   <p>In addition, HaplotypeCaller is able to handle non-diploid organisms as well as pooled experiment data. Note however that the algorithms used to calculate variant likelihoods is not well suited to extreme allele frequencies (relative to ploidy) so its use is not recommended for somatic (cancer) variant discovery. For that purpose, use Mutect2 instead.</p>

   <p>Finally, HaplotypeCaller is also able to correctly handle the splice junctions that make RNAseq a challenge for most variant callers,
   on the condition that the input read data has previously been processed according to our recommendations as documented <a href='https://software.broadinstitute.org/gatk/documentation/article?id=4067'>here</a>.</p>

   <h3>How HaplotypeCaller works</h3>

   <br />
   <h4><a href='https://software.broadinstitute.org/gatk/documentation/article?id=4147'>1. Define active regions </a></h4>

   <p>The program determines which regions of the genome it needs to operate on (active regions), based on the presence of
   evidence for variation.

   <br />
   <h4><a href='https://software.broadinstitute.org/gatk/documentation/article?id=4146'>2. Determine haplotypes by assembly of the active region </a></h4>

   <p>For each active region, the program builds a De Bruijn-like graph to reassemble the active region and identifies
   what are the possible haplotypes present in the data. The program then realigns each haplotype against the reference
   haplotype using the Smith-Waterman algorithm in order to identify potentially variant sites. </p>

   <br />
   <h4><a href='https://software.broadinstitute.org/gatk/documentation/article?id=4441'>3. Determine likelihoods of the haplotypes given the read data </a></h4>

   <p>For each active region, the program performs a pairwise alignment of each read against each haplotype using the
   PairHMM algorithm. This produces a matrix of likelihoods of haplotypes given the read data. These likelihoods are
   then marginalized to obtain the likelihoods of alleles for each potentially variant site given the read data.   </p>

   <br />
   <h4><a href='https://software.broadinstitute.org/gatk/documentation/article?id=4442'>4. Assign sample genotypes </a></h4>

   <p>For each potentially variant site, the program applies Bayes' rule, using the likelihoods of alleles given the
   read data to calculate the likelihoods of each genotype per sample given the read data observed for that
   sample. The most likely genotype is then assigned to the sample.    </p>

   <h3>Input</h3>
   <p>
   Input bam file(s) from which to make variant calls
   </p>

   <h3>Output</h3>
   <p>
   Either a VCF or GVCF file with raw, unfiltered SNP and indel calls. Regular VCFs must be filtered either by variant
   recalibration (Best Practice) or hard-filtering before use in downstream analyses. If using the GVCF workflow, the
   output is a GVCF file that must first be run through GenotypeGVCFs and then filtering before further analysis.
   </p>

   <h3>Usage examples</h3>

   <p>These are example commands that show how to run HaplotypeCaller for typical use cases. Have a look at the <a href='https://software.broadinstitute.org/gatk/documentation/article?id=3893'>method documentation</a> for the basic GVCF workflow. </p>

   <br />
   <h4>Single-sample GVCF calling (outputs intermediate GVCF)</h4>
   <pre>
   gatk --java-options "-Xmx4g" HaplotypeCaller  \
     -R Homo_sapiens_assembly38.fasta \
     -I input.bam \
     -O output.g.vcf.gz \
     -ERC GVCF
   </pre>

   <h4>Single-sample GVCF calling with <a href='https://software.broadinstitute.org/gatk/documentation/article?id=9622'>allele-specific annotations</a></h4>
   <pre>
   gatk --java-options "-Xmx4g" HaplotypeCaller  \
     -R Homo_sapiens_assembly38.fasta \
     -I input.bam \
     -O output.g.vcf.gz \
     -ERC GVCF \
     -G Standard \
     -G AS_Standard
   </pre>

   <h4>Variant calling with <a href='https://software.broadinstitute.org/gatk/documentation/article?id=5484'>bamout</a> to show realigned reads</h4>
   <pre>
   gatk --java-options "-Xmx4g" HaplotypeCaller  \
     -R Homo_sapiens_assembly38.fasta \
     -I input.bam \
     -O output.vcf.gz \
     -bamout bamout.bam
   </pre>

   <h3>Caveats</h3>
   <ul>
   <li>We have not yet fully tested the interaction between the GVCF-based calling or the multisample calling and the
   RNAseq-specific functionalities. Use those in combination at your own risk.</li>
   </ul>

   <h3>Special note on ploidy</h3>
   <p>This tool is able to handle many non-diploid use cases; the desired ploidy can be specified using the -ploidy
   argument. Note however that very high ploidies (such as are encountered in large pooled experiments) may cause
   performance challenges including excessive slowness. We are working on resolving these limitations.</p>

   <h3>Additional Notes</h3>
   <ul>
       <li>When working with PCR-free data, be sure to set `-pcr_indel_model NONE` (see argument below).</li>
       <li>When running in `-ERC GVCF` or `-ERC BP_RESOLUTION` modes, the confidence threshold
       is automatically set to 0. This cannot be overridden by the command line. The threshold can be set manually
       to the desired level in the next step of the workflow (GenotypeGVCFs)</li>
       <li>We recommend using a list of intervals to speed up analysis. See <a href='https://software.broadinstitute.org/gatk/documentation/article?id=4133'>this document</a> for details.</li>
   </ul>
temporaryFailCodes: [3]
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
                    return addTagToArgument(tags[i], element, prefix);
                }).reduce(function(a, b){return a.concat(b)})

                return value;
            }
            else{
                return addTagToArgument(tags, self, prefix);
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
- doc: Minimum probability for a locus to be considered active.
  id: active-probability-threshold
  type: double?
  inputBinding:
    prefix: --active-probability-threshold
- doc: Output the raw activity profile results in IGV format
  id: activity-profile-out-filename
  type: string?
  inputBinding:
    prefix: --activity-profile-out
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
- doc: Annotate all sites with PLs
  id: all-site-pls
  type: boolean?
  inputBinding:
    prefix: --all-site-pls
    valueFrom: $(generateGATK4BooleanValue())
- doc: The set of alleles at which to genotype when --genotyping_mode is GENOTYPE_GIVEN_ALLELES
  id: alleles
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--alleles", inputs['alleles_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'alleles'
  id: alleles_tags
- doc: Allow graphs that have non-unique kmers in the reference
  id: allow-non-unique-kmers-in-ref
  type: boolean?
  inputBinding:
    prefix: --allow-non-unique-kmers-in-ref
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
- doc: Output the assembly region to this IGV formatted file
  id: assembly-region-out-filename
  type: string?
  inputBinding:
    prefix: --assembly-region-out
- doc: Number of additional bases of context to include around each assembly region
  id: assembly-region-padding
  type: int?
  inputBinding:
    prefix: --assembly-region-padding
- doc: File to which assembled haplotypes should be written
  id: bam-output-filename
  type: string?
  inputBinding:
    prefix: --bam-output
- doc: Which haplotypes should be written to the BAM
  id: bam-writer-type
  type:
  - 'null'
  - type: enum
    symbols:
    - ALL_POSSIBLE_HAPLOTYPES
    - CALLED_HAPLOTYPES
  inputBinding:
    prefix: --bam-writer-type
- doc: Base qualities below this threshold will be reduced to the minimum (6)
  id: base-quality-score-threshold
  type: int?
  inputBinding:
    prefix: --base-quality-score-threshold
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
- doc: Comparison VCF file(s)
  id: comp
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--comp", inputs['comp_tags']))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'comp'
  id: comp_tags
- doc: 1000G consensus mode
  id: consensus
  type: boolean?
  inputBinding:
    prefix: --consensus
    valueFrom: $(generateGATK4BooleanValue())
- doc: Tab-separated File containing fraction of contamination in sequencing data
    (per sample) to aggressively remove. Format should be "<SampleID><TAB><Contamination>"
    (Contamination is double) per line; No header.
  id: contamination-fraction-per-sample-file
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--contamination-fraction-per-sample-file", inputs['contamination-fraction-per-sample-file_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'contamination-fraction-per-sample-file'
  id: contamination-fraction-per-sample-file_tags
- doc: Fraction of contamination in sequencing data (for all samples) to aggressively
    remove
  id: contamination-fraction-to-filter
  type: double?
  inputBinding:
    prefix: --contamination-fraction-to-filter
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
- doc: Print out very verbose debug information about each triggering active region
  id: debug
  type: boolean?
  inputBinding:
    prefix: --debug
    valueFrom: $(generateGATK4BooleanValue())
- doc: If true, don't cache bam indexes, this will reduce memory requirements but
    may harm performance if many intervals are specified.  Caching is automatically
    disabled if there are no intervals specified.
  id: disable-bam-index-caching
  type: boolean?
  inputBinding:
    prefix: --disable-bam-index-caching
    valueFrom: $(generateGATK4BooleanValue())
- doc: Don't skip calculations in ActiveRegions with no variants
  id: disable-optimizations
  type: boolean?
  inputBinding:
    prefix: --disable-optimizations
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
- doc: Disable physical phasing
  id: do-not-run-physical-phasing
  type: boolean?
  inputBinding:
    prefix: --do-not-run-physical-phasing
    valueFrom: $(generateGATK4BooleanValue())
- doc: Disable iterating over kmer sizes when graph cycles are detected
  id: dont-increase-kmer-sizes-for-cycles
  type: boolean?
  inputBinding:
    prefix: --dont-increase-kmer-sizes-for-cycles
    valueFrom: $(generateGATK4BooleanValue())
- doc: If specified, we will not trim down the active region from the full region
    (active + extension) to just the active interval for genotyping
  id: dont-trim-active-regions
  type: boolean?
  inputBinding:
    prefix: --dont-trim-active-regions
    valueFrom: $(generateGATK4BooleanValue())
- doc: Do not analyze soft clipped bases in the reads
  id: dont-use-soft-clipped-bases
  type: boolean?
  inputBinding:
    prefix: --dont-use-soft-clipped-bases
    valueFrom: $(generateGATK4BooleanValue())
- doc: Mode for emitting reference confidence scores
  id: emit-ref-confidence
  type:
  - 'null'
  - type: enum
    symbols:
    - NONE
    - BP_RESOLUTION
    - GVCF
  inputBinding:
    prefix: --emit-ref-confidence
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
- doc: Specifies how to determine the alternate alleles to use for genotyping
  id: genotyping-mode
  type:
  - 'null'
  - type: enum
    symbols:
    - DISCOVERY
    - GENOTYPE_GIVEN_ALLELES
  inputBinding:
    prefix: --genotyping-mode
- doc: Write debug assembly graph information to this file
  id: graph-output-filename
  type: string?
  inputBinding:
    prefix: --graph-output
- doc: Exclusive upper bounds for reference confidence GQ bands (must be in [1, 100]
    and specified in increasing order)
  id: gvcf-gq-bands
  type:
  - 'null'
  - type: array
    items: int
    inputBinding:
      valueFrom: $(null)
  - int
  inputBinding:
    valueFrom: $(generateArrayCmd("--gvcf-gq-bands"))
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
- doc: The size of an indel to check for in the reference model
  id: indel-size-to-eliminate-in-ref-model
  type: int?
  inputBinding:
    prefix: --indel-size-to-eliminate-in-ref-model
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
- doc: Kmer size to use in the read threading assembler
  id: kmer-size
  type:
  - 'null'
  - type: array
    items: int
    inputBinding:
      valueFrom: $(null)
  - int
  inputBinding:
    valueFrom: $(generateArrayCmd("--kmer-size"))
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
- doc: Maximum size of an assembly region
  id: max-assembly-region-size
  type: int?
  inputBinding:
    prefix: --max-assembly-region-size
- doc: Maximum number of genotypes to consider at any site
  id: max-genotype-count
  type: int?
  inputBinding:
    prefix: --max-genotype-count
- doc: Maximum number of haplotypes to consider for your population
  id: max-num-haplotypes-in-population
  type: int?
  inputBinding:
    prefix: --max-num-haplotypes-in-population
- doc: Upper limit on how many bases away probability mass can be moved around when
    calculating the boundaries between active and inactive assembly regions
  id: max-prob-propagation-distance
  type: int?
  inputBinding:
    prefix: --max-prob-propagation-distance
- doc: Maximum number of reads to retain per alignment start position. Reads above
    this threshold will be downsampled. Set to 0 to disable.
  id: max-reads-per-alignment-start
  type: int?
  inputBinding:
    prefix: --max-reads-per-alignment-start
- doc: Minimum size of an assembly region
  id: min-assembly-region-size
  type: int?
  inputBinding:
    prefix: --min-assembly-region-size
- doc: Minimum base quality required to consider a base for calling
  id: min-base-quality-score
  type: int?
  inputBinding:
    prefix: --min-base-quality-score
- doc: Minimum length of a dangling branch to attempt recovery
  id: min-dangling-branch-length
  type: int?
  inputBinding:
    prefix: --min-dangling-branch-length
- doc: Minimum support to not prune paths in the graph
  id: min-pruning
  type: int?
  inputBinding:
    prefix: --min-pruning
- doc: How many threads should a native pairHMM implementation use
  id: native-pair-hmm-threads
  type: int?
  inputBinding:
    prefix: --native-pair-hmm-threads
- doc: use double precision in the native pairHmm. This is slower but matches the
    java implementation better
  id: native-pair-hmm-use-double-precision
  type: boolean?
  inputBinding:
    prefix: --native-pair-hmm-use-double-precision
    valueFrom: $(generateGATK4BooleanValue())
- doc: Number of samples that must pass the minPruning threshold
  id: num-pruning-samples
  type: int?
  inputBinding:
    prefix: --num-pruning-samples
- doc: File to which variants should be written
  id: output-filename
  type: string
  inputBinding:
    prefix: --output
- doc: Specifies which type of calls we should output
  id: output-mode
  type:
  - 'null'
  - type: enum
    symbols:
    - EMIT_VARIANTS_ONLY
    - EMIT_ALL_CONFIDENT_SITES
    - EMIT_ALL_SITES
  inputBinding:
    prefix: --output-mode
- doc: Flat gap continuation penalty for use in the Pair HMM
  id: pair-hmm-gap-continuation-penalty
  type: int?
  inputBinding:
    prefix: --pair-hmm-gap-continuation-penalty
- doc: The PCR indel model to use
  id: pcr-indel-model
  type:
  - 'null'
  - type: enum
    symbols:
    - NONE
    - HOSTILE
    - AGGRESSIVE
    - CONSERVATIVE
  inputBinding:
    prefix: --pcr-indel-model
- doc: The global assumed mismapping rate for reads
  id: phred-scaled-global-read-mismapping-rate
  type: int?
  inputBinding:
    prefix: --phred-scaled-global-read-mismapping-rate
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
- doc: This argument is deprecated since version 3.3
  id: recover-dangling-heads
  type: boolean?
  inputBinding:
    prefix: --recover-dangling-heads
    valueFrom: $(generateGATK4BooleanValue())
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'reference'
  id: reference_tags
- doc: Name of single sample to use from a multi-sample bam
  id: sample-name
  type: string?
  inputBinding:
    prefix: --sample-name
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
- doc: Which Smith-Waterman implementation to use, generally FASTEST_AVAILABLE is
    the right choice
  id: smith-waterman
  type:
  - 'null'
  - type: enum
    symbols:
    - FASTEST_AVAILABLE
    - AVX_ENABLED
    - JAVA
  inputBinding:
    prefix: --smith-waterman
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
- doc: Use additional trigger on variants found in an external alleles file
  id: use-alleles-trigger
  type: boolean?
  inputBinding:
    prefix: --use-alleles-trigger
    valueFrom: $(generateGATK4BooleanValue())
- doc: Use the contamination-filtered read maps for the purposes of annotating variants
  id: use-filtered-reads-for-annotations
  type: boolean?
  inputBinding:
    prefix: --use-filtered-reads-for-annotations
    valueFrom: $(generateGATK4BooleanValue())
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
- id: activity-profile-out
  doc: Output file from corresponding to the input argument activity-profile-out-filename
  type: File?
  outputBinding:
    glob: $(inputs['activity-profile-out-filename'])
- id: assembly-region-out
  doc: Output file from corresponding to the input argument assembly-region-out-filename
  type: File?
  outputBinding:
    glob: $(inputs['assembly-region-out-filename'])
- id: bam-output
  doc: Output file from corresponding to the input argument bam-output-filename
  type: File?
  outputBinding:
    glob: $(inputs['bam-output-filename'])
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
- id: graph-output
  doc: Output file from corresponding to the input argument graph-output-filename
  type: File?
  outputBinding:
    glob: $(inputs['graph-output-filename'])
- id: output
  doc: Output file from corresponding to the input argument output-filename
  type: File
  outputBinding:
    glob: $(inputs['output-filename'])
