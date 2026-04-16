* Model 2: quadratic
* Add a squared term to allow for a non-linear relationship

sysuse citytemp, clear

gen tempjuly_sq = tempjuly^2
reg tempjan tempjuly tempjuly_sq

estimates save "${output_directory}/model_quadratic", replace
