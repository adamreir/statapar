# Example 2: Running the same do-file with different inputs

This example shows how to use `statapar` to run the **same do-file multiple times in parallel**, each time with a different set of local macro values.

## What this example does

It estimates a simple regression of January temperatures on July temperatures separately for each of the four US census regions, using Stata's built-in `citytemp` dataset. The four regressions are completely independent of each other and can therefore run at the same time.

## Files

| File | Description |
|---|---|
| `example_main.do` | The main script — sets up statapar, submits the four jobs, and combines results |
| `example_client.do` | The do-file that each parallel job runs (one regression per region) |
| `output/` | Folder where each job saves its estimates |

## How to run it

1. Download `example_2.zip` and extract it to a folder.
2. Open `example_main.do` in Stata, set `code_directory` at the top to the folder you extracted to, and run the file.

```stata
loc code_directory = "path/to/example_2_single_dofile"
```

`output_directory` is set automatically as a global pointing to the `output` subfolder — you don't need to set it manually.

3. Run `example_main.do`. Statapar will launch four Stata processes simultaneously — one per region — and wait for all of them to finish before loading and displaying the results.

## How it works

`example_main.do` opens separate Stata processes, each one running `example_client.do`. `output_directory` is defined as a global in `example_main.do` and is automatically forwarded to each job. Each call to `statapar submit` passes only the job-specific value of `` `region' ``:

```stata
loc code_directory      = "path/to/example_2_single_dofile"
global output_directory = "`code_directory'/output"

statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("1")
statapar submit, dofile("`code_directory'/example_client.do") locals(region) values("2")
...
```

`example_client.do` uses the global for the output path and the local for filtering:

```stata
sysuse citytemp, clear
reg tempjan tempjuly if region == `region'
estimates save "${output_directory}/region_`region'_jan-july", replace
```

Statapar creates a small temporary wrapper do-file for each job that defines the locals and then runs `example_client.do`. All four wrapper do-files are executed in parallel.
