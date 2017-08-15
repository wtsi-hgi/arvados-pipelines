"""
Convert a bed file to an interval list
"""

import argparse

def main():
    parser = argparse.ArgumentParser(description='Convert a bed file to an interval list')
    parser.add_argument("--input", required=True, help="Input file")
    parser.add_argument("--header", required=True, help="Header file")

    args = parser.parse_args()

    with open(args.input, "r") as f:
        bed_lines = f.readlines()

    with open(args.header, "r") as f:
        new_file = f.readlines() # Add the header file to start the file

    for line in bed_lines:
        line_parts = line.split("\t")
        line_parts.insert(3, "+")
        new_file.append("\t".join(line_parts))

    with open("output.bed", "w") as f:
        f.writelines(new_file)

if __name__ == "__main__":
    main()