
loc code_directory   = "C:\Users\s16501\Documents\GitHub\statapar\example_2_single_dofile"
loc output_directory = "C:\Users\s16501\Documents\GitHub\statapar\example_2_single_dofile\output"

// Run the same do-file four times in parallel, once per region:
statapar init, keepdata

statapar submit, dofile("`code_directory'/example_client.do") locals(region output_directory) values("1" "`output_directory'")
statapar submit, dofile("`code_directory'/example_client.do") locals(region output_directory) values("2" "`output_directory'")
statapar submit, dofile("`code_directory'/example_client.do") locals(region output_directory) values("3" "`output_directory'")
statapar submit, dofile("`code_directory'/example_client.do") locals(region output_directory) values("4" "`output_directory'")

sysuse citytemp, clear
statapar run

// Load and compare the estimates saved by each parallel job:
eststo region1: estimates use "`output_directory'/region_1_jan-july"
eststo region2: estimates use "`output_directory'/region_2_jan-july"
eststo region3: estimates use "`output_directory'/region_3_jan-july"
eststo region4: estimates use "`output_directory'/region_4_jan-july"

sysuse citytemp, clear // Load dataset so esttab can read variable labels
esttab region1 region2 region3 region4, label
