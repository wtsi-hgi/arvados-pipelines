id: HaplotypeCaller
cwlVersion: v1.0
baseCommand:
- java
- -d64
- -jar
- /usr/GenomeAnalysisTK.jar
- --analysis_type
- HaplotypeCaller
class: CommandLineTool
requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
  expressionLib:
  - |-
    /**
     * File of functions to be added to cwl files
     */
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
            function addTagToArgument(tagObject, argument){
                var allTags = Array.isArray(tagObject) ? tagObject.join(",") : tagObject;

                return [prefix + ":" + allTags, argument];
            }

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
  dockerPull: broadinstitute/gatk3:3.8-0
inputs:
- doc: Reference sequence file
  id: reference_sequence
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--reference_sequence", inputs.reference_sequence_tags))
  secondaryFiles:
  - .fai
  - ^.dict
- doc: Input file containing sequence data (BAM or CRAM)
  id: input_file
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--input_file", inputs.input_file_tags))
  secondaryFiles: $(self.basename + self.nameext.replace('m','i'))
- doc: Threshold for the probability of a profile state being active.
  id: activeProbabilityThreshold
  type: double?
  inputBinding:
    prefix: --activeProbabilityThreshold
- doc: The active region extension; if not provided defaults to Walker annotated default
  id: activeRegionExtension
  type: int?
  inputBinding:
    prefix: --activeRegionExtension
- doc: Use this interval list file as the active regions to process
  id: activeRegionIn
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
    valueFrom: $(applyTagsToArgument("--activeRegionIn", inputs.activeRegionIn_tags))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'activeRegionIn'
  id: activeRegionIn_tags
- doc: The active region maximum size; if not provided defaults to Walker annotated
    default
  id: activeRegionMaxSize
  type: int?
  inputBinding:
    prefix: --activeRegionMaxSize
- doc: Output the active region to this IGV formatted file
  id: activeRegionOut
  type: string?
  inputBinding:
    prefix: --activeRegionOut
- doc: Output the raw activity profile results in IGV format
  id: activityProfileOut
  type: string?
  inputBinding:
    prefix: --activityProfileOut
- doc: Set of alleles to use in genotyping
  id: alleles
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--alleles", inputs.alleles_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'alleles'
  id: alleles_tags
- doc: Allow graphs that have non-unique kmers in the reference
  id: allowNonUniqueKmersInRef
  type: boolean?
  inputBinding:
    prefix: --allowNonUniqueKmersInRef
- doc: Annotate all sites with PLs
  id: allSitePLs
  type: boolean?
  inputBinding:
    prefix: --allSitePLs
- doc: Annotate number of alleles observed
  id: annotateNDA
  type: boolean?
  inputBinding:
    prefix: --annotateNDA
- doc: One or more specific annotations to apply to variant calls
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
- doc: File to which assembled haplotypes should be written
  id: bamOutput
  type: string?
  inputBinding:
    prefix: --bamOutput
- doc: Which haplotypes should be written to the BAM
  id: bamWriterType
  type:
  - 'null'
  - type: enum
    symbols:
    - ALL_POSSIBLE_HAPLOTYPES
    - CALLED_HAPLOTYPES
  inputBinding:
    prefix: --bamWriterType
- doc: The sigma of the band pass filter Gaussian kernel; if not provided defaults
    to Walker annotated default
  id: bandPassSigma
  type: double?
  inputBinding:
    prefix: --bandPassSigma
- doc: Comparison VCF file
  id: comp
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--comp", inputs.comp_tags))
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
- doc: Contamination per sample
  id: contamination_fraction_per_sample_file
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--contamination_fraction_per_sample_file", inputs.contamination_fraction_per_sample_file_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'contamination_fraction_per_sample_file'
  id: contamination_fraction_per_sample_file_tags
- doc: Fraction of contamination to aggressively remove
  id: contamination_fraction_to_filter
  type: double?
  inputBinding:
    prefix: --contamination_fraction_to_filter
- doc: dbSNP file
  id: dbsnp
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--dbsnp", inputs.dbsnp_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'dbsnp'
  id: dbsnp_tags
- doc: Print out very verbose debug information about each triggering active region
  id: debug
  type: boolean?
  inputBinding:
    prefix: --debug
- doc: Don't skip calculations in ActiveRegions with no variants
  id: disableOptimizations
  type: boolean?
  inputBinding:
    prefix: --disableOptimizations
- doc: Disable physical phasing
  id: doNotRunPhysicalPhasing
  type: boolean?
  inputBinding:
    prefix: --doNotRunPhysicalPhasing
- doc: Disable iterating over kmer sizes when graph cycles are detected
  id: dontIncreaseKmerSizesForCycles
  type: boolean?
  inputBinding:
    prefix: --dontIncreaseKmerSizesForCycles
- doc: If specified, we will not trim down the active region from the full region
    (active + extension) to just the active interval for genotyping
  id: dontTrimActiveRegions
  type: boolean?
  inputBinding:
    prefix: --dontTrimActiveRegions
- doc: Do not analyze soft clipped bases in the reads
  id: dontUseSoftClippedBases
  type: boolean?
  inputBinding:
    prefix: --dontUseSoftClippedBases
- doc: Emit reads that are dropped for filtering, trimming, realignment failure
  id: emitDroppedReads
  type: boolean?
  inputBinding:
    prefix: --emitDroppedReads
- doc: Mode for emitting reference confidence scores
  id: emitRefConfidence
  type:
  - 'null'
  - type: enum
    symbols:
    - NONE
    - BP_RESOLUTION
    - GVCF
  inputBinding:
    prefix: --emitRefConfidence
- doc: One or more specific annotations to exclude
  id: excludeAnnotation
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--excludeAnnotation"))
- doc: If provided, all bases will be tagged as active
  id: forceActive
  type: boolean?
  inputBinding:
    prefix: --forceActive
- doc: Flat gap continuation penalty for use in the Pair HMM
  id: gcpHMM
  type: int?
  inputBinding:
    prefix: --gcpHMM
- doc: Specifies how to determine the alternate alleles to use for genotyping
  id: genotyping_mode
  type:
  - 'null'
  - type: enum
    symbols:
    - DISCOVERY
    - GENOTYPE_GIVEN_ALLELES
  inputBinding:
    prefix: --genotyping_mode
- doc: Write debug assembly graph information to this file
  id: graphOutput
  type: string?
  inputBinding:
    prefix: --graphOutput
- doc: One or more classes/groups of annotations to apply to variant calls
  id: group
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--group"))
- doc: Exclusive upper bounds for reference confidence GQ bands (must be in [1, 100]
    and specified in increasing order)
  id: GVCFGQBands
  type:
  - 'null'
  - type: array
    items: int
    inputBinding:
      valueFrom: $(null)
  - int
  inputBinding:
    valueFrom: $(generateArrayCmd("--GVCFGQBands"))
- doc: Heterozygosity value used to compute prior likelihoods for any locus
  id: heterozygosity
  type: double?
  inputBinding:
    prefix: --heterozygosity
- doc: Standard deviation of eterozygosity for SNP and indel calling.
  id: heterozygosity_stdev
  type: double?
  inputBinding:
    prefix: --heterozygosity_stdev
- doc: Heterozygosity for indel calling
  id: indel_heterozygosity
  type: double?
  inputBinding:
    prefix: --indel_heterozygosity
- doc: The size of an indel to check for in the reference model
  id: indelSizeToEliminateInRefModel
  type: int?
  inputBinding:
    prefix: --indelSizeToEliminateInRefModel
- doc: Input prior for calls
  id: input_prior
  type:
  - 'null'
  - type: array
    items: double
    inputBinding:
      valueFrom: $(null)
  - double
  inputBinding:
    valueFrom: $(generateArrayCmd("--input_prior"))
- doc: Kmer size to use in the read threading assembler
  id: kmerSize
  type:
  - 'null'
  - type: array
    items: int
    inputBinding:
      valueFrom: $(null)
  - int
  inputBinding:
    valueFrom: $(generateArrayCmd("--kmerSize"))
- doc: Maximum number of alternate alleles to genotype
  id: max_alternate_alleles
  type: int?
  inputBinding:
    prefix: --max_alternate_alleles
- doc: Maximum number of genotypes to consider at any site
  id: max_genotype_count
  type: int?
  inputBinding:
    prefix: --max_genotype_count
- doc: Maximum number of PL values to output
  id: max_num_PL_values
  type: int?
  inputBinding:
    prefix: --max_num_PL_values
- doc: Maximum number of haplotypes to consider for your population
  id: maxNumHaplotypesInPopulation
  type: int?
  inputBinding:
    prefix: --maxNumHaplotypesInPopulation
- doc: Maximum reads per sample given to traversal map() function
  id: maxReadsInMemoryPerSample
  type: int?
  inputBinding:
    prefix: --maxReadsInMemoryPerSample
- doc: Maximum reads in an active region
  id: maxReadsInRegionPerSample
  type: int?
  inputBinding:
    prefix: --maxReadsInRegionPerSample
- doc: Maximum total reads given to traversal map() function
  id: maxTotalReadsInMemory
  type: int?
  inputBinding:
    prefix: --maxTotalReadsInMemory
- doc: Minimum base quality required to consider a base for calling
  id: min_base_quality_score
  type: int?
  inputBinding:
    prefix: --min_base_quality_score
- doc: Minimum length of a dangling branch to attempt recovery
  id: minDanglingBranchLength
  type: int?
  inputBinding:
    prefix: --minDanglingBranchLength
- doc: Minimum support to not prune paths in the graph
  id: minPruning
  type: int?
  inputBinding:
    prefix: --minPruning
- doc: Minimum number of reads sharing the same alignment start for each genomic location
    in an active region
  id: minReadsPerAlignmentStart
  type: int?
  inputBinding:
    prefix: --minReadsPerAlignmentStart
- doc: Number of samples that must pass the minPruning threshold
  id: numPruningSamples
  type: int?
  inputBinding:
    prefix: --numPruningSamples
- doc: File to which variants should be written
  id: out
  type: string?
  inputBinding:
    prefix: --out
  default: out.vcf.gz
- doc: Which type of calls we should output
  id: output_mode
  type:
  - 'null'
  - type: enum
    symbols:
    - EMIT_VARIANTS_ONLY
    - EMIT_ALL_CONFIDENT_SITES
    - EMIT_ALL_SITES
  inputBinding:
    prefix: --output_mode
- doc: The PCR indel model to use
  id: pcr_indel_model
  type:
  - 'null'
  - type: enum
    symbols:
    - NONE
    - HOSTILE
    - AGGRESSIVE
    - CONSERVATIVE
  inputBinding:
    prefix: --pcr_indel_model
- doc: The global assumed mismapping rate for reads
  id: phredScaledGlobalReadMismappingRate
  type: int?
  inputBinding:
    prefix: --phredScaledGlobalReadMismappingRate
- doc: Name of single sample to use from a multi-sample bam
  id: sample_name
  type: string?
  inputBinding:
    prefix: --sample_name
- doc: Ploidy per sample. For pooled data, set to (Number of samples in each pool
    * Sample Ploidy).
  id: sample_ploidy
  type: int?
  inputBinding:
    prefix: --sample_ploidy
- doc: The minimum phred-scaled confidence threshold at which variants should be called
  id: standard_min_confidence_threshold_for_calling
  type: double?
  inputBinding:
    prefix: --standard_min_confidence_threshold_for_calling
- doc: Use additional trigger on variants found in an external alleles file
  id: useAllelesTrigger
  type: boolean?
  inputBinding:
    prefix: --useAllelesTrigger
- doc: Use the contamination-filtered read maps for the purposes of annotating variants
  id: useFilteredReadsForAnnotations
  type: boolean?
  inputBinding:
    prefix: --useFilteredReadsForAnnotations
- doc: Use new AF model instead of the so-called exact model
  id: useNewAFCalculator
  type: boolean?
  inputBinding:
    prefix: --useNewAFCalculator
- doc: Ignore warnings about base quality score encoding
  id: allow_potentially_misencoded_quality_scores
  type: boolean?
  inputBinding:
    prefix: --allow_potentially_misencoded_quality_scores
- doc: Compression level to use for writing BAM files (0 - 9, higher is more compressed)
  id: bam_compression
  type: int?
  inputBinding:
    prefix: --bam_compression
- doc: Type of BAQ calculation to apply in the engine
  id: baq
  type:
  - 'null'
  - type: enum
    symbols:
    - OFF
    - CALCULATE_AS_NECESSARY
    - RECALCULATE
  inputBinding:
    prefix: --baq
- doc: BAQ gap open penalty
  id: baqGapOpenPenalty
  type: double?
  inputBinding:
    prefix: --baqGapOpenPenalty
- doc: Input covariates table file for on-the-fly base quality score recalibration
  id: BQSR
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--BQSR", inputs.BQSR_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'BQSR'
  id: BQSR_tags
- doc: Disable both auto-generation of index files and index file locking
  id: disable_auto_index_creation_and_locking_when_reading_rods
  type: boolean?
  inputBinding:
    prefix: --disable_auto_index_creation_and_locking_when_reading_rods
- doc: Turn off on-the-fly creation of indices for output BAM/CRAM files
  id: disable_bam_indexing
  type: boolean?
  inputBinding:
    prefix: --disable_bam_indexing
- doc: Disable printing of base insertion and deletion tags (with -BQSR)
  id: disable_indel_quals
  type: boolean?
  inputBinding:
    prefix: --disable_indel_quals
- doc: Read filters to disable
  id: disable_read_filter
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--disable_read_filter"))
- doc: Target coverage threshold for downsampling to coverage
  id: downsample_to_coverage
  type: int?
  inputBinding:
    prefix: --downsample_to_coverage
- doc: Fraction of reads to downsample to
  id: downsample_to_fraction
  type: double?
  inputBinding:
    prefix: --downsample_to_fraction
- doc: Type of read downsampling to employ at a given locus
  id: downsampling_type
  type:
  - 'null'
  - type: enum
    symbols:
    - NONE
    - ALL_READS
    - BY_SAMPLE
  inputBinding:
    prefix: --downsampling_type
- doc: Emit the OQ tag with the original base qualities (with -BQSR)
  id: emit_original_quals
  type: boolean?
  inputBinding:
    prefix: --emit_original_quals
- doc: One or more genomic intervals to exclude from processing
  id: excludeIntervals
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
    valueFrom: $(applyTagsToArgument("--excludeIntervals", inputs.excludeIntervals_tags))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'excludeIntervals'
  id: excludeIntervals_tags
- doc: Fix mis-encoded base quality scores
  id: fix_misencoded_quality_scores
  type: boolean?
  inputBinding:
    prefix: --fix_misencoded_quality_scores
- doc: Enable on-the-fly creation of md5s for output BAM files.
  id: generate_md5
  type: boolean?
  inputBinding:
    prefix: --generate_md5
- doc: Global Qscore Bayesian prior to use for BQSR
  id: globalQScorePrior
  type: double?
  inputBinding:
    prefix: --globalQScorePrior
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'input_file'
  id: input_file_tags
- doc: Interval merging rule for abutting intervals
  id: interval_merging
  type:
  - 'null'
  - type: enum
    symbols:
    - ALL
    - OVERLAPPING_ONLY
  inputBinding:
    prefix: --interval_merging
- doc: Amount of padding (in bp) to add to each interval
  id: interval_padding
  type: int?
  inputBinding:
    prefix: --interval_padding
- doc: Set merging approach to use for combining interval inputs
  id: interval_set_rule
  type:
  - 'null'
  - type: enum
    symbols:
    - UNION
    - INTERSECTION
  inputBinding:
    prefix: --interval_set_rule
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
    valueFrom: $(applyTagsToArgument("--intervals", inputs.intervals_tags))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'intervals'
  id: intervals_tags
- doc: Keep program records in the SAM header
  id: keep_program_records
  type: boolean?
  inputBinding:
    prefix: --keep_program_records
- doc: Set the logging location
  id: log_to_file
  type: string?
  inputBinding:
    prefix: --log_to_file
- doc: Set the minimum level of logging
  id: logging_level
  type: string?
  inputBinding:
    prefix: --logging_level
- doc: Stop execution cleanly as soon as maxRuntime has been reached
  id: maxRuntime
  type: long?
  inputBinding:
    prefix: --maxRuntime
- doc: Unit of time used by maxRuntime
  id: maxRuntimeUnits
  type:
  - 'null'
  - type: enum
    symbols:
    - NANOSECONDS
    - MICROSECONDS
    - MILLISECONDS
    - SECONDS
    - MINUTES
    - HOURS
    - DAYS
  inputBinding:
    prefix: --maxRuntimeUnits
- doc: Enable threading efficiency monitoring
  id: monitorThreadEfficiency
  type: boolean?
  inputBinding:
    prefix: --monitorThreadEfficiency
- doc: Always output all the records in VCF FORMAT fields, even if some are missing
  id: never_trim_vcf_format_field
  type: boolean?
  inputBinding:
    prefix: --never_trim_vcf_format_field
- doc: Don't include the command line in output VCF headers
  id: no_cmdline_in_header
  type: boolean?
  inputBinding:
    prefix: --no_cmdline_in_header
- doc: Use a non-deterministic random seed
  id: nonDeterministicRandomSeed
  type: boolean?
  inputBinding:
    prefix: --nonDeterministicRandomSeed
- doc: Number of CPU threads to allocate per data thread
  id: num_cpu_threads_per_data_thread
  type: int?
  inputBinding:
    prefix: --num_cpu_threads_per_data_thread
- doc: Number of data threads to allocate to this analysis
  id: num_threads
  type: int?
  inputBinding:
    prefix: --num_threads
- doc: Pedigree files for samples
  id: pedigree
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--pedigree", inputs.pedigree_tags))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'pedigree'
  id: pedigree_tags
- doc: Pedigree string for samples
  id: pedigreeString
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--pedigreeString"))
- doc: Validation strictness for pedigree
  id: pedigreeValidationType
  type:
  - 'null'
  - type: enum
    symbols:
    - STRICT
    - SILENT
  inputBinding:
    prefix: --pedigreeValidationType
- doc: Write GATK runtime performance log to this file
  id: performanceLog
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--performanceLog", inputs.performanceLog_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'performanceLog'
  id: performanceLog_tags
- doc: Don't recalibrate bases with quality scores less than this threshold (with
    -BQSR)
  id: preserve_qscores_less_than
  type: int?
  inputBinding:
    prefix: --preserve_qscores_less_than
- doc: Quantize quality scores to a given number of levels (with -BQSR)
  id: quantize_quals
  type: int?
  inputBinding:
    prefix: --quantize_quals
- doc: Number of reads per SAM file to buffer in memory
  id: read_buffer_size
  type: int?
  inputBinding:
    prefix: --read_buffer_size
- doc: Filters to apply to reads before analysis
  id: read_filter
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--read_filter"))
- doc: Exclude read groups based on tags
  id: read_group_black_list
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--read_group_black_list"))
- doc: Reduce NDN elements in CIGAR string
  id: refactor_NDN_cigar_string
  type: boolean?
  inputBinding:
    prefix: --refactor_NDN_cigar_string
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'reference_sequence'
  id: reference_sequence_tags
- doc: Reference window stop
  id: reference_window_stop
  type: int?
  inputBinding:
    prefix: --reference_window_stop
- doc: Remove program records from the SAM header
  id: remove_program_records
  type: boolean?
  inputBinding:
    prefix: --remove_program_records
- doc: Rename sample IDs on-the-fly at runtime using the provided mapping file
  id: sample_rename_mapping_file
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--sample_rename_mapping_file", inputs.sample_rename_mapping_file_tags))
- type:
  - 'null'
  - string
  - type: array
    items: string
  doc: A argument to set the tags of 'sample_rename_mapping_file'
  id: sample_rename_mapping_file_tags
- doc: Time interval for process meter information output (in seconds)
  id: secondsBetweenProgressUpdates
  type: long?
  inputBinding:
    prefix: --secondsBetweenProgressUpdates
- doc: Emit list of input BAM/CRAM files to log
  id: showFullBamList
  type: boolean?
  inputBinding:
    prefix: --showFullBamList
- doc: Strip down read content and tags
  id: simplifyBAM
  type: boolean?
  inputBinding:
    prefix: --simplifyBAM
- doc: Output sites-only VCF
  id: sites_only
  type: boolean?
  inputBinding:
    prefix: --sites_only
- doc: Use static quantized quality scores to a given number of levels (with -BQSR)
  id: static_quantized_quals
  type:
  - 'null'
  - type: array
    items: int
    inputBinding:
      valueFrom: $(null)
  - int
  inputBinding:
    valueFrom: $(generateArrayCmd("--static_quantized_quals"))
- doc: 'Enable unsafe operations: nothing will be checked at runtime'
  id: unsafe
  type:
  - 'null'
  - type: enum
    symbols:
    - ALLOW_N_CIGAR_READS
    - ALLOW_UNINDEXED_BAM
    - ALLOW_UNSET_BAM_SORT_ORDER
    - NO_READ_ORDER_VERIFICATION
    - ALLOW_SEQ_DICT_INCOMPATIBILITY
    - LENIENT_VCF_PROCESSING
    - ALL
  inputBinding:
    prefix: --unsafe
- doc: Use the JDK Deflater instead of the IntelDeflater for writing BAMs
  id: use_jdk_deflater
  type: boolean?
  inputBinding:
    prefix: --use_jdk_deflater
- doc: Use the JDK Inflater instead of the IntelInflater for reading BAMs
  id: use_jdk_inflater
  type: boolean?
  inputBinding:
    prefix: --use_jdk_inflater
- doc: Use the base quality scores from the OQ tag
  id: useOriginalQualities
  type: boolean?
  inputBinding:
    prefix: --useOriginalQualities
- doc: How strict should we be with validation
  id: validation_strictness
  type:
  - 'null'
  - type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  inputBinding:
    prefix: --validation_strictness
- doc: Parameter to pass to the VCF/BCF IndexCreator
  id: variant_index_parameter
  type: int?
  inputBinding:
    prefix: --variant_index_parameter
- doc: Type of IndexCreator to use for VCF/BCF indices
  id: variant_index_type
  type:
  - 'null'
  - type: enum
    symbols:
    - DYNAMIC_SEEK
    - DYNAMIC_SIZE
    - LINEAR
    - INTERVAL
  inputBinding:
    prefix: --variant_index_type
- doc: Output version information
  id: version
  type: boolean?
  inputBinding:
    prefix: --version
- doc: The name of the library to keep, filtering out all others
  id: library
  type: string?
  inputBinding:
    prefix: --library
- doc: Filter out reads with no stored bases (i.e. '*' where the sequence should be),
    instead of failing with an error
  id: filter_bases_not_stored
  type: boolean?
  inputBinding:
    prefix: --filter_bases_not_stored
- doc: Filter out reads with mismatching numbers of bases and base qualities, instead
    of failing with an error
  id: filter_mismatching_base_and_quals
  type: boolean?
  inputBinding:
    prefix: --filter_mismatching_base_and_quals
- doc: Filter out reads with CIGAR containing the N operator, instead of failing with
    an error
  id: filter_reads_with_N_cigar
  type: boolean?
  inputBinding:
    prefix: --filter_reads_with_N_cigar
- doc: Minimum read mapping quality required to consider a read for calling
  id: min_mapping_quality_score
  type: int?
  inputBinding:
    prefix: --min_mapping_quality_score
- doc: Insert size cutoff
  id: maxInsertSize
  type: int?
  inputBinding:
    prefix: --maxInsertSize
- doc: Allow a read to be filtered out based on having only 1 soft-clipped block.
    By default, both ends must have a soft-clipped block, setting this flag requires
    only 1 soft-clipped block.
  id: do_not_require_softclips_both_ends
  type: boolean?
  inputBinding:
    prefix: --do_not_require_softclips_both_ends
- doc: Value for which reads with less than this number of aligned bases is considered
    too short
  id: filter_is_too_short_value
  type: int?
  inputBinding:
    prefix: --filter_is_too_short_value
- doc: Discard reads with RG:PL attribute containing this string
  id: PLFilterName
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--PLFilterName"))
- doc: Discard reads with length greater than the specified value
  id: maxReadLength
  type: int?
  inputBinding:
    prefix: --maxReadLength
- doc: Discard reads with length shorter than the specified value
  id: minReadLength
  type: int?
  inputBinding:
    prefix: --minReadLength
- doc: Read name to whitelist
  id: readName
  type: string?
  inputBinding:
    prefix: --readName
- doc: Discard reads on the forward strand
  id: filterPositive
  type: boolean?
  inputBinding:
    prefix: --filterPositive
- doc: Default read mapping quality to assign to all reads
  id: default_mapping_quality
  type: int?
  inputBinding:
    prefix: --default_mapping_quality
- doc: Original mapping quality
  id: reassign_mapping_quality_from
  type: int?
  inputBinding:
    prefix: --reassign_mapping_quality_from
- doc: Desired mapping quality
  id: reassign_mapping_quality_to
  type: int?
  inputBinding:
    prefix: --reassign_mapping_quality_to
- doc: The name of the sample(s) to keep, filtering out all others
  id: sample_to_keep
  type:
  - 'null'
  - type: array
    items: string
    inputBinding:
      valueFrom: $(null)
  - string
  inputBinding:
    valueFrom: $(generateArrayCmd("--sample_to_keep"))
- doc: The name of the read group to keep, filtering out all others
  id: read_group_to_keep
  type: string?
  inputBinding:
    prefix: --read_group_to_keep
outputs:
- id: activeRegionOutOutput
  type: File?
  outputBinding:
    glob: $(inputs.activeRegionOut)
- id: activityProfileOutOutput
  type: File?
  outputBinding:
    glob: $(inputs.activityProfileOut)
- id: bamOutputOutput
  type: File?
  outputBinding:
    glob: $(inputs.bamOutput)
- id: graphOutputOutput
  type: File?
  outputBinding:
    glob: $(inputs.graphOutput)
- id: outOutput
  type: File
  outputBinding:
    glob: $(inputs.out)
