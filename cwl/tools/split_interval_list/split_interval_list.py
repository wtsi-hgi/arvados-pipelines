#!/usr/bin/env python

import os
import argparse

# The amount to weight each sequence contig
weight_seq = 120000

class InvalidArgumentError(Exception):
    pass

def split_interval_lists(genome_chunks, interval_list_path, out_dir):
    # Load the interval_list data

    with open(interval_list_path, "r") as f:
        interval_list_lines = f.readlines()

    interval_header = ""
    target_intervals = dict()
    targets = []
    total_len = 0

    # Consume header
    while interval_list_lines:
        header_line = interval_list_lines.pop(0)
        if not header_line[0] == "@":
            interval_list_lines.insert(0, header_line)
            break
        else:
            interval_header += header_line

    # Process interval lines
    for interval_line in interval_list_lines:
        sn_start_stop_plus_target = interval_line.split("\t")

        if len(sn_start_stop_plus_target) != 5:
            raise InvalidArgumentError("interval_list file had line with unexpected number of columns: [%s]" % interval_line)

        sn = sn_start_stop_plus_target[0]
        start = sn_start_stop_plus_target[1]
        stop = sn_start_stop_plus_target[2]
        target = "%s_%s_%s_%s" % (sn_start_stop_plus_target[4].rstrip('\n').replace(' ', '_'), sn, start, stop)
        ln = int(stop) - int(start) + 1
        target_intervals[target] = (sn, int(start), int(stop))

        targets.append(target)
        total_len += ln
    total_targets = len(targets)

    # Chunk the genome into genome_chunks equally sized pieces and create intervals files
    print("Total targets included: %s" % total_targets)
    print("Total genome length is %s" % total_len)
    total_points = total_len + (total_targets * weight_seq)
    print("Total points to split: %s" % total_points)
    chunk_points = int(total_points / genome_chunks)

    # Create new directory to store the split_interval_lists

    print("Chunking genome into %s chunks of ~%s points" % (genome_chunks, chunk_points))
    for chunk_i in range(0, genome_chunks):
        chunk_num = chunk_i + 1
        chunk_intervals_count = 0
        chunk_input_name = os.path.join(out_dir, os.path.basename(interval_list_path) + (".%s_of_%s.interval_list" % (chunk_num, genome_chunks)))
        print("Creating interval file for chunk %s" % chunk_num)

        # Create new file with the correct name and write to it
        with open(chunk_input_name, 'w+') as f:
            f.write(interval_header)

            remaining_points = chunk_points
            while targets:
                target = targets.pop(0)

                if chunk_num != genome_chunks:
                    # Don't enforce points on the last chunk
                    remaining_points -= weight_seq

                if remaining_points <= 0:
                    # No space for this target, put it back on the list and close this file unless it is the last chunk
                    targets.insert(0, target)
                    break

                if not target_intervals.has_key(target):
                    raise ValueError("target_intervals missing entry for target [%s]" % target)

                sn, start, end = target_intervals[target]
                if (end - start + 1) > remaining_points:
                    # not enough space for the whole sq, split it
                    real_end = end
                    end = remaining_points + start - 1

                    assert((end - start + 1) <= remaining_points)

                    target_intervals[target] = (sn, end + 1, real_end)
                    # Put target back on the list
                    targets.insert(0, target)

                interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, "interval_%s_of_%s_%s" % (chunk_num, genome_chunks, target))

                if chunk_num != genome_chunks:
                    # Don't enforce points on the last chunk
                    remaining_points -= (end - start + 1)

                f.write(interval)

                chunk_intervals_count += 1
                if remaining_points <= 0:
                    break

        if chunk_intervals_count > 0:
            print("Chunk intervals file %s saved." % chunk_input_name)
        else:
            print("WARNING: skipping empty intervals for %s" % chunk_input_name)

    print("Finished, writing output collection!")


def main():
    parser = argparse.ArgumentParser(description='Create Interval List')
    parser.add_argument("--path", help="path to dict file")
    parser.add_argument("--output_dir", help="output directory for interval list")
    parser.add_argument("--chunks", help="number of genome chunks to split into")
    args = vars(parser.parse_args())

    path_to_ilp = args['path']
    out_dir = args['output_dir']
    genome_chunks = int(args['chunks'])

    if genome_chunks < 1:
        raise InvalidArgumentError("genome_chunks must be a positive integer")

    # Create an interval_list file for each chunk based on the .interval_list in the interval_list collection
    split_interval_lists(genome_chunks, path_to_ilp, out_dir)


if __name__ == '__main__':
    main()
