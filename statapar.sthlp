{smcl}
{* *! version 0.1.0 14April2026}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:statapar} {hline 2}}Run multiple Stata do-files in parallel{p_end}
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
{cmd:statapar} lets you run multiple Stata do-files in parallel.
Each job runs in its own separate Stata process, so all jobs can proceed at the same time
rather than waiting for the previous one to finish.

{pstd}
You can use {cmd:statapar} in two ways:

{phang2}{c 149} Run several {bf:different} do-files in parallel — for example, three independent cleaning scripts that do not depend on each other.{p_end}
{phang2}{c 149} Run the {bf:same} do-file multiple times with different local macro values — for example, the same estimation routine for many countries or subgroups.{p_end}

{pstd}
A {cmd:statapar} session always follows the same three steps:

{phang2}1. Call {cmd:statapar init} to start a new session.{p_end}
{phang2}2. Call {cmd:statapar submit} once for each job you want to run, providing the do-file and any local macros it needs.{p_end}
{phang2}3. Call {cmd:statapar run} to launch all queued jobs at once and wait until they all finish.{p_end}

{pstd}
{cmd:statapar} works on Windows and Unix/Mac.

{marker overview}{...}
{title:Overview}

{p2colset 9 25 27 2}{...}
{p2col :{cmd:statapar init}}Start a new parallel session{p_end}
{p2col :{cmd:statapar submit}}Add a job to the queue{p_end}
{p2col :{cmd:statapar run}}Launch all queued jobs in parallel{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Step 1 — start a session:

{p 8 16 2}
{cmd:statapar init} [{cmd:,} {opt max_cpu(#)} {opt force} {opt noglobal} {opt keepdata}]

{pstd}
Step 2 — add a job (repeat once per job):

{p 8 16 2}
{cmd:statapar submit,} {opt dofile(path)} [{opt locals(namelist)} {opt values("val1" "val2" ...)}]

{pstd}
Step 3 — run all queued jobs:

{p 8 16 2}
{cmd:statapar run}

{marker options}{...}
{title:Options}

{pstd}
{ul:statapar init}

{phang}
{opt max_cpu(#)} sets the maximum number of logical CPUs that {cmd:statapar} may use in total across all parallel jobs.
If not specified, the default is half the machine's available CPUs.
The number of simultaneous processes is then set automatically based on the number of cores per Stata process ({cmd:c(processors)}).

{phang}
{opt force} allows {opt max_cpu(#)} to exceed the default limit (and the server cap described below).
Without {opt force}, specifying a value above the applicable limit triggers an error.

{phang}
{opt noglobal} suppresses the automatic propagation of global macros to every job in the session.
By default, the globals defined in the calling session at the time of each {cmd:statapar submit} call are written into that job's environment.

{phang}
{opt keepdata} passes the dataset currently in memory to every job in the session.
The active dataset is saved to a temporary file immediately when {cmd:statapar init} is called;
each job then loads that file at startup, before any local macros are defined.
The temporary file is deleted automatically once all jobs have finished.

{pstd}
{bf:Note:} {opt max_cpu()} caps total CPU usage, not the number of processes directly — the number of simultaneous
processes is derived automatically so that total core usage stays within the limit.
On the server {bf:lucia.nhh.no}, the number of simultaneous processes is additionally capped at 4 regardless of the machine default.
Use {opt max_cpu(#)} together with {opt force} to exceed this cap.

{pstd}
{ul:statapar submit}

{phang}
{opt dofile(path)} specifies the do-file to run as a job. Required.

{phang}
{opt locals(namelist)} specifies the names of the local macros to define before running the do-file.
Must be combined with {opt values()}. The number of names must match the number of values.

{phang}
{opt values("val1" "val2" ...)} specifies the value for each local macro listed in {opt locals()}.
Each value {bf:must} be enclosed in double quotes, even for numbers.
The order corresponds to the order of names in {opt locals()}.

{pmore}
{bf:Note:} each job runs in a completely separate Stata process.
Global macros from the calling session are automatically propagated to every job,
so do-files can rely on globals just as they would in the main session.
The active dataset can be passed to every job using {opt keepdata} on {cmd:statapar init}.
Scalars and matrices are {bf:not} carried over — anything the do-file needs beyond globals and data
must be passed via {opt locals()} and {opt values()}, or loaded from disk inside the do-file.

{marker examples}{...}
{title:Examples}

{pstd}
{ul:Example 1: Running independent do-files in parallel}

{pstd}
Suppose you have three do-files that are completely independent of each other —
they do not share data or depend on each other's results.
Instead of running them one at a time, you can run all three at once:

{phang2}{cmd:statapar init}{p_end}
{phang2}{cmd:statapar submit, dofile(clean.do)}{p_end}
{phang2}{cmd:statapar submit, dofile(analysis.do)}{p_end}
{phang2}{cmd:statapar submit, dofile(figures.do)}{p_end}
{phang2}{cmd:statapar run}{p_end}

{pstd}
{cmd:statapar run} returns once all three do-files have finished.

{pstd}
{ul:Example 2: Running the same do-file with different local macros}

{pstd}
Suppose you have a do-file {cmd:estimate.do} that runs a regression for a given country and year,
using two local macros {cmd:`country'} and {cmd:`year'}:

{p 8 16 2}{it:(estimate.do)}{p_end}
{phang2}{cmd:use data_`country'_`year'.dta, clear}{p_end}
{phang2}{cmd:reg y x}{p_end}
{phang2}{cmd:estimates save results_`country'_`year', replace}{p_end}

{pstd}
You want to run this for three countries and two years — six jobs in total.
Each call to {cmd:statapar submit} provides the do-file and the macro values for that job:

{phang2}{cmd:statapar init}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("usa" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("usa" "2021")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2021")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("deu" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("deu" "2021")}{p_end}
{phang2}{cmd:statapar run}{p_end}

{pstd}
All six jobs will run simultaneously (subject to the process limit derived from {opt max_cpu()}) and {cmd:statapar run} returns once the last job finishes.
Afterwards, the six results files can be loaded and combined in the usual way.

{marker usecases}{...}
{title:Use cases}

{pstd}
{cmd:statapar} is most useful when your machine has more CPU cores than a single Stata process can use.
Stata SE is limited to one core regardless of the underlying hardware,
and Stata MP is capped at a fixed number of cores per licence (up to 64).
If you are running Stata SE on a modern multi-core workstation,
or Stata MP on a server where many cores would otherwise sit idle,
{cmd:statapar} lets you put that spare capacity to work by running several Stata processes in parallel.

{pstd}
{cmd:statapar} is well suited for tasks where jobs are independent of each other. Common examples:

{phang2}{c 149} Estimating the same model across many subgroups, countries, or time periods.{p_end}
{phang2}{c 149} Running multiple independent cleaning or processing scripts.{p_end}
{phang2}{c 149} Running Monte Carlo simulations with different seeds or parameter values.{p_end}
{phang2}{c 149} Bootstrapping or permutation testing where each replication is independent.{p_end}
{phang2}{c 149} Producing many output files (tables, figures, datasets) where each can be generated on its own.{p_end}

{pstd}
{cmd:statapar} is {ul:not} suited for tasks where jobs depend on each other or need to share memory,
since each job runs in a completely separate Stata process.

{marker hood}{...}
{title:How it works}

{pstd}
{cmd:statapar init} creates a shell script in Stata's temporary directory
(PowerShell on Windows, bash on Unix/Mac).

{pstd}
Each call to {cmd:statapar submit} does two things:
it creates a small temporary do-file (also in Stata's temp directory) that optionally defines the supplied local macros
and then calls {cmd:include} on the target do-file;
and it appends the path to that temporary do-file to the shell script.

{pstd}
{cmd:statapar run} finalizes the shell script with job-throttling logic, executes it, and waits for all spawned processes to finish.
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
