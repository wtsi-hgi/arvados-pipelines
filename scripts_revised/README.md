## Interval List Scripts

To split intervals run the command
```
cwl-runner split_interval.cwl <interval_list_inputs.yml>
```
The <interval_list_inputs.yml> object should contain the following inputs:
`python_script (string), number_of_intervals (integer), interval_list (file), output_directory (string)`

interval_list_inputs_format.yml

```
python_script: /path/to/gatk-interval-list.py
number_of_intervals: num_to_split
interval_list:
  class: File
  path: /path/to/interval_list_to_split
output_directory: /path/to/desired/output/directory
```

To convert dictionary into split intervals run the command

```
cwl-runner convert.cwl <dict_inputs.yml>
```

The <dict_inputs.yml> object should contain the following inputs:
`python_script (string), genome_chunks (integer), dictionary (file), directory (string)`

```
python_script: /path/to/gatk-create-interval-lists.py
genome_chunks: num_genome_chunks
dictionary:
  class: File
  path: /path/to/dictionary_to_convert
directory: /path/to/desired/output/directory
```
