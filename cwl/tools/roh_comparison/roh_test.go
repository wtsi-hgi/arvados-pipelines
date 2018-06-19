package main

import (
	"fmt"
	"testing"
)

func TestSampleBEDsFromROH(t *testing.T) {
	file1 := "/home/sjc/Downloads/sample_id_mappings_egan_to_elgh"
	rohfile := "/home/sjc/testdata/ROH_regions/allROH.txt"

	m, err := mapSampleNames(file1)
	fmt.Println(m)
	if err != nil {
		t.Errorf("%s", err.Error())
	}

	err = sampleBEDsFromROH(rohfile, m)
	if err != nil {
		t.Errorf("%s", err.Error())
	}

}
