# Statapar
Statapar is a simple Stata package for running multiple Stata do-files in parallel.

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

Statapar also gives you the option to call do-files with local macros already defined. This option let you run a single do-file with different options, speeding up compute heavy processes. See [Example 2](example_2_single_dofile/) for a concrete example. 

Statapar makes Stata faster by utilizing more of the computer's CPU power. Make sure you don't annoy your colleagues by running to many do-files in parallell (see option `max_cpu()` below). 

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
statapar init

statapar submit, dofile("/some_path/clean_individual.do")
statapar submit, dofile("/some_path/clean_firms.do")
statapar submit, dofile("/some_path/clean_education.do")

statapar run
```

`statapar run` opens three different background Stata processes, and returns once all processes have finished.

---

### Running the same do-file with different inputs

A common use case is running the same estimation routine for many subgroups. Suppose `estimate.do` uses two local macros — `` `country' `` and `` `year' `` — to load data and save results:

```stata
* estimate.do
use data_`country'_`year'.dta, clear
reg y x
estimates save results_`country'_`year', replace
```

You can run this for every country-year combination in parallel using `locals()` and `values()`:

```stata
statapar init

statapar submit, dofile("/some_path/estimate.do") locals(country year) values("usa" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("usa" "2021")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("gbr" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("gbr" "2021")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("deu" "2020")
statapar submit, dofile("/some_path/estimate.do") locals(country year) values("deu" "2021")

statapar run
```

All six jobs run simultaneously — possibly not all at the same time, depending on how many parallel processes `max_cpu()` allows. Once they finish, you can load and combine the results files as usual.

> **Note:** each job runs in a completely separate Stata process. Global macros, loaded data, and scalars from the calling session are not available inside the do-file. Everything it needs must be passed via `locals()`/`values()` or loaded from disk inside the do-file.

---

## Options

| Option | Command | Description |
|---|---|---|
| `max_cpu(#)` | `init` | Maximum logical CPUs to use across all parallel jobs. Defaults to `floor(c(processors_mach)/2)` (half the machine's CPUs). The number of simultaneous processes is then set automatically based on `c(processors)` per process. |
| `force` | `init` | Allow `max_cpu(#)` to exceed the default limit. |
| `dofile(path)` | `submit` | The do-file to run as a job. Required. |
| `locals(namelist)` | `submit` | Names of local macros to define before running the do-file. |
| `values("v1" "v2" ...)` | `submit` | Values for each local in `locals()`. Each value must be quoted. |

> **Note:** the number of simultaneous processes is derived automatically as the largest integer such that `max_jobs * c(processors) < max_cpu`. If you use Stata-MP, `c(processors)` reflects the number of cores each Stata process is licensed to use, so the limit is respected in terms of total core usage.

---

## Provided Code Examples
This GitHub repository provides two code examples of how to use Statapar: 
1. [Example 1: Running multiple do-files in parallel.](example_1_multiple_dofiles/)
2. [Example 2: Running a single do-file with different macros.](example_2_single_dofile/)

---

See `help statapar` after installing for full documentation.
