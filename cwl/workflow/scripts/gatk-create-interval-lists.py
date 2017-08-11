#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import re
import subprocess
import sys
import argparse

# the amount to weight each sequence contig
weight_seq = 120000

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

class APIError(Exception):
    pass


def create_interval_lists(reference_coll, skip_sq_sn_r):

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
    # chunk_points = int(total_points / genome_chunks)

    basename = os.path.splitext(os.path.basename(dict_reader.name))[0]+'.interval_list'
    # directory = os.path.join(os.getcwd(), basename)
    # os.makedirs(directory)
    # os.chdir(directory)

    inpt_name = os.path.basename(dict_reader.name)
    f = open(basename, 'w+')

    f.write(interval_header)

    
    remaining_points = total_points
    chunk_num = 1
    while len(sns) > 0:
        chunk_num+=1
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
        interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, sn)
        remaining_points -= (end-start+1)

            #write to the file
        f.write(interval)
            
        if remaining_points <= 0:
            break        
    f.close()

    chunk_input_pdh = os.getcwd()
    print "Chunk intervals collection saved as: %s" % (chunk_input_pdh)
    return chunk_input_pdh

def main():

    #parse the arguments from command line
    # path_to_dict = sys.argv[1]
    # todir = sys.argv[2]

    parser = argparse.ArgumentParser(description='Create Interval List')
    parser.add_argument("--path", help="path to dict file")
    parser.add_argument("--output_dir", help="output directory for interval list")
    args = vars(parser.parse_args())

    path_to_dict = args['path']
    todir = args['output_dir']
    
    skip_sq_sn_regex = '_decoy$'
    # if 'skip_sq_sn_regex' in current_job['script_parameters']:
    #     skip_sq_sn_regex = current_job['script_parameters']['skip_sq_sn_regex']
    skip_sq_sn_r = re.compile(skip_sq_sn_regex)
    
    # Create an interval_list file for each chunk based on the .dict in the reference collection

    #change to working directory
    os.chdir(todir)

    #open dict file
    ref_input_pdh = open(path_to_dict, 'r')
    
    output_locator = create_interval_lists(ref_input_pdh, skip_sq_sn_r)

    # Done!


if __name__ == '__main__':
    main()
