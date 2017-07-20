FROM python:2


# Install python and clone script from github
RUN \

  # script to turn dictionary into interval list  
  wget https://raw.githubusercontent.com/yejinyou/arvados-pipelines/master/scripts_revised/create_interval_list/gatk-create-interval-lists.py

  # script to split intervals
  wget https://raw.githubusercontent.com/yejinyou/arvados-pipelines/master/scripts_revised/split_interval_list/gatk-split-interval-list.py

 
CMD ["/bin/bash"]

