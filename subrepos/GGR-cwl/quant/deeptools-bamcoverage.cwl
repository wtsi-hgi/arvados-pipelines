#!/usr/bin/env cwl-runner

# Mantainer: alejandro.barrera@duke.edu
# Partially Auto generated with clihp (https://github.com/portah/clihp, developed by Andrey.Kartashov@cchmc.org)
# Developed for GGR project (https://github.com/Duke-GCB/GGR-cwl)

cwlVersion: 'cwl:draft-3'
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: 'dukegcb/deeptools'

requirements:
  - class: InlineJavascriptRequirement
inputs:
  - id: bam
    type: File
    description: "BAM file to process "
    secondaryFiles: $(self.path + '.bai')
    inputBinding:
      position: 1
      prefix: "--bam"
#-------------------------------------
#--- Output formatting arguments -----
#-------------------------------------
  - id: outFileName
    type:
      - 'null'
      - string
    description: |
      FILENAME
      Output file name. (default: input BAM filename with bigwig [*.bw] or bedgraph [*.bdg] extension.)
  - id: output_suffix
    type:
      - 'null'
      - string
    description: "Suffix used for output file (input BAM filename + suffix)"
  - id: outFileFormat
    type: string
    default: 'bigwig'
    description: |
      {bigwig,bedgraph}, -of {bigwig,bedgraph}
      Output file type. Either "bigwig" or "bedgraph".
      (default: bigwig)
    inputBinding:
      position: 1
      prefix: '--outFileFormat'
#---------------------------------
#-----  Processing arguments -----
#---------------------------------
  - id: scaleFactor
    type:
      - 'null'
      - float
    description: |
      SCALEFACTOR
      Indicate a number that you would like to use. When
      used in combination with --normalizeTo1x or
      --normalizeUsingRPKM, the computed scaling factor will
      be multiplied by the given scale factor. (default:
      1.0)
    inputBinding:
      position: 1
      prefix: '--scaleFactor'
  - id: MNase
    type:
      - 'null'
      - boolean
    description: | 
      Determine nucleosome positions from MNase-seq data.
      Only 3 nucleotides at the center of each fragment are
      counted. The fragment ends are defined by the two mate
      reads. Only fragment lengthsbetween 130 - 200 bp are
      considered to avoid dinucleosomes or other
      artifacts.*NOTE*: Requires paired-end data. A bin size
      of 1 is recommended. (default: False)
    inputBinding:
      position: 1
      prefix: '--MNase'
  - id: filterRNAstrand
    type:
      - 'null'
      - string
    description: |
      {forward,reverse}
      Selects RNA-seq reads (single-end or paired-end) in
      the given strand. (default: None)
    inputBinding:
      position: 1
      prefix: '--filterRNAstrand'
  - id: version
    type:
      - 'null'
      - boolean
    description: "show program's version number and exit"
    inputBinding:
      position: 1
      prefix: '--version'
  - id: binSize
    type:
      - 'null'
      - int
    description: |
      INT bp
      Size of the bins, in bases, for the output of the
      bigwig/bedgraph file. (default: 50)
    inputBinding:
      position: 1
      prefix: '--binSize'
  - id: region
    type:
      - 'null'
      - string
    description: |
      CHR:START:END
      Region of the genome to limit the operation to - this
      is useful when testing parameters to reduce the
      computing time. The format is chr:start:end, for
      example --region chr10 or --region
      chr10:456700:891000. (default: None)
    inputBinding:
      position: 1
      prefix: '--region'
  - id: blackListFileName
    type:
      - 'null'
      - File
    description: |
      BED file
      A BED file containing regions that should be excluded
      from all analyses. Currently this works by rejecting
      genomic chunks that happen to overlap an entry.
      Consequently, for BAM files, if a read partially
      overlaps a blacklisted region or a fragment spans over
      it, then the read/fragment might still be considered.
      (default: None)
    inputBinding:
      position: 1
      prefix: '--blackListFileName'
  - id: numberOfProcessors
    type:
      - 'null'
      - int
    description: |
      INT
      Number of processors to use. Type "max/2" to use half
      the maximum number of processors or "max" to use all
      available processors. (default: max/2)
    inputBinding:
      position: 1
      prefix: '--numberOfProcessors'
  - id: verbose
    type:
      - 'null'
      - boolean
    description: |
      --verbose         
      Set to see processing messages. (default: False)

    inputBinding:
      position: 1
      prefix: '--verbose'
#-----------------------------------------
#-- Read coverage normalization options --
#-----------------------------------------      
  - id: normalizeTo1x
    type:
      - 'null'
      - string
    description: |
      EFFECTIVE GENOME SIZE LENGTH
      Report read coverage normalized to 1x sequencing depth
      (also known as Reads Per Genomic Content (RPGC)).
      Sequencing depth is defined as: (total number of
      mapped reads * fragment length) / effective genome
      size. The scaling factor used is the inverse of the
      sequencing depth computed for the sample to match the
      1x coverage. To use this option, the effective genome
      size has to be indicated after the option. The
      effective genome size is the portion of the genome
      that is mappable. Large fractions of the genome are
      stretches of NNNN that should be discarded. Also, if
      repetitive regions were not included in the mapping of
      reads, the effective genome size needs to be adjusted
      accordingly. Common values are: mm9: 2,150,570,000;
      hg19:2,451,960,000; dm3:121,400,000 and
      ce10:93,260,000. See Table 2 of http://www.plosone.org
      /article/info:doi/10.1371/journal.pone.0030377 or http
      ://www.nature.com/nbt/journal/v27/n1/fig_tab/nbt.1518_
      T1.html for several effective genome sizes. (default:
      None)
    inputBinding:
      position: 1
      prefix: '--normalizeTo1x'
  - id: normalizeUsingRPKM
    type:
      - 'null'
      - boolean
    description: |
      Use Reads Per Kilobase per Million reads to normalize
      the number of reads per bin. The formula is: RPKM (per
      bin) = number of reads per bin / ( number of mapped
      reads (in millions) * bin length (kb) ). Each read is
      considered independently,if you want to only count
      either of the mate pairs inpaired-end data, use the
      --samFlag option. (default: False)
    inputBinding:
      position: 1
      prefix: '--normalizeUsingRPKM'
  - id: ignoreForNormalization
    type:
      - 'null'
      - string
    description: |
      --ignoreForNormalization chrX chrM. (default: None)
      A list of space-delimited chromosome names containing
      those chromosomes that should be excluded for
      computing the normalization. This is useful when
      considering samples with unequal coverage across
      chromosomes, like male samples. An usage examples is
    inputBinding:
      position: 1
      prefix: '--ignoreForNormalization'
  - id: skipNonCoveredRegions
    type:
      - 'null'
      - string
    description: |
      --skipNonCoveredRegions, --skipNAs
      This parameter determines if non-covered regions
      (regions without overlapping reads) in a BAM file
      should be skipped. The default is to treat those
      regions as having a value of zero. The decision to
      skip non-covered regions depends on the interpretation
      of the data. Non-covered regions may represent, for
      example, repetitive regions that should be skipped.
      (default: False)
    inputBinding:
      position: 1
      prefix: '--skipNonCoveredRegions'
  - id: smoothLength
    type:
      - 'null'
      - int
    description: |
      INT bp
      The smooth length defines a window, larger than the
      binSize, to average the number of reads. For example,
      if the --binSize is set to 20 and the --smoothLength
      is set to 60, then, for each bin, the average of the
      bin and its left and right neighbors is considered.
      Any value smaller than --binSize will be ignored and
      no smoothing will be applied. (default: None)
      Read processing options:
    inputBinding:
      position: 1
      prefix: '--smoothLength'
#-----------------------------------------
#------- Read processing options ---------
#-----------------------------------------
  - id: extendReads
    type:
      - 'null'
      - int
    description: |
      INT bp
      This parameter allows the extension of reads to
      fragment size. If set, each read is extended, without
      exception. *NOTE*: This feature is generally NOT
      recommended for spliced-read data, such as RNA-seq, as
      it would extend reads over skipped regions. *Single-
      end*: Requires a user specified value for the final
      fragment length. Reads that already exceed this
      fragment length will not be extended. *Paired-end*:
      Reads with mates are always extended to match the
      fragment size defined by the two read mates. Unmated
      reads, mate reads that map too far apart (>4x fragment
      length) or even map to different chromosomes are
      treated like single-end reads. The input of a fragment
      length value is optional. If no value is specified, it
      is estimated from the data (mean of the fragment size
      of all mate reads). (default: False)
    inputBinding:
      position: 1
      prefix: '--extendReads'
  - id: ignoreDuplicates
    type:
      - 'null'
      - boolean
    description: |
      If set, reads that have the same orientation and start
      position will be considered only once. If reads are
      paired, the mate's position also has to coincide to
      ignore a read. (default: False)
    inputBinding:
      position: 1
      prefix: '--ignoreDuplicates'
  - id: minMappingQuality
    type:
      - 'null'
      - int
    description: |
      INT
      If set, only reads that have a mapping quality score
      of at least this are considered. (default: None)
    inputBinding:
      position: 1
      prefix: '--minMappingQuality'
  - id: centerReads
    type:
      - 'null'
      - boolean
    description: |
      By adding this option, reads are centered with respect
      to the fragment length. For paired-end data, the read
      is centered at the fragment length defined by the two
      ends of the fragment. For single-end data, the given
      fragment length is used. This option is useful to get
      a sharper signal around enriched regions. (default:
      False)
    inputBinding:
      position: 1
      prefix: '--centerReads'
  - id: samFlagInclude
    type:
      - 'null'
      - int
    description: |
      INT  
      Include reads based on the SAM flag. For example, to
      get only reads that are the first mate, use a flag of
      64. This is useful to count properly paired reads only
      once, as otherwise the second mate will be also
      considered for the coverage. (default: None)
    inputBinding:
      position: 1
      prefix: '--samFlagInclude'
  - id: samFlagExclude
    type:
      - 'null'
      - int
    description: |
      INT  
      Exclude reads based on the SAM flag. For example, to
      get only reads that map to the forward strand, use
      --samFlagExclude 16, where 16 is the SAM flag for
      reads that map to the reverse strand. (default: None)
    inputBinding:
      position: 1
      prefix: '--samFlagExclude'
outputs:
  - id: output_bam_coverage
    type: File
    outputBinding:
      glob: ${
              if (inputs.outFileName)
                return inputs.outFileName;
              if (inputs.output_suffix)
                return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + inputs.output_suffix;
              if (inputs.outFileFormat == "bedgraph")
                return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + ".bdg";
              return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + ".bw";
            }
baseCommand: bamCoverage
arguments:
  - valueFrom: ${
                  if (inputs.outFileName)
                    return inputs.outFileName;
                  if (inputs.output_suffix)
                    return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + inputs.output_suffix;
                  if (inputs.outFileFormat == "bedgraph")
                    return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + ".bdg";
                  return inputs.bam.path.replace(/^.*[\\\/]/, "").replace(/\.[^/.]+$/, "") + ".bw";
                }
    prefix: '--outFileName'
    position: 3
description: |
  usage: An example usage is:$ bamCoverage -b reads.bam -o coverage.bw


  This tool takes an alignment of reads or fragments as input (BAM file) and
  generates a coverage track (bigWig or bedGraph) as output. The coverage is
  calculated as the number of reads per bin, where bins are short consecutive
  counting windows of a defined size. It is possible to extended the length of
  the reads to better reflect the actual fragment length. *bamCoverage* offers
  normalization by scaling factor, Reads Per Kilobase per Million mapped reads
  (RPKM), and 1x depth (reads per genome coverage, RPGC).

  Required arguments:
    --bam BAM file, -b BAM file
                          BAM file to process (default: None)

  Output:
    --outFileName FILENAME, -o FILENAME
                          Output file name. (default: None)
    --outFileFormat {bigwig,bedgraph}, -of {bigwig,bedgraph}
                          Output file type. Either "bigwig" or "bedgraph".
                          (default: bigwig)

  Optional arguments:
    --help, -h            show this help message and exit
    --scaleFactor SCALEFACTOR
                          Indicate a number that you would like to use. When
                          used in combination with --normalizeTo1x or
                          --normalizeUsingRPKM, the computed scaling factor will
                          be multiplied by the given scale factor. (default:
                          1.0)
    --MNase               Determine nucleosome positions from MNase-seq data.
                          Only 3 nucleotides at the center of each fragment are
                          counted. The fragment ends are defined by the two mate
                          reads. Only fragment lengthsbetween 130 - 200 bp are
                          considered to avoid dinucleosomes or other
                          artifacts.*NOTE*: Requires paired-end data. A bin size
                          of 1 is recommended. (default: False)
    --filterRNAstrand {forward,reverse}
                          Selects RNA-seq reads (single-end or paired-end) in
                          the given strand. (default: None)
    --version             show program's version number and exit
    --binSize INT bp, -bs INT bp
                          Size of the bins, in bases, for the output of the
                          bigwig/bedgraph file. (default: 50)
    --region CHR:START:END, -r CHR:START:END
                          Region of the genome to limit the operation to - this
                          is useful when testing parameters to reduce the
                          computing time. The format is chr:start:end, for
                          example --region chr10 or --region
                          chr10:456700:891000. (default: None)
    --blackListFileName BED file, -bl BED file
                          A BED file containing regions that should be excluded
                          from all analyses. Currently this works by rejecting
                          genomic chunks that happen to overlap an entry.
                          Consequently, for BAM files, if a read partially
                          overlaps a blacklisted region or a fragment spans over
                          it, then the read/fragment might still be considered.
                          (default: None)
    --numberOfProcessors INT, -p INT
                          Number of processors to use. Type "max/2" to use half
                          the maximum number of processors or "max" to use all
                          available processors. (default: max/2)
    --verbose, -v         Set to see processing messages. (default: False)

  Read coverage normalization options:
    --normalizeTo1x EFFECTIVE GENOME SIZE LENGTH
                          Report read coverage normalized to 1x sequencing depth
                          (also known as Reads Per Genomic Content (RPGC)).
                          Sequencing depth is defined as: (total number of
                          mapped reads * fragment length) / effective genome
                          size. The scaling factor used is the inverse of the
                          sequencing depth computed for the sample to match the
                          1x coverage. To use this option, the effective genome
                          size has to be indicated after the option. The
                          effective genome size is the portion of the genome
                          that is mappable. Large fractions of the genome are
                          stretches of NNNN that should be discarded. Also, if
                          repetitive regions were not included in the mapping of
                          reads, the effective genome size needs to be adjusted
                          accordingly. Common values are: mm9: 2,150,570,000;
                          hg19:2,451,960,000; dm3:121,400,000 and
                          ce10:93,260,000. See Table 2 of http://www.plosone.org
                          /article/info:doi/10.1371/journal.pone.0030377 or http
                          ://www.nature.com/nbt/journal/v27/n1/fig_tab/nbt.1518_
                          T1.html for several effective genome sizes. (default:
                          None)
    --normalizeUsingRPKM  Use Reads Per Kilobase per Million reads to normalize
                          the number of reads per bin. The formula is: RPKM (per
                          bin) = number of reads per bin / ( number of mapped
                          reads (in millions) * bin length (kb) ). Each read is
                          considered independently,if you want to only count
                          either of the mate pairs inpaired-end data, use the
                          --samFlag option. (default: False)
    --ignoreForNormalization IGNOREFORNORMALIZATION [IGNOREFORNORMALIZATION ...],
  -ignore IGNOREFORNORMALIZATION [IGNOREFORNORMALIZATION ...]
                          A list of space-delimited chromosome names containing
                          those chromosomes that should be excluded for
                          computing the normalization. This is useful when
                          considering samples with unequal coverage across
                          chromosomes, like male samples. An usage examples is
                          --ignoreForNormalization chrX chrM. (default: None)
    --skipNonCoveredRegions, --skipNAs
                          This parameter determines if non-covered regions
                          (regions without overlapping reads) in a BAM file
                          should be skipped. The default is to treat those
                          regions as having a value of zero. The decision to
                          skip non-covered regions depends on the interpretation
                          of the data. Non-covered regions may represent, for
                          example, repetitive regions that should be skipped.
                          (default: False)
    --smoothLength INT bp
                          The smooth length defines a window, larger than the
                          binSize, to average the number of reads. For example,
                          if the --binSize is set to 20 and the --smoothLength
                          is set to 60, then, for each bin, the average of the
                          bin and its left and right neighbors is considered.
                          Any value smaller than --binSize will be ignored and
                          no smoothing will be applied. (default: None)

  Read processing options:
    --extendReads [INT bp], -e [INT bp]
                          This parameter allows the extension of reads to
                          fragment size. If set, each read is extended, without
                          exception. *NOTE*: This feature is generally NOT
                          recommended for spliced-read data, such as RNA-seq, as
                          it would extend reads over skipped regions. *Single-
                          end*: Requires a user specified value for the final
                          fragment length. Reads that already exceed this
                          fragment length will not be extended. *Paired-end*:
                          Reads with mates are always extended to match the
                          fragment size defined by the two read mates. Unmated
                          reads, mate reads that map too far apart (>4x fragment
                          length) or even map to different chromosomes are
                          treated like single-end reads. The input of a fragment
                          length value is optional. If no value is specified, it
                          is estimated from the data (mean of the fragment size
                          of all mate reads). (default: False)
    --ignoreDuplicates    If set, reads that have the same orientation and start
                          position will be considered only once. If reads are
                          paired, the mate's position also has to coincide to
                          ignore a read. (default: False)
    --minMappingQuality INT
                          If set, only reads that have a mapping quality score
                          of at least this are considered. (default: None)
    --centerReads         By adding this option, reads are centered with respect
                          to the fragment length. For paired-end data, the read
                          is centered at the fragment length defined by the two
                          ends of the fragment. For single-end data, the given
                          fragment length is used. This option is useful to get
                          a sharper signal around enriched regions. (default:
                          False)
    --samFlagInclude INT  Include reads based on the SAM flag. For example, to
                          get only reads that are the first mate, use a flag of
                          64. This is useful to count properly paired reads only
                          once, as otherwise the second mate will be also
                          considered for the coverage. (default: None)
    --samFlagExclude INT  Exclude reads based on the SAM flag. For example, to
                          get only reads that map to the forward strand, use
                          --samFlagExclude 16, where 16 is the SAM flag for
                          reads that map to the reverse strand. (default: None)

