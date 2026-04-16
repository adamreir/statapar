reg tempjan tempjuly if region==`region'
estimates save "${output_directory}/region_`region'_jan-july", replace

sleep 5000
