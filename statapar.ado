* Author: Adam Reiremo
* Date: March 27, 2026
* Content: Simple program for running multiple Stata do-files in parallel, with optional local macros per job.
* Usage:
	* 1. Initiate a new session: statapar init [max_cpu(max logical CPUs to use; default: floor(c(processors_mach)/2))]
	* 2. Submit a job: statapar submit, dofile(path) [locals(name1 name2 ...) values("val1" "val2" ...)]
	* 3. Run: statapar run

********************************************************************************
***************************** Access point *************************************
********************************************************************************

cap prog drop statapar
cap prog drop statapar_run
cap prog drop statapar_init
cap prog drop statapar_submit
cap prog drop __statapar_close_sh

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
	syntax [, max_cpu(integer 0) force noglobal keepdata]

	// Determine max_cpu (total logical CPUs available to statapar)
	local default_max_cpu = max(floor(c(processors_mach)/2), 1)
	local user_set_max_cpu = (`max_cpu' != 0)  // track whether user explicitly passed max_cpu
	if `max_cpu' == 0 {
		local max_cpu = `default_max_cpu'
	}
	else if `max_cpu' > `default_max_cpu' & "`force'" == "" {
		di as error "max_cpu(`max_cpu') exceeds the recommended limit of `default_max_cpu' (half of c(processors_mach)=`c(processors_mach)')."
		di as error "Use the force option to override: statapar init, max_cpu(`max_cpu') force"
		exit 198
	}

	// On lucia.nhh.no, cap max_cpu at 4 unless force is specified
	if `"`c(hostname)'"' == "lucia.nhh.no" {
		local lucia_cap = 4
		if `max_cpu' > `lucia_cap' & `user_set_max_cpu' & "`force'" == "" {
			di as error "max_cpu(`max_cpu') exceeds the limit of `lucia_cap' on `c(hostname)'."
			di as error "Use the force option to override: statapar init, max_cpu(`max_cpu') force"
			exit 198
		}
		else if `max_cpu' > `lucia_cap' & "`force'" == "" {
			// Default exceeded cap — silently apply cap
			local max_cpu = `lucia_cap'
		}
	}

	// Derive max_jobs: largest integer s.t. max_jobs * c(processors) < max_cpu
	local maxjobs = max(floor((`max_cpu' - 1) / c(processors)), 1)

	// Restart environment if it's already active
	if `"${statapar_tmpfiles}"'!="" {
		global statapar_active = 0
		di "Delete old multiprocessing environment"
		foreach file of global statapar_tmpfiles {
			rm `file'
		}
		global statapar_tmpfiles = ""
		cap rm `"${statapar_datafile}"'
		global statapar_datafile = ""
	}
	
	di "Init new multiprocessing environment (max_cpu=`max_cpu', maxjobs (maximum # parallel jobs) =`maxjobs')"

	cap assert inlist(c(os), "Windows", "Unix")
	if _rc {
		di as error "Statapar only works in Windows or Unix operating systems. "
	}

	if c(os)=="Unix" 	loc unix = 1
	else 			loc unix = 0

	loc username = "`c(username)'"
	loc tmpdir = "`c(tmpdir)'"

	// Figure out path for data tempfile if keepdata is specified
	if "`keepdata'" != "" {
		loc n = 1
		while `"`data_file'"' == "" {
			cap confirm new file `"`tmpdir'/statapar_data_`username'_`n'.dta"'
			if !_rc {
				loc data_file = `"`tmpdir'/statapar_data_`username'_`n'.dta"'
			}
			loc n = `n'+1
		}
		global statapar_datafile = `"`data_file'"'
		save `"`data_file'"', replace
	}
	else {
		global statapar_datafile = ""
	}

	// Figure out path for shell file
	if `unix'	loc ext = "sh"
	else 		loc ext = "ps1"
	loc n = 1
	while `"`shell_file'"' == "" {
		cap confirm new file `"`tmpdir'/statapar_shell_`username'_`n'.`ext'"'
		if !_rc {
			loc shell_file = `"`tmpdir'/statapar_shell_`username'_`n'.`ext'"'
		}
		loc n = `n'+1
	}

	// Make shell file
	qui file open statapar_shell_file using `"`shell_file'"', write text replace
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
		file write statapar_shell_file `"	-ArgumentList "/e", "-q", "do", \$DoFile"'
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
	global statapar_noglobal = "`noglobal'"

end

prog statapar_submit
	syntax, dofile(string) [locals(string) values(string asis)]

	if "${statapar_active}"!="1" {
		di as error "Statapar session not open."
		exit 198
	}
	
	// Validate locals and values
	if `"`locals'"' != "" {
		if `"`values'"' == "" {
			di as error "values() must be specified when locals() is specified."
			exit 198
		}
		local nlocals : word count `locals'
		local nvalues : word count `values'
		if `nlocals' != `nvalues' {
			di as error "locals() and values() must have the same number of elements."
			exit 198
		}
		// Check that each value is enclosed in double quotes
		local nquotes = length(`"`values'"') - length(subinstr(`"`values'"', `"""', "", .))
		if `nquotes' < 2 * `nvalues' {
			di as error `"Each element of values() must be enclosed in double quotes, e.g. values("val1" "val2")."'
			exit 198
		}
	}

	// Append .do extension if missing
	if substr(`"`dofile'"', -3, 3) != ".do" {
		local dofile = `"`dofile'.do"'
	}

	// Check dofile exists
	confirm file `"`dofile'"'

	loc username = `"`c(username)'"'
	loc tmpdir = `"`c(tmpdir)'"'

	// Find a unique temp do-file path
	loc n = 1
	while `"`do_file'"' == "" {
		cap confirm new file `"`tmpdir'/statapar_do_`username'_`n'.do"'
		if !_rc {
			loc do_file = `"`tmpdir'/statapar_do_`username'_`n'.do"'
		}
		loc n = `n'+1
	}

	// Append do-file path to shell file
	qui file open statapar_shell_file using "${statapar_shellfile}", write text append
	file write statapar_shell_file `""`do_file'""' _n
	file close statapar_shell_file

	// Write the temp do-file
	global statapar_tmpfiles = `"${statapar_tmpfiles} `do_file'"'
	qui file open statapar_do_file using `"`do_file'"', write text replace
	file write statapar_do_file "" _n
	file write statapar_do_file "capture log close _all" _n
	file write statapar_do_file "set more off" _n
	file write statapar_do_file "" _n

	// Global macros from main environment
	if "${statapar_noglobal}" == "" {
		local globs : all globals
		foreach g of local globs {
			file write statapar_do_file `"global `g' `"${`g'}"'"' _n
		}
		file write statapar_do_file "" _n
	}

	// Load dataset from main environment if keepdata was specified
	if `"${statapar_datafile}"' != "" {
		file write statapar_do_file `"use `"${statapar_datafile}"', clear"' _n
		file write statapar_do_file "" _n
	}

	// Write local assignments if provided
	if `"`locals'"' != "" {
		local nlocals : word count `locals'
		forvalues i = 1/`nlocals' {
			local lname : word `i' of `locals'
			local lval  : word `i' of `values'
			file write statapar_do_file `"loc `lname' = "`lval'""' _n
		}
		file write statapar_do_file "" _n
	}

	// Run the user's do-file
	file write statapar_do_file `"include "`dofile'""' _n

	file close statapar_do_file

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

	// Change to temp directory so Stata background processes write logs there
	loc cwd = c(pwd)
	loc tmpdir = c(tmpdir)
	qui cd `"`tmpdir'"'

	if `unix' {
		! source "${statapar_shellfile}"
	}
	else {
		shell powershell -ExecutionPolicy Bypass -File "${statapar_shellfile}"
	}

	// Delete log files produced by background processes
	foreach file of global statapar_tmpfiles {
		if substr(`"`file'"', -3, 3) == ".do" {
			loc logfile = substr(`"`file'"', 1, length(`"`file'"') - 3) + ".log"
			cap rm `"`logfile'"'
		}
	}

	// Restore working directory
	qui cd `"`cwd'"'

	foreach file of global statapar_tmpfiles {
		rm `file'
	}
	global statapar_tmpfiles = ""
	global statapar_shellfile = ""
	global statapar_active = 0
	global statapar_noglobal = ""
	if `"${statapar_datafile}"' != "" cap rm `"${statapar_datafile}"'
	global statapar_datafile = ""
end
