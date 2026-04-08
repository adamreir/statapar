

loc code_directory   = "C:\Users\s16501\Documents\GitHub\statapar\example" // Where to find example_client.do
loc output_directory = "C:\Users\s16501\Documents\GitHub\statapar\example\output" // A folder where Stata can store estimates from example_client.do

// Run regional regressions in parallel: 
statapar init, dofile("`code_directory'/example_client.do") macros(region output_directory) maxjobs(3)

statapar submit, region(1) output_directory("`output_directory'")
statapar submit, region(2) output_directory("`output_directory'")
statapar submit, region(3) output_directory("`output_directory'")
statapar submit, region(4) output_directory("`output_directory'")

statapar run

// Fetch estimates stored during the above execution

eststo region1: estimates use "`output_directory'/region_1_jan-july"
eststo region2: estimates use "`output_directory'/region_2_jan-july"
eststo region3: estimates use "`output_directory'/region_3_jan-july"
eststo region4: estimates use "`output_directory'/region_4_jan-july"

sysuse citytemp, clear // For esttab: estab reads variable labels from variables in memory

esttab region1 region2 region3 region4,  label
