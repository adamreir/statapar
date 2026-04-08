{smcl}
{* *! version 0.0.1 29March2026}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:statapar} {hline 2}}Run a do-file across many parameter combinations in parallel{p_end}
{p2col:}{browse "https://github.com/adamreir/statapar":(View on GitHub)}{p_end}
{p2colreset}{...}

{marker TOC}{...}
{title:Table of Contents}

    {help statapar##description:Description}
    {help statapar##overview:Overview}
    {help statapar##syntax:Syntax}
    {help statapar##options:Options}
    {help statapar##examples:Examples}
    {help statapar##usecases:Use cases}
    {help statapar##hood:How it works}
    {help statapar##author:Author}

{marker description}{...}
{title:Description}

{pstd}
{cmd:statapar} lets you run multiple Stata processes in parallel, executing a single do-file with different local macros.
This is useful whenever you have a do-file that produces one result (e.g. estimates a model, produces a table, runs a simulation)
and you want to run it across many parameter combinations without waiting for each run to finish before starting the next.

{pstd}
A typical {cmd:statapar} session has three steps:

{phang2}1. Declare a new session with {cmd:statapar init}, specifying which do-file to run and which local macros it expects.{p_end}
{phang2}2. Call {cmd:statapar submit} once per job, passing the macro values for that job. This step tells {cmd:statapar} to add a pass through the do-file with the provided macros to the list of jobs to do.{p_end}
{phang2}3. Call {cmd:statapar run} to launch all queued jobs in parallel and wait until they all finish. Note that {cmd:statapar} restricts the number of parallel processes to leave CPU resources for other jobs and users.{p_end}

{pstd}
{cmd:statapar} works on both Windows (untested) and Unix/Mac.

{marker overview}{...}
{title:Overview}

{pstd}
{cmd:statapar} runs in three steps

{p2colset 9 25 27 2}{...}
{p2col :{cmd:statapar init}}Set up a new parallel session{p_end}
{p2col :{cmd:statapar submit}}Queue a job with a specific set of parameter values{p_end}
{p2col :{cmd:statapar run}}Execute all queued jobs in parallel{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Step 1 — initialize a session:

{p 8 16 2}
{cmd:statapar init,} {opt dofile(path)} {opt macros(namelist)} [{opt maxjobs(#)}]

{pstd}
Step 2 — queue a job (repeat once per desired parameter combination):

{p 8 16 2}
{cmd:statapar submit,} {it:macro1}{cmd:(}{it:value}{cmd:)} [{it:macro2}{cmd:(}{it:value}{cmd:)} ...]

{pstd}
Step 3 — run all queued jobs:

{p 8 16 2}
{cmd:statapar run}

{marker options}{...}
{title:Options}

{pstd}
{ul:statapar init options}

{phang}
{opt dofile(path)} specifies the do-file to run in Parallel. This do-file will be executed once per submitted job.
The local macros provided to {cmd statapar submit} are autmatically available for this do-file (see example below). Required.

{phang}
{opt macros(namelist)} specifies the names of the local macros that the do-file expects.
These names become the option names for {cmd:statapar submit}.
For example, {cmd:macros(model year)} means the do-file uses {cmd:`model'} and {cmd:`year'},
and each call to {cmd:statapar submit} will supply {cmd:model(...)} and {cmd:year(...)}. Required.

{pmore}
{bf:Note:} each job runs in a separate Stata process with no access to the calling session's memory.
Global macros, scalars, matrices, and loaded data from the main session will {bf:not} be available.
Any values the do-file needs must be passed explicitly via {opt macros()} or defined in the do-file passed to {opt dofile()}.

{phang}
{opt maxjobs(#)} sets the maximum number of Stata processes that may run simultaneously. Once this limit is reached, {cmd:statapar} waits for a job to finish before starting the next one. Default is {cmd:5}.

{pstd}
{bf:{err:Warning:}} {cmd:maxjobs()} only restricts the number of parallel Stata processes, {bf:not} the number of CPUs.
If you are using Stata-MP, each process can use multiple CPU cores.
For example, {cmd:maxjobs(5)} with Stata-MP-16 can result in up to 80 CPU cores being used simultaneously.

{pstd}
{ul:statapar submit options}

{phang}
{it:macro1}{cmd:(}{it:value}{cmd:)}, {it:macro2}{cmd:(}{it:value}{cmd:)}, ... supply the values for the macros declared in {cmd:statapar init}.
One option is required for each macro name declared in {opt macros()}. The option names match those macro names exactly.

{marker examples}{...}
{title:Examples}

{pstd}
Suppose you have a do-file {cmd:estimate.do} that runs a regression for a given country and year:

{p 8 16 2}{it:(estimate.do)}{p_end}
{phang2}{cmd:use data_`country'_`year'.dta, clear}{p_end}
{phang2}{cmd:reg y x}{p_end}
{phang2}{cmd:estimates save results_`country'_`year', replace}{p_end}

{pstd}
You want to run this for three countries and two years — six jobs in total. With {cmd:statapar}:

{phang2}{cmd:statapar init, dofile(estimate.do) macros(country year) maxjobs(6)}{p_end}
{phang2}{cmd:statapar submit, country(usa) year(2020)}{p_end}
{phang2}{cmd:statapar submit, country(usa) year(2021)}{p_end}
{phang2}{cmd:statapar submit, country(gbr) year(2020)}{p_end}
{phang2}{cmd:statapar submit, country(gbr) year(2021)}{p_end}
{phang2}{cmd:statapar submit, country(deu) year(2020)}{p_end}
{phang2}{cmd:statapar submit, country(deu) year(2021)}{p_end}
{phang2}{cmd:statapar run}{p_end}

{pstd}
All six jobs will run simultaneously (or as many as {opt maxjobs()} allows) and {cmd:statapar run} returns once the last job finishes.

{pstd}

{marker usecases}{...}
{title:Use cases}

{pstd}
{cmd:statapar} is well suited for tasks where the same do-file is run repeatedly with different inputs and each run is independent of the others. Common examples:

{phang2}{c 149} Estimating the same model across many subgroups, countries, or time periods.{p_end}
{phang2}{c 149} Running Monte Carlo simulations with different seeds or parameter values.{p_end}
{phang2}{c 149} Producing many output files (tables, figures, datasets) where each can be generated independently.{p_end}
{phang2}{c 149} Bootstrapping or permutation testing where each replication is a separate do-file run.{p_end}

{pstd}
{cmd:statapar} is {ul:not} suited for tasks where runs depend on each other or need to share memory, since each job runs in a completely separate Stata process.

{marker hood}{...}
{title:How it works}

{pstd}
{cmd:statapar init} writes a shell script (PowerShell on Windows, bash on Unix/Mac) and defines an internal {cmd:statapar_submit} program in memory.

{pstd}
Each call to {cmd:statapar submit} creates a small wrapper do-file in Stata's temp directory.
That wrapper defines the supplied local macros and then calls {cmd:include} on the target do-file.
The path to this wrapper is appended to the shell script.

{pstd}
{cmd:statapar run} finalizes the shell script with job-throttling logic, executes it, and waits for all spawned processes to exit.
It then deletes all temporary files and resets the session.
The Stata executable path is detected automatically from {cmd:c(sysdir_stata)} and {cmd:c(edition_real)}.

{pstd}
Globals used internally: {cmd:statapar_active}, {cmd:statapar_shellfile}, {cmd:statapar_tmpfiles}.

{marker author}{...}
{title:Author}

{pstd}{browse "https://adamreir.com/":Adam Reiremo}{break}
Norwegian School of Economics{break}
Email: {browse "mailto:adamreir@gmail.com":adamreir@gmail.com}
{p_end}

{* https://www.techtips.surveydesign.com.au/post/how-to-write-a-stata-help-file}
{* help smcl}
