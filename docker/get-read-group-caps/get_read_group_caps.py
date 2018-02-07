import argparse

parser = argparse.ArgumentParser(description='Converts a dict file to an interval list file')
parser.add_argument("--read_groups", help="Path to dict file", action='append')
parser.add_argument("--verify_bam_id_files", help="Output directory for interval list", action='append')
args = parser.parse_args()

with open("caps_file", "w") as caps_file:
    for read_group, verify_bam_id_file_name in zip(args.read_groups, args.verify_bam_id_files):
        with open(verify_bam_id_file_name, "r") as verify_bam_id_file:
            file_text = verify_bam_id_file.read()
            alpha = file_text[file_text.find("Alpha:") + len("Alpha:"):]

        caps_file.write(read_group + "\t" + alpha + " \n")
