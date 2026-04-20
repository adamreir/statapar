reg tempjan tempjuly if region==`region'
estimates save "${output_directory}/region_`region'_jan-july", replace

sleep 5000 // This will pause every process for 5 seconds - simulating a regression that takes a little longer to run...
