
// Enter folders: 

loc code_directory    = "" // "C:\Users\s16501\Documents\GitHub\statapar\example_1_multiple_dofiles"
global output_directory = "" //"C:\Users\s16501\Documents\GitHub\statapar\example_1_multiple_dofiles\output"

// Run three different do-files in parallel, each estimating a different model:
statapar init

//set trace on

statapar submit, dofile("`code_directory'/model_ols.do")
statapar submit, dofile("`code_directory'/model_quadratic.do")
statapar submit, dofile("`code_directory'/model_region_fe.do")

statapar run

// Load and compare the estimates saved by each parallel job:
eststo ols:       estimates use "${output_directory}/model_ols"
eststo quadratic: estimates use "${output_directory}/model_quadratic"
eststo region_fe: estimates use "${output_directory}/model_region_fe"

sysuse citytemp, clear // Load dataset so esttab can read variable labels
esttab ols quadratic region_fe, label
