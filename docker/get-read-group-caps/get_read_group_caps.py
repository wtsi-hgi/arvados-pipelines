import argparse

parser = argparse.ArgumentParser(description='Converts a dict file to an interval list file')
parser.add_argument("--read_groups", help="Path to dict file", action='append')
parser.add_argument("--verify_bam_id_files", help="Output directory for interval list", action='append')
args = parser.parse_args()

with open("caps_file", "w") as caps_file:
    for read_group, verify_bam_id_file_name in zip(args.read_groups, args.verify_bam_id_files):
        alpha = None
        with open(verify_bam_id_file_name, "r") as verify_bam_id_file:
            for line in verify_bam_id_file:
                key, value = line.strip().split(':', maxsplit=1)
                if key == "Alpha":
                    alpha = value
                    break

        if alpha is None:
            raise Exception(f"Alpha is not found for file {verify_bam_id_file_name}")
        caps_file.write(read_group + "\t" + alpha + "\n")
