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

Statapar solves this by launching each job as a separate Stata process in the background, so all jobs run at the same time. You just describe the jobs, call `statapar run`, and wait for everything to finish.

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

statapar submit, dofile(clean.do)
statapar submit, dofile(analysis.do)
statapar submit, dofile(figures.do)

statapar run
```

`statapar run` returns once all three do-files have finished.

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
statapar init, maxjobs(6)

statapar submit, dofile(estimate.do) locals(country year) values("usa" "2020")
statapar submit, dofile(estimate.do) locals(country year) values("usa" "2021")
statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2020")
statapar submit, dofile(estimate.do) locals(country year) values("gbr" "2021")
statapar submit, dofile(estimate.do) locals(country year) values("deu" "2020")
statapar submit, dofile(estimate.do) locals(country year) values("deu" "2021")

statapar run
```

All six jobs run simultaneously (subject to `maxjobs()`). Once they finish, you can load and combine the results files as usual.

> **Note:** each job runs in a completely separate Stata process. Global macros, loaded data, and scalars from the calling session are not available inside the do-file. Everything it needs must be passed via `locals()`/`values()` or loaded from disk inside the do-file.

---

## Options

| Option | Command | Description |
|---|---|---|
| `maxjobs(#)` | `init` | Maximum simultaneous processes. Default: 5 |
| `dofile(path)` | `submit` | The do-file to run as a job. Required. |
| `locals(namelist)` | `submit` | Names of local macros to define before running the do-file. |
| `values("v1" "v2" ...)` | `submit` | Values for each local in `locals()`. Each value must be quoted. |

> **Warning:** `maxjobs()` limits the number of parallel Stata *processes*, not CPU cores. If you use Stata-MP, each process can use multiple cores — keep this in mind when setting `maxjobs()`.

---

See `help statapar` after installing for full documentation.
