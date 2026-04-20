
// Point Stata towards folders before running: 
loc code_directory      = "" // Where Stata will find example_client.do
global output_directory = "" // Where example_client.do will place regression results (this global will be accessible from example_client.do)

// Run the same do-file four times in parallel, once per region:
statapar init, keepdata

statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("1")
statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("2")
statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("3")
statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("4")

sysuse citytemp, clear
statapar run

// Load and compare the estimates saved by each parallel job:
eststo region1: estimates use "${output_directory}/region_1_jan-july"
eststo region2: estimates use "${output_directory}/region_2_jan-july"
eststo region3: estimates use "${output_directory}/region_3_jan-july"
eststo region4: estimates use "${output_directory}/region_4_jan-july"

sysuse citytemp, clear // Load dataset so esttab can read variable labels
esttab region1 region2 region3 region4, label
