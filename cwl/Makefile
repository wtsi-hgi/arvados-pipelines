all: HaplotypeCaller.cwl build_docker

HaplotypeCaller.cwl: FORCE 
	bash get_haplotype_caller.sh > /dev/null

build_docker: FORCE
	docker build workflow/dict_to_interval_list -t dict_to_interval_list
	docker build workflow/split_interval_list -t split_interval_list
	docker build workflow/intersect_intervals -t intersect_intervals

FORCE: