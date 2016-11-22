#!/usr/bin/env python

import os           # Import the os module for basic path manipulation
import arvados      # Import the Arvados sdk module
import re
import subprocess

# the amount to weight each sequence contig
weight_seq = 120000

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

class APIError(Exception):
    pass

def prepare_gatk_interval_list_collection(interval_list_coll):
    """
    Checks that the supplied interval_list_collection has the required 
    files and only the required files for GATK. 
    Returns: a portable data hash for the interval_list collection
    """
    # Ensure we have a .fa interval_list file with corresponding .fai index and .dict
    # see: http://gatkforums.broadinstitute.org/discussion/1601/how-can-i-prepare-a-fasta-file-to-use-as-interval_list
    ilcr = arvados.CollectionReader(interval_list_coll)
    ref_dict = {}
    for ils in ilcr.all_streams():
        for ilf in ils.all_files():
            if re.search(r'\.dict$', ilf.name()):
                ref_dict[ils.name(), ilf.name()] = ilf
    if len(ref_dict) < 1:
        raise InvalidArgumentError("Expected an interval_list dict in interval_list_collection, but found none. Found [%s]" % ' '.join(ilf.name() for ilf in ils.all_files()))
    if len(ref_dict) > 1:
        raise InvalidArgumentError("Expected a single interval_list dict in interval_list_collection, but found multuple. Found [%s]" % ' '.join(ilf.name() for ilf in ils.all_files()))
    for ((s_name, f_name), dict_f) in ref_dict.items():
            ref_input = dict_f.as_manifest()
            break
    # Create and return a portable data hash for the ref_input manifest
    try:
        r = arvados.api().collections().create(body={"manifest_text": ref_input}).execute()
        ref_input_pdh = r["portable_data_hash"]
    except:
        raise 
    return ref_input_pdh

def create_interval_lists(genome_chunks, interval_list_coll, skip_sq_sn_r):
    rcr = arvados.CollectionReader(interval_list_coll)
    ref_dict = []
    dict_reader = None
    for rs in rcr.all_streams():
        for rf in rs.all_files():
            if re.search(r'\.dict$', rf.name()):
                ref_dict.append(rf)
    if len(ref_dict) < 1:
        raise InvalidArgumentError("Interval_List collection does not contain any .dict files but one is required.")
    if len(ref_dict) > 1:
        raise InvalidArgumentError("Interval_List collection contains multiple .dict files but only one is allowed.")
    dict_reader = ref_dict[0]

    # Load the dict data
    interval_header = ""
    dict_lines = dict_reader.readlines()
    dict_header = dict_lines.pop(0)
    if re.search(r'^@HD', dict_header) is None:
        raise InvalidArgumentError("Dict file in interval_list collection does not have correct header: [%s]" % dict_header)
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
    chunks_c = arvados.collection.CollectionWriter(num_retries=3)
    print "Chunking genome into %s chunks of ~%s points" % (genome_chunks, chunk_points)
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = dict_reader.name() + (".%s_of_%s.interval_list" % (chunk_num, genome_chunks))
        print "Creating interval file for chunk %s" % chunk_num
        chunks_c.start_new_file(newfilename=chunk_input_name)
        chunks_c.write(interval_header)
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
            chunks_c.write(interval)
            chunk_intervals_count += 1
            if remaining_points <= 0:
                break
        if chunk_intervals_count > 0:
            print "Chunk intervals file %s saved." % (chunk_input_name)
        else:
            print "WARNING: skipping empty intervals for %s" % chunk_input_name
    chunk_input_pdh = chunks_c.finish()
    print "Chunk intervals collection saved as: %s" % (chunk_input_pdh)
    return chunk_input_pdh

def main():
    current_job = arvados.current_job()
    skip_sq_sn_regex = '_decoy$'
    if 'skip_sq_sn_regex' in current_job['script_parameters']:
        skip_sq_sn_regex = current_job['script_parameters']['skip_sq_sn_regex']
    skip_sq_sn_r = re.compile(skip_sq_sn_regex)

    genome_chunks = int(current_job['script_parameters']['genome_chunks'])
    if genome_chunks < 1:
        raise InvalidArgumentError("genome_chunks must be a positive integer")

    # Limit the scope of the interval_list collection to only those files relevant to gatk
    il_input_pdh = prepare_gatk_interval_list_collection(interval_list_coll=current_job['script_parameters']['interval_list_collection'])

    # Create an interval_list file for each chunk based on the .dict in the interval_list collection
    output_locator = create_interval_lists(genome_chunks, il_input_pdh, skip_sq_sn_r)

    # Use the resulting locator as the output for this task.
    arvados.current_task().set_output(output_locator)

    # Done!


if __name__ == '__main__':
    main()
