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
    # Ensure we have a .fa interval_list file with corresponding .fai index and .interval_list
    # see: http://gatkforums.broadinstitute.org/discussion/1601/how-can-i-prepare-a-fasta-file-to-use-as-interval_list
    ilcr = arvados.CollectionReader(interval_list_coll)
    interval_list = {}
    for ils in ilcr.all_streams():
        for ilf in ils.all_files():
            if re.search(r'\.interval_list$', ilf.name()):
                interval_list[ils.name(), ilf.name()] = ilf
    if len(interval_list) < 1:
        raise InvalidArgumentError("Expected an interval_list dict in interval_list_collection, but found none. Found [%s]" % ' '.join(ilf.name() for ilf in ils.all_files()))
    if len(interval_list) > 1:
        raise InvalidArgumentError("Expected a single interval_list dict in interval_list_collection, but found multuple. Found [%s]" % ' '.join(ilf.name() for ilf in ils.all_files()))
    for ((s_name, f_name), interval_list_f) in interval_list.items():
            ref_input = interval_list_f.as_manifest()
            break
    # Create and return a portable data hash for the ref_input manifest
    try:
        r = arvados.api().collections().create(body={"manifest_text": ref_input}).execute()
        ref_input_pdh = r["portable_data_hash"]
    except:
        raise
    return ref_input_pdh

def create_interval_lists(genome_chunks, interval_list_coll):
    rcr = arvados.CollectionReader(interval_list_coll)
    interval_list = []
    interval_list_reader = None
    for rs in rcr.all_streams():
        for rf in rs.all_files():
            if re.search(r'\.interval_list$', rf.name()):
                interval_list.append(rf)
    if len(interval_list) < 1:
        raise InvalidArgumentError("Interval_List collection does not contain any .interval_list files but one is required.")
    if len(interval_list) > 1:
        raise InvalidArgumentError("Interval_List collection contains multiple .interval_list files but only one is allowed.")
    interval_list_reader = interval_list[0]

    # Load the interval_list data
    interval_header = ""
    interval_list_lines = interval_list_reader.readlines()
    target_intervals = dict()
    targets = []
    total_len = 0
    # consume header
    while len(interval_list_lines) > 0:
        h = interval_list_lines.pop(0)
        if re.search(r'^[@]', h) is None:
            print "Finished with header"
            interval_list_lines.insert(0, h)
            break
        else:
            interval_header += h

    # process interval lines
    for interval_line in interval_list_lines:
        sn_start_stop_plus_target = interval_line.split("\t")
        if len(sn_start_stop_plus_target) != 5:
            raise InvalidArgumentError("interval_list file had line with unexpected number of columns: [%s]" % interval_line)
        sn = sn_start_stop_plus_target[0]
        start = sn_start_stop_plus_target[1]
        stop = sn_start_stop_plus_target[2]
        target = "%s_%s_%s_%s" % (sn_start_stop_plus_target[4].rstrip('\n').replace(' ','_'), sn, start, stop)
        ln = int(stop) - int(start) + 1
        target_intervals[target] = (sn, int(start), int(stop))
        targets.append(target)
        total_len += ln
    total_targets = len(targets)

    # Chunk the genome into genome_chunks equally sized pieces and create intervals files
    print "Total targets included: %s" % (total_targets)
    print "Total genome length is %s" % total_len
    total_points = total_len + (total_targets * weight_seq)
    print "Total points to split: %s" % (total_points)
    chunk_points = int(total_points / genome_chunks)
    chunks_c = arvados.collection.CollectionWriter(num_retries=3)
    print "Chunking genome into %s chunks of ~%s points" % (genome_chunks, chunk_points)
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = interval_list_reader.name() + (".%s_of_%s.interval_list" % (chunk_num, genome_chunks))
        print "Creating interval file for chunk %s" % chunk_num
        chunks_c.start_new_file(newfilename=chunk_input_name)
        chunks_c.write(interval_header)
        remaining_points = chunk_points
        while len(targets) > 0:
            target = targets.pop(0)
            if chunk_num != genome_chunks:
                # don't enforce points on the last chunk
                remaining_points -= weight_seq
            if remaining_points <= 0:
                # no space for this target, put it back on the list and close this file unless it is the last chunk
                targets.insert(0, target)
                break
            if not target_intervals.has_key(target):
                raise ValueError("target_intervals missing entry for target [%s]" % target)
            sn, start, end = target_intervals[target]
            if (end-start+1) > remaining_points:
                # not enough space for the whole sq, split it
                real_end = end
                end = remaining_points + start - 1
                assert((end-start+1) <= remaining_points)
                target_intervals[target] = (sn, end+1, real_end)
                # put target back on the list
                targets.insert(0, target)
            interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, "interval_%s_of_%s_%s" % (chunk_num, genome_chunks, target))
            if chunk_num != genome_chunks:
                # don't enforce points on the last chunk
                remaining_points -= (end-start+1)
            chunks_c.write(interval)
            chunk_intervals_count += 1
            if remaining_points <= 0:
                break
        if chunk_intervals_count > 0:
            print "Chunk intervals file %s saved." % (chunk_input_name)
        else:
            print "WARNING: skipping empty intervals for %s" % chunk_input_name
    print "Finished, writing output collection!"
    chunk_input_pdh = chunks_c.finish()
    print "Chunk intervals collection saved as: %s" % (chunk_input_pdh)
    return chunk_input_pdh

def main():
    current_job = arvados.current_job()

    genome_chunks = int(current_job['script_parameters']['genome_chunks'])
    if genome_chunks < 1:
        raise InvalidArgumentError("genome_chunks must be a positive integer")

    # Limit the scope of the interval_list collection to only those files relevant to gatk
    il_input_pdh = prepare_gatk_interval_list_collection(interval_list_coll=current_job['script_parameters']['interval_list_collection'])

    # Create an interval_list file for each chunk based on the .interval_list in the interval_list collection
    output_locator = create_interval_lists(genome_chunks, il_input_pdh)

    # Use the resulting locator as the output for this task.
    arvados.current_task().set_output(output_locator)

    # Done!


if __name__ == '__main__':
    main()
