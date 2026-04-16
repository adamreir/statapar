* Model 1: simple OLS
* Regress January temperature on July temperature (full sample)

sysuse citytemp, clear

reg tempjan tempjuly

estimates save "${output_directory}/model_ols", replace
