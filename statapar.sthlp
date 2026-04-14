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
{cmd:statapar init} [{cmd:,} {opt maxjobs(#)}]

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
{opt maxjobs(#)} sets the maximum number of Stata processes allowed to run at the same time.
Once this limit is reached, {cmd:statapar} waits for a job to finish before starting the next one.
Default is {cmd:5}.

{pstd}
{bf:{err:Warning:}} {opt maxjobs()} restricts the number of parallel Stata {it:processes}, not CPU cores.
If you are using Stata-MP, each process can use multiple cores.
For example, {cmd:maxjobs(5)} with Stata-MP-16 may use up to 80 cores simultaneously.

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
Global macros, scalars, matrices, and loaded data from the calling session are {bf:not} available.
Everything the do-file needs must either be passed via {opt locals()} and {opt values()}, or loaded from disk inside the do-file.

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

{phang2}{cmd:statapar init, maxjobs(6)}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("usa" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("usa" "2021")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2021")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("deu" "2020")}{p_end}
{phang2}{cmd:statapar submit, dofile(estimate.do) locals(country year) values("deu" "2021")}{p_end}
{phang2}{cmd:statapar run}{p_end}

{pstd}
All six jobs will run simultaneously (subject to {opt maxjobs()}) and {cmd:statapar run} returns once the last job finishes.
Afterwards, the six results files can be loaded and combined in the usual way.

{marker usecases}{...}
{title:Use cases}

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
