#!/usr/bin/env python

import os
import re
import argparse

# The amount to weight each sequence contig
weight_seq = 120000

class InvalidArgumentError(Exception):
    pass

class APIError(Exception):
    pass

def dict_to_interval_list(input_file, output_file):
    # Load the dict data

    interval_header = ""

    with open(input_file, 'r') as f:
        dict_lines = f.readlines()

    dict_header = dict_lines.pop(0)
    if re.search(r'^@HD', dict_header) is None:
        raise InvalidArgumentError("Dict file in reference collection does not have correct header: [%s]" % dict_header)
    interval_header += dict_header
    print("Dict header is %s" % dict_header)
    sn_intervals = dict()
    sns = []
    total_len = 0
    for line in dict_lines:
        if re.search(r'^@SQ', line) is None:
            raise InvalidArgumentError("Dict file contains malformed SQ line: [%s]" % line)
        interval_header += line

        # Locate the SN and LN parameters
        sn = None
        ln = None
        for tagval in line.split("\t"):
            tv = tagval.split(":", 1)
            if tv[0] == "SN":
                sn = tv[1]
            if tv[0] == "LN":
                ln = tv[1]
            if sn and ln:
                break
        if not (sn and ln):
            raise InvalidArgumentError("Dict file SQ entry missing required SN and/or LN parameters: [%s]" % line)

        if sn_intervals.has_key(sn):
            raise InvalidArgumentError("Dict file has duplicate SQ entry for SN %s: [%s]" % (sn, line))

        sn_intervals[sn] = (1, int(ln))
        sns.append(sn)
        total_len += int(ln)
    total_sequences = len(sns)

    # Chunk the genome into genome_chunks equally sized pieces and create intervals files
    print("Total sequences included: %s" % (total_sequences))
    print("Total genome length is %s" % total_len)
    total_points = total_len + (total_sequences * weight_seq)
    print("Total points to split: %s" % (total_points))
    
    with open(output_file, "w+") as out_file:
        out_file.write(interval_header)

        remaining_points = total_points
        chunk_num = 1
        while sns:
            chunk_num += 1
            sn = sns.pop(0)
            remaining_points -= weight_seq
            if remaining_points <= 0:
                sns.insert(0, sn)
                break
            if not sn_intervals.has_key(sn):
                raise ValueError("sn_intervals missing entry for sn [%s]" % sn)
            start, end = sn_intervals[sn]
            if (end - start + 1) > remaining_points:
                # Not enough space for the whole sq, split it
                real_end = end
                end = remaining_points + start - 1
                assert((end - start + 1) <= remaining_points)
                sn_intervals[sn] = (end + 1, real_end)
                sns.insert(0, sn)
            interval = "%s\t%s\t%s\t+\t%s\n" % (sn, start, end, sn)
            remaining_points -= (end - start + 1)

            out_file.write(interval)

            if remaining_points <= 0:
                break


def main():
    parser = argparse.ArgumentParser(description='Converts a dict file to an interval list file')
    parser.add_argument("--path", help="Path to dict file")
    parser.add_argument("--output_dir", help="Output directory for interval list")
    args = parser.parse_args()

    # Create an interval_list file for each chunk based on the .dict in the reference collection

    basename = os.path.splitext(os.path.basename(args.path))[0] + '.interval_list'

    dict_to_interval_list(args.path, os.path.join(args.output_dir, basename))


if __name__ == '__main__':
    main()
