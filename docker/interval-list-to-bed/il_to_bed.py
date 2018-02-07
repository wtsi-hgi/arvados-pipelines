"""
Converts a interval list to a bed file
"""

import argparse

def main():
    parser = argparse.ArgumentParser(description='Converts interval list to a bed file. Also outputs the header file')
    parser.add_argument("--input", "-i", required=True, help="Input interval list")

    args = parser.parse_args()

    with open(args.input, "r") as f:
        il_lines = f.readlines()

    new_file = []
    header = []

    for line in il_lines:
        if line.startswith("@"):
            header.append(line)
        else:
            new_file.append(line.replace("\t+", ""))

    with open("output.bed", "w") as f:
        f.writelines(new_file)

    with open("header.txt", "w") as f:
        f.writelines(header)

if __name__ == "__main__":
    main()