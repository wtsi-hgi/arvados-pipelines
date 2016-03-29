import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import gzip

BGZF_EOF="\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff\x06\x00\x42\x43\x02\x00\x1b\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00"

def validate_compressed_indexed_vcf_collection(pdh):
    reader = arvados.collection.CollectionReader(pdh)
    vcf_files = {}
    vcf_indices = {}
    for s in reader.all_streams():
        for f in s.all_files():
            if re.search(r'\.vcf\.gz$', f.name()):
                vcf_files[(s.name(), f.name())] = f
            elif re.search(r'\.tbi$', f.name()):
                vcf_indices[(s.name(), f.name())] = f
            else:
                print "WARNING: unexpected file in task output - ignoring %s" % (f.name())

    # verify that we got some VCFs
    if len(vcf_files) <= 0:
        print "ERROR: found no VCF files in collection"
        return False

    print "Have %s VCF files to validate" % (len(vcf_files))
    for ((stream_name, file_name), vcf) in vcf_files.items():
        vcf_path = os.path.join(stream_name, file_name)
        # verify that VCF is sizeable
        if vcf.size() < 128:
            print "ERROR: Small VCF file %s - INVALID!" % (vcf_path)
            return False
        print "Have VCF file %s of %s bytes" % (vcf_path, vcf.size())

        # verify that BGZF EOF block is intact
        eof_block = vcf.readfrom(vcf.size()-28, 28, num_retries=10)
        if eof_block != BGZF_EOF:
            print "ERROR: VCF BGZF EOF block was missing or incorrect: %s" % (':'.join("{:02x}".format(ord(c)) for c in eof_block))
            return False

        # verify index exists
        tbi = vcf_indices.get((stream_name, re.sub(r'gz$', 'gz.tbi', file_name)),
                              None)
        if tbi is None:
            print "ERROR: could not find index .tbi for VCF: %s" % (vcf_path)
            return False

        # verify index is sizeable
        if tbi.size() < 32:
            print "ERROR: .tbi index was too small for VCF %s (%s): %s bytes" % (vcf_path, tbi.name(), tbi.size())
            return False

        # verify first compressed block starts with ##fileformat=VCF
        vcf.seek(0)
        try:
            g = gzip.GzipFile(fileobj=vcf)
            header = g.read(16)
            if header != "##fileformat=VCF":
                print "ERROR: first 16 bytes of decompressed block was '%s' instead of '##fileformat=VCF'" % (header)
                return False
        except Exception as e:
            print "ERROR: could not read from compressed VCF: %s" % (e)
            return False

    return True
