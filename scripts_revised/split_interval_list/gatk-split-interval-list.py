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

def create_interval_lists(genome_chunks, interval_list_coll, todir):

    # Load the interval_list data

    interval_list_reader = interval_list_coll
    
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

    # create new directory to store the split_interval_lists
    directory = os.path.join(todir, 'split_intervals')
    os.makedirs(directory)

    print "Chunking genome into %s chunks of ~%s points" % (genome_chunks, chunk_points)
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = os.path.basename(interval_list_reader.name) + (".%s_of_%s.interval_list" % (chunk_num, genome_chunks))
        print "Creating interval file for chunk %s" % chunk_num

        #change working directory
        os.chdir(directory)

        #create new file with the correct name and write to it
        f = open(chunk_input_name, 'w+')
        f.write(interval_header)

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
        
    print "Finished, writing output collection!"

    #print the output directory
    chunk_input_pdh = directory

    print "Chunk intervals collection saved as: %s" % (chunk_input_pdh)
    return chunk_input_pdh

def main():

    #parse the arguments from command line
   
    genome_chunks = int(sys.argv[1])
    path_to_ilp = sys.argv[2]
    
    try: 
     todir = sys.argv[3]
    except:
     todir = os.getcwd()
  
    #change to working directory
    os.chdir(todir)

    #open interval_list file
    il_input = open(path_to_ilp, 'r')
    
    if genome_chunks < 1:
        raise InvalidArgumentError("genome_chunks must be a positive integer")
    
    # Create an interval_list file for each chunk based on the .interval_list in the interval_list collection
    output_locator = create_interval_lists(genome_chunks, il_input, todir)


if __name__ == '__main__':
    main()
