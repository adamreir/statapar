# Statapar
Statapar is a simple and transparent Stata package for running multiple Stata do-files in parallel.

## Installation
```stata
cap ssc uninstall statapar
net install statapar, from("https://raw.githubusercontent.com/adamreir/statapar/main")
```

Tested on Stata MP 16.1 (Linux) and StataNow/SE 18.5 (Windows).

---

## What does it do?

Stata normally runs one task at a time. If you need to run the same do-file for 20 countries, or run three independent scripts, you have to wait for each one to finish before the next one starts.

One way to speed up this process is to open multiple Stata windows, and run different do-files in each window. Statapar does this for you by launching each job as a separate Stata process in the background. 

Statapar additionally gives you the option to call do-files with local macros already defined. This option let you run a single do-file with different options, speeding up compute heavy processes. See [Example 2](example_2_single_dofile/) for a concrete example. 

Statapar is useful when your machine has more CPU cores than a single Stata process can use. Stata SE is limited to one core regardless of hardware, and even Stata MP is capped at a fixed number of cores per process (1-64 cores depending on version and license). If you are running Stata SE on any modern multi-core workstation, or Stata MP on a server with many cores to spare, those idle cores would otherwise go unused — Statapar lets you put them to work by running several Stata processes at the same time.

Statapar makes Stata faster by utilizing more of the computer's CPU power. Make sure you don't annoy your colleagues by running too many do-files in parallell (see option `max_cpu()` below). 

---

## How to use it

Every statapar session has three steps:

1. **`statapar init`** — start a new session (optionally set a limit on simultaneous jobs)
2. **`statapar submit`** — add a job to the queue (repeat once per job)
3. **`statapar run`** — launch all queued jobs in parallel and wait for them to finish

---

## Examples

### Running independent do-files in parallel

If you have several do-files that don't depend on each other, you can run them all at once:

```stata
// Initiate a new parallel session
statapar init 

// Submit three do-files that will be run in parallel
statapar submit, dofile("/some_path/clean_individual.do") 
statapar submit, dofile("/some_path/clean_firms.do")
statapar submit, dofile("/some_path/clean_education.do")

// Run the three jobs
statapar run
```

`statapar run` opens three different background Stata processes, and returns once all processes have finished.

---

### Running the same do-file with different macros

A common use case is running the same estimation routine for many subgroups. Suppose `estimate.do` uses two local macros — `` `country' `` and `` `year' `` — to load data and save results:

```stata
* estimate.do
use data_`country'_`year'.dta, clear
reg y x
estimates save "${output_directory}/results_`country'_`year'", replace
```

You can run this for every country-year combination in parallel using `locals()` and `values()`:

```stata
global output_directory = "some_path" // Globals are forwarded to new processes

statapar init

// Submit jobs: Same do-file with different values for `country' and `year': 
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("usa" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("usa" "2021")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("gbr" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("gbr" "2021")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("deu" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("deu" "2021")

// Run
statapar run
```

Stata runns these jobs in parallel, each one with different values for `` `country' `` and `` `year' ``. Once they finish, you can load and combine the results files as usual.

> **Note:** Each job runs in a completely separate Stata process. Global macros from the calling session are automatically propagated to every job, so do-files can rely on globals just as they would in the main session. The active dataset can be forwarded to every job with `keepdata` on `statapar init`. Scalars and matrices are not carried over — anything beyond globals and data must be passed via `locals()`/`values()` or loaded from disk. Specify `noglobal` on `statapar init` to suppress global propagation for the entire session.

---

## Options

| Option | Command | Description |
|---|---|---|
| `max_cpu(#)` | `init` | Maximum logical CPUs to use across all parallel jobs. Defaults to `floor(c(processors_mach)/2)` (half the machine's CPUs). The number of simultaneous processes is then set automatically based on `c(processors)` per process. |
| `force` | `init` | Allow `max_cpu(#)` to exceed the default limit. |
| `noglobal` | `init` | Suppress the automatic propagation of global macros to each job's environment. |
| `keepdata` | `init` | Pass the dataset currently in memory to every job. The data is saved to a temporary file immediately when `statapar init` is called and loaded at the start of each job, before any local macros are defined. The temporary file is deleted once all jobs finish. |
| `dofile(path)` | `submit` | The do-file to run as a job. Required. |
| `locals(namelist)` | `submit` | Names of local macros to define before running the do-file. |
| `values("v1" "v2" ...)` | `submit` | Values for each local in `locals()`. Each value must be quoted. |

> **Note:** The maximum number of simultaneous processes defaults to a number s.t. the number of CPUs used is less than `number_of_cores_available / 2`. On the server Lucia, the maximum number of parallel processes is set to 4. Use `max_cpu(#)` and `force` to exeed this. 

---

## Provided Code Examples
This GitHub repository provides two code examples of how to use Statapar: 
1. [Example 1: Running multiple do-files in parallel.](example_1_multiple_dofiles/)
2. [Example 2: Running a single do-file with different macros.](example_2_single_dofile/)

---

See `help statapar` after installing for full documentation.

--- 
## Issues
Create an `` Issue `` in GitHub or contact me on adamreir@gmail.com if you are experiencing problems with Statapar. 
