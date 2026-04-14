* Model 3: region fixed effects
* Control for systematic differences across census regions

sysuse citytemp, clear

reg tempjan tempjuly i.region

estimates save "`output_directory'/model_region_fe", replace
