#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import re
import subprocess
import sys

# the amount to weight each sequence contig
weight_seq = 120000

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

class APIError(Exception):
    pass


def create_interval_lists(genome_chunks, reference_coll, skip_sq_sn_r):

    #load the dict data
    dict_reader = reference_coll
    
    interval_header = ""
    dict_lines = dict_reader.readlines()
    dict_header = dict_lines.pop(0)
    if re.search(r'^@HD', dict_header) is None:
        raise InvalidArgumentError("Dict file in reference collection does not have correct header: [%s]" % dict_header)
    interval_header += dict_header
    print "Dict header is %s" % dict_header
    sn_intervals = dict()
    sns = []
    total_len = 0
    for sq in dict_lines:
        if re.search(r'^@SQ', sq) is None:
            raise InvalidArgumentError("Dict file contains malformed SQ line: [%s]" % sq)
        interval_header += sq
        sn = None
        ln = None
        for tagval in sq.split("\t"):
            tv = tagval.split(":", 1)
            if tv[0] == "SN":
                sn = tv[1]
            if tv[0] == "LN":
                ln = tv[1]
            if sn and ln:
                break
        if not (sn and ln):
            raise InvalidArgumentError("Dict file SQ entry missing required SN and/or LN parameters: [%s]" % sq)
        assert(sn and ln)
        if sn_intervals.has_key(sn):
            raise InvalidArgumentError("Dict file has duplicate SQ entry for SN %s: [%s]" % (sn, sq))
        if skip_sq_sn_r.search(sn):
            next
        sn_intervals[sn] = (1, int(ln))
        sns.append(sn)
        total_len += int(ln)
    total_sequences = len(sns)

    # Chunk the genome into genome_chunks equally sized pieces and create intervals files
    print "Total sequences included: %s" % (total_sequences)
    print "Total genome length is %s" % total_len
    total_points = total_len + (total_sequences * weight_seq)
    print "Total points to split: %s" % (total_points)
    chunk_points = int(total_points / genome_chunks)

    # create directory to save the created interval lists
    directory = os.path.join(os.getcwd(), 'interval_lists')
    os.makedirs(directory)
    os.chdir(directory)
    
    print "Chunking genome into %s chunks of ~%s points" % (genome_chunks, chunk_points)
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = os.path.basename(dict_reader.name) + (".%s_of_%s.interval_list" % (chunk_num, genome_chunks))
        print "Creating interval file for chunk %s" % chunk_num

        # create file with correct name and write to it
        f = open(chunk_input_name, 'w+')
        f.write(interval_header)
        
        remaining_points = chunk_points
        while len(sns) > 0:
            sn = sns.pop(0)
            remaining_points -= weight_seq
            if remaining_points <= 0:
                sns.insert(0, sn)
                break
            if not sn_intervals.has_key(sn):
                raise ValueError("sn_intervals missing entry for sn [%s]" % sn)
            start, end = sn_intervals[sn]
            if (end-start+1) > remaining_points:
                # not enough space for the whole sq, split it
                real_end = end
                end = remaining_points + start - 1
                assert((end-start+1) <= remaining_points)
                sn_intervals[sn] = (end+1, real_end)
                sns.insert(0, sn)
            interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, "interval_%s_of_%s_%s" % (chunk_num, genome_chunks, sn))
            remaining_points -= (end-start+1)

            #write to the file
            f.write(interval)
            
            chunk_intervals_count += 1
            if remaining_points <= 0:
                break
        if chunk_intervals_count > 0:
            print "Chunk intervals file %s saved." % (chunk_input_name)
        else:
            print "WARNING: skipping empty intervals for %s" % chunk_input_name
            
    f.close()

    #print the output directory
    chunk_input_pdh = directory
    print "Chunk intervals collection saved as: %s" % (chunk_input_pdh)
    return chunk_input_pdh

def main():

    #parse the arguments from command line
    genome_chunks = int(sys.argv[1])
    path_to_dict = sys.argv[2]
    todir = sys.argv[3]
    
    skip_sq_sn_regex = '_decoy$'
    # if 'skip_sq_sn_regex' in current_job['script_parameters']:
    #     skip_sq_sn_regex = current_job['script_parameters']['skip_sq_sn_regex']
    skip_sq_sn_r = re.compile(skip_sq_sn_regex)
    
    if genome_chunks < 1:
        raise InvalidArgumentError("genome_chunks must be a positive integer")

    # Create an interval_list file for each chunk based on the .dict in the reference collection

    #change to working directory
    os.chdir(todir)

    #open dict file
    ref_input_pdh = open(path_to_dict, 'r')
    
    output_locator = create_interval_lists(genome_chunks, ref_input_pdh, skip_sq_sn_r)

    # Done!


if __name__ == '__main__':
    main()
