
// Point Stata towards folders before running: 

loc code_directory      = "" // Where Stata will find model_ols.do, model_quadratic.do, and model_region_fe.do. 
global output_directory = "`code_directory'/output" // Where model_*.do will place regression results (this global will be accessible from the model_*.do do-files).

// Run three different do-files in parallel, each estimating a different model:
statapar init

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
