$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"
id: GenomicsDBImport
cwlVersion: v1.0
baseCommand:
- python3
- /gatk-tmpdir-output-wrapper.py
- '["--genomicsdb-workspace-path"]' # output paths to redirect to tmpdir
- '["-Xmx4g","-Xms4g"]' # extra java args
- GenomicsDBImport # GATK command
class: CommandLineTool
doc: |-
  Import single-sample GVCFs into GenomicsDB before joint genotyping.

   <p>The GATK4 Best Practice Workflow for SNP and Indel calling uses GenomicsDBImport to merge GVCFs from multiple samples.
   GenomicsDBImport offers the same functionality as CombineGVCFs and comes from the <i>Intel-Broad Center for Genomics</i>.
   The datastore transposes sample-centric variant information across genomic loci to make data more accessible to tools.
   </p>

   <p>To query the contents of the GenomicsDB datastore, use
   <a href='https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_gatk_tools_walkers_variantutils_SelectVariants.php'>SelectVariants</a>.
   See <a href='https://software.broadinstitute.org/gatk/documentation/article?id=10061'>Tutorial#10061</a> to get started. </p>

   <p>Details on GenomicsDB are at
   <a href='https://github.com/Intel-HLS/GenomicsDB/wiki'>https://github.com/Intel-HLS/GenomicsDB/wiki</a>.
   In brief, GenomicsDB is a utility built on top of TileDB. TileDB is a format for efficiently representing sparse data.
   Genomics data is typically sparse in that each sample has few variants with respect to the entire reference genome.
   GenomicsDB contains code to specialize TileDB for genomics applications, such as VCF parsing and INFO field annotation
   calculation.
   </p>

   <h3>Input</h3>
   <p>
   One or more GVCFs produced by in HaplotypeCaller with the `-ERC GVCF` or `-ERC BP_RESOLUTION` settings, containing
   the samples to joint-genotype.
   </p>

   <h3>Output</h3>
   <p>
   A GenomicsDB workspace
   </p>

    <h3>Usage examples</h3>

    Provide each sample GVCF separately.
    <pre>
      gatk --java-options "-Xmx4g -Xms4g" GenomicsDBImport \
        -V data/gvcfs/mother.g.vcf.gz \
        -V data/gvcfs/father.g.vcf.gz \
        -V data/gvcfs/son.g.vcf.gz \
        --genomicsdb-workspace-path my_database \
        -L 20
    </pre>

    Provide sample GVCFs in a map file.

    <pre>
      gatk --java-options "-Xmx4g -Xms4g" \
         GenomicsDBImport \
         --genomicsdb-workspace-path my_database \
         --batch-size 50 \
         -L chr1:1000-10000 \
         --sample-name-map cohort.sample_map \
         --reader-threads 5
    </pre>

    The sample map is a tab-delimited text file with sample_name--tab--path_to_sample_vcf per line. Using a sample map
    saves the tool from having to download the GVCF headers in order to determine the sample names.

    <pre>
    sample1      sample1.vcf.gz
    sample2      sample2.vcf.gz
    sample3      sample3.vcf.gz
    </pre>

   <h3>Caveats</h3>
   <ul>
       <li>IMPORTANT: The -Xmx value the tool is run with should be less than the total amount of physical memory available by at least a few GB, as the native TileDB library requires additional memory on top of the Java memory. Failure to leave enough memory for the native code can result in confusing error messages!</li>
       <li>A single interval must be provided. This means each import is limited to a maximum of one contig</li>
       <li>Currently, only supports diploid data</li>
       <li>Input GVCFs cannot contain multiple entries for a single genomic position</li>
       <li>The --genomicsdb-workspace-path must point to a non-existent or empty directory.</li>
   </ul>

   <h3>Developer Note</h3>
   To read data from GenomicsDB, use the query interface com.intel.genomicsdb.GenomicsDBFeatureReader
temporaryFailCodes: [3]
hints:
  arv:RuntimeConstraints:
    outputDirType: keep_output_dir
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
  dockerPull: mercury/gatk-4.0.0.0-tmpdir-output-wrapper:v2
inputs:
- doc: Reference sequence
  id: reference
  type: File?
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
- doc: Batch size controls the number of samples for which readers are open at once
    and therefore provides a way to minimize memory consumption. However, it can take
    longer to complete. Use the consolidate flag if more than a hundred batches were
    used. This will improve feature read time. batchSize=0 means no batching (i.e.
    readers for all samples will be opened at once) Defaults to 0
  id: batch-size
  type: int?
  inputBinding:
    prefix: --batch-size
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
- doc: Boolean flag to enable consolidation. If importing data in batches, a new fragment
    is created for each batch. In case thousands of fragments are created, GenomicsDB
    feature readers will try to open ~20x as many files. Also, internally GenomicsDB
    would consume more memory to maintain bookkeeping data from all fragments. Use
    this flag to merge all fragments into one. Merging can potentially improve read
    performance, however overall benefit might not be noticeable as the top Java layers
    have significantly higher overheads. This flag has no effect if only one batch
    is used. Defaults to false
  id: consolidate
  type: boolean?
  inputBinding:
    prefix: --consolidate
    valueFrom: $(generateGATK4BooleanValue())
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
- doc: Buffer size in bytes allocated for GenomicsDB attributes during import. Should
    be large enough to hold data from one site.  Defaults to 1048576
  id: genomicsdb-segment-size
  type: long?
  inputBinding:
    prefix: --genomicsdb-segment-size
- doc: Buffer size in bytes to store variant contexts. Larger values are better as
    smaller values cause frequent disk writes. Defaults to 16384 which was empirically
    determined to work well for many inputs.
  id: genomicsdb-vcf-buffer-size
  type: long?
  inputBinding:
    prefix: --genomicsdb-vcf-buffer-size
- doc: Workspace for GenomicsDB. Must be a POSIX file system path, but can be a relative
    path. Must be an empty or non-existent directory.
  id: genomicsdb-workspace-path
  type: string
  inputBinding:
    prefix: --genomicsdb-workspace-path
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
  doc: A argument to set the tags of 'input'
  id: input_tags
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
  - File
  - string
  inputBinding:
    valueFrom: $(applyTagsToArgument("--intervals", inputs['intervals_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'intervals'
  id: intervals_tags
- doc: Lenient processing of VCF files
  id: lenient
  type: boolean?
  inputBinding:
    prefix: --lenient
    valueFrom: $(generateGATK4BooleanValue())
- doc: Will overwrite given workspace if it exists. Otherwise a new workspace is created.
    Defaults to false
  id: overwrite-existing-genomicsdb-workspace
  type: boolean?
  inputBinding:
    prefix: --overwrite-existing-genomicsdb-workspace
    valueFrom: $(generateGATK4BooleanValue())
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
- doc: How many simultaneous threads to use when opening VCFs in batches; higher values
    may improve performance when network latency is an issue
  id: reader-threads
  type: int?
  inputBinding:
    prefix: --reader-threads
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'reference'
  id: reference_tags
- doc: Path to file containing a mapping of sample name to file uri in tab delimited
    format.  If this is specified then the header from the first sample will be treated
    as the merged header rather than merging the headers, and the sample names will
    be taken from this file.  This may be used to rename input samples. This is a
    performance optimization that relaxes the normal checks for consistent headers.  Using
    vcfs with incompatible headers may result in silent data corruption.
  id: sample-name-map
  type: File?
  inputBinding:
    valueFrom: $(applyTagsToArgument("--sample-name-map", inputs['sample-name-map_tags']))
- type:
  - 'null'
  - string
  - string[]
  doc: A argument to set the tags of 'sample-name-map'
  id: sample-name-map_tags
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
- doc: Boolean flag to enable checks on the sampleNameMap file. If true, tool checks
    whetherfeature readers are valid and shows a warning if sample names do not match
    with the headers. Defaults to false
  id: validate-sample-name-map
  type: boolean?
  inputBinding:
    prefix: --validate-sample-name-map
    valueFrom: $(generateGATK4BooleanValue())
- doc: GVCF files to be imported to GenomicsDB. Each file must containdata for only
    a single sample. Either this or sample-name-map must be specified.
  id: variant
  type:
  - 'null'
  - type: array
    items: File
    inputBinding:
      valueFrom: $(null)
  - File
  inputBinding:
    valueFrom: $(applyTagsToArgument("--variant", inputs['variant_tags']))
- type:
  - 'null'
  - type: array
    items:
    - string
    - type: array
      items: string
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
- id: genomicsdb-workspace
  doc: Output folder corresponding to the input argument genomicsdb-workspace-path
  type: Directory
  outputBinding:
    glob: $(inputs['genomicsdb-workspace-path'])
