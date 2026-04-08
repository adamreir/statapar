* Author: Adam Reiremo
* Date: March 27, 2026
* Content: Simple program for running multiple Stata processes: a single do-file with separate local macros. 
* Usage: 
	* 1. Initiate a new session: statapar init, dofile(path_to_existing_dofile) macros(name_of_macros) [maxjobs(maximum number of simultaneous processes)]
	* 2. Submitt process: statapar submit, macro1(string) macro2(string) // macro1 and macro2 are names using `macros' from 1.
	* 3. Run: statapar run
	
********************************************************************************
***************************** Access point *************************************
********************************************************************************

/*
tmp block to redefine programs
*/
cap prog drop statapar
cap prog drop statapar_run
cap prog drop statapar_init
cap prog drop __statapar_close_sh

/*
\end
*/


prog statapar
	version 16
	
	gettoken subcmd 0 : 0, parse(" ,")
	local subcmd = trim("`subcmd'")
	
	cap assert inlist("`subcmd'", "init", "run", "submit")
	if _rc {
		di as error `"Statapar subcommand '`subcmd'' not recognized"'
		exit 199
	}
	
	statapar_`subcmd' `0'
end
	
*

prog def statapar_init
	syntax, dofile(string) macros(string) [maxjobs(integer 5)]
	
	di "Init new multiprocessing environment"
	// Check if dofile exists
	confirm file `dofile'
	
	// Restart environment if it's already active
	if `"${statapar_tmpfiles}"'!="" {
		global statapar_active = 0
		di "Delete old multiprocessing environment"
		foreach file of global statapar_tmpfiles {
			rm `file'
		}
		global statapar_tmpfiles = ""
		cap prog drop statapar_submit
	}
	
	cap assert inlist(c(os), "Windows", "Unix") 
	if _rc {
		di as error "Statapar only works in Windows or Unix operating systems. "
	}
	
	if c(os)=="Unix" 	loc unix = 1
	else 			loc unix = 0
	
	// Figure out paths and filenames for stata prog and shell file
	loc username = "`c(username)'"
	loc tmpdir = "`c(tmpdir)'"
	
	loc n = 1
	while "`prog_file'" == "" {
		cap confirm new file "`tmpdir'/statapar_prog_`username'_`n'.do"
		if !_rc {
			loc prog_file = "`tmpdir'/statapar_prog_`username'_`n'.do"
		}
		loc n = `n'+1
	}
	
	if `unix'	loc ext = "sh"
	else 		loc ext = "ps1"
	loc n = 1
	while "`shell_file'" == "" {
		cap confirm new file "`tmpdir'/statapar_shell_`username'_`n'.`ext'"
		if !_rc {
			loc shell_file = "`tmpdir'/statapar_shell_`username'_`n'.`ext'"
		}
		loc n = `n'+1
	}
	
	// Make stata prog that i) makes a do-file, and ii) adds that do-file to the shell file
	file open statapar_init_file using "`prog_file'", write text replace
	
	file write statapar_init_file `""' _n
	file write statapar_init_file `"cap prog drop statapar_submit"' _n
	file write statapar_init_file `"prog statapar_submit"' _n
	
	// Turn list of macros into "opt1(string) opt2(string)"
	foreach loc of local macros {
		loc syntax_macros = "`syntax_macros' `loc'(string)"
	}
	
	file write statapar_init_file `"	syntax, `syntax_macros'"' _n
	file write statapar_init_file `"	"' _n
	
	// The Stata program have to figure out the name of the do file it's going to create
	file write statapar_init_file `"	// Figure out name of do-file"' _n
	file write statapar_init_file `"	loc n = 1"' _n
	file write statapar_init_file `"	while "\`do_file'" == "" { "' _n
	file write statapar_init_file `"		cap confirm new file "`tmpdir'/statapar_do_`username'_\`n'.do""' _n
	file write statapar_init_file `"		if !_rc {"' _n
	file write statapar_init_file `"			loc do_file = "`tmpdir'/statapar_do_`username'_\`n'.do""' _n
	file write statapar_init_file `"		}"' _n
	file write statapar_init_file `"		loc n = \`n'+1"' _n
	file write statapar_init_file `"	}"' _n
	file write statapar_init_file `"	"' _n
	
	// Add the soon-to-be created do file to the shell file
	file write statapar_init_file `"	// Add do-file to shell file"' _n
	
	file write statapar_init_file `"	confirm file "`shell_file'""' _n
	file write statapar_init_file `"	qui file open statapar_shell_file using "`shell_file'", write text append"' _n
	file write statapar_init_file `"	file write statapar_shell_file `""\`do_file'""' _n"' _n
	file write statapar_init_file `"	file close statapar_shell_file"' _n
	file write statapar_init_file "" _n
	
	// Now create the do file
	file write statapar_init_file `"	// Write do-file"' _n
	file write statapar_init_file `"	global statapar_tmpfiles = `"\${statapar_tmpfiles} \`do_file'"'"' _n
	file write statapar_init_file `"	qui file open statapar_do_file using "\`do_file'", write text replace"' _n
	file write statapar_init_file `"	file write statapar_do_file "" _n"' _n
	
	// Turn of logging
	file write statapar_init_file `"	file write statapar_do_file "capture log close _all" _n"' _n
	file write statapar_init_file `"	file write statapar_do_file "set more off" _n"' _n
	
	file write statapar_init_file `"	file write statapar_do_file "" _n"' _n
	foreach loc of local macros {
		file write statapar_init_file `"	file write statapar_do_file `"loc `loc' = `"\``loc''"'"' _n"' _n
	}
	file write statapar_init_file `"	file write statapar_do_file "" _n "' _n
	
	file write statapar_init_file `""' _n
	file write statapar_init_file `"	// run the main do-file after defining locals"' _n
	file write statapar_init_file `"	file write statapar_do_file `"include "`dofile'""' _n "' _n
	file write statapar_init_file `"	"' _n
	file write statapar_init_file `"	file close statapar_do_file"' _n
	file write statapar_init_file `"end"' _n
	
	file close statapar_init_file
	
	do "`prog_file'" // Run the do-file defining statapar_submit made above.
	rm "`prog_file'"	

	// Make shell file
	qui file open statapar_shell_file using "`shell_file'", write text replace
	file write statapar_shell_file `""' _n
		
	if `unix' { // Bash script
		file write statapar_shell_file `"MAXJOBS=`maxjobs'"' _n
		file write statapar_shell_file `"pids=()"' _n
		
		file write statapar_shell_file `"run_stata() {"' _n
		file write statapar_shell_file `"	nice -19 nohup stata-mp -b do "$1" & "' _n
		file write statapar_shell_file `"	pids+=($!)"' _n
		file write statapar_shell_file `"}"' _n
		file write statapar_shell_file `""' _n
		
		file write statapar_shell_file `"FILES=("' _n
		
	}
	else { // Powershell script
		file write statapar_shell_file `"\$MAXJOBS = `maxjobs'"' _n
		file write statapar_shell_file `"\$processes = @()"' _n

		loc stata_exe = "`c(sysdir_stata)'Stata`c(edition_real)'-64.exe"
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"# Path to Stata executable"' _n
		file write statapar_shell_file `"\$stataExe = "`stata_exe'""' _n
		
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"function Start-StataJob {"' _n
		file write statapar_shell_file `"	param([string]\$DoFile)"' _n
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"	\$proc = Start-Process "' //_n
		file write statapar_shell_file  "`" _n
		file write statapar_shell_file `"	-FilePath \$stataExe "'
		file write statapar_shell_file  "`" _n
		/*
		file write statapar_shell_file `"	-ArgumentList "/e", "-q", "do", ""'
		file write statapar_shell_file  "`"  
		file write statapar_shell_file  `""\$DoFile"'
		file write statapar_shell_file  "`"
		file write statapar_shell_file  `""""' 
		file write statapar_shell_file  " `" _n
		*/
		file write statapar_shell_file `"	-ArgumentList "/e", "-q", "do", \$DoFile"'  // Improvement suggested by ChatGPT. Supposedly makes it safer? 
		file write statapar_shell_file  " `"  _n
		
		file write statapar_shell_file `"	-PassThru "' 
		file write statapar_shell_file  "`" _n
		file write statapar_shell_file `"	-WindowStyle Hidden"' _n
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"	\$proc.PriorityClass = "BelowNormal""' _n
		file write statapar_shell_file `"	return \$proc"' _n
		file write statapar_shell_file `"}"' _n
		
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"\$FILES = @("' _n
	}
	file close statapar_shell_file
	
	// Store information for subsequent calls
	global statapar_tmpfiles = `"`shell_file'"'
	global statapar_shellfile = `"`shell_file'"'
	global statapar_active = 1
	
end

prog __statapar_close_sh
	// Writes the rest of the "shell" file.  

	if "${statapar_active}"!="1" {
		di as error "Statapar session not open."
		exit 198
	}
	
	if c(os)=="Unix" 	loc unix = 1
	else 			loc unix = 0
	
	qui file open statapar_shell_file using "${statapar_shellfile}", write text append
	
	if `unix' {
		file write statapar_shell_file `")"' _n
		file write statapar_shell_file `""' _n
		
		file write statapar_shell_file `"for f in "\${FILES[@]}"; do"' _n
		file write statapar_shell_file `"	run_stata "\$f""' _n
		file write statapar_shell_file `"	"' _n
		file write statapar_shell_file `"	# If MAXJOBS running wait for one to finish"' _n
		file write statapar_shell_file `"	while (( \$(jobs -rp | wc -l) >= MAXJOBS )); do "' _n
		file write statapar_shell_file `"		wait -n"' _n
		file write statapar_shell_file `"	done"' _n
		file write statapar_shell_file `"done"' _n
		file write statapar_shell_file `""' _n
		
		file write statapar_shell_file `" # Wait for remaining jobs"' _n
		file write statapar_shell_file `"wait"' _n
	}
	else {
		file write statapar_shell_file ")" _n
		file write statapar_shell_file "" _n
		
		file write statapar_shell_file `"foreach (\$f in \$FILES) {"' _n
		file write statapar_shell_file `"    \$processes += Start-StataJob -DoFile \$f"' _n
		
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"    # Keep only still-running processes"' _n
		file write statapar_shell_file `"    \$processes = @(\$processes | Where-Object { -not \$_.HasExited })"' _n
		
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"    # If MAXJOBS are running, wait until one finishes"' _n
		file write statapar_shell_file `"    while (\$processes.Count -ge \$MAXJOBS) {"' _n
		file write statapar_shell_file `"	Start-Sleep -Seconds 1"' _n
		file write statapar_shell_file `"	\$processes = @(\$processes | Where-Object { -not \$_.HasExited })"' _n
		file write statapar_shell_file `"    }"' _n
		file write statapar_shell_file `"}"' _n

		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"# Wait for remaining jobs"' _n
		file write statapar_shell_file `"while ((\$processes | Where-Object { -not \$_.HasExited }).Count -gt 0) {"' _n
		file write statapar_shell_file `"    Start-Sleep -Seconds 1"' _n
		file write statapar_shell_file `"    \$processes = \$processes | Where-Object { -not \$_.HasExited }"' _n
		file write statapar_shell_file `"}"' _n
		
		file write statapar_shell_file `""' _n
		file write statapar_shell_file `"foreach (\$p in \$processes) {"' _n
		file write statapar_shell_file `"	if (\$null -ne \$p -and -not \$p.HasExited) {"' _n
		file write statapar_shell_file `"		\$p.WaitForExit()"' _n
		file write statapar_shell_file `"	}"' _n
		file write statapar_shell_file `"}"' _n
	}
	
	
	file close statapar_shell_file
	
end

prog statapar_run
	// Finish the shell file (with a function call) and exectute. 
	
	if "${statapar_active}"!="1" {
		di as error "Statapar session not open."
		exit 198
	}
	
	__statapar_close_sh
	
	if c(os)=="Unix" 	loc unix = 1
	else 			loc unix = 0
	
	
	if `unix' {
		! source "${statapar_shellfile}"
	}
	else {
		shell powershell -ExecutionPolicy Bypass -File "${statapar_shellfile}"
	}
	
	foreach file of global statapar_tmpfiles {
		rm `file'
	}
	global statapar_tmpfiles = ""
	global statapar_shellfile = ""
	global statapar_active = 0
end
