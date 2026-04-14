# Example 2: Running different do-files in parallel

This example shows how to use `statapar` to run **multiple different do-files in parallel**. Unlike Example 1, each job runs a completely different script — not the same script with different inputs.

## What this example does

It estimates three different regression models of January temperatures on July temperatures, using Stata's built-in `citytemp` dataset. The three models are:

| Do-file | Model |
|---|---|
| `model_ols.do` | Simple OLS (full sample) |
| `model_quadratic.do` | OLS with a quadratic term for July temperature |
| `model_region_fe.do` | OLS with census region fixed effects |

Because the three models are completely independent of each other, they can all run at the same time.

## Files

| File | Description |
|---|---|
| `example_main.do` | The main script — sets up statapar, submits the three jobs, and combines results |
| `model_ols.do` | Estimates a simple OLS model |
| `model_quadratic.do` | Estimates a quadratic model |
| `model_region_fe.do` | Estimates an OLS model with region fixed effects |
| `output/` | Folder where each job saves its estimates |

## How to run it

Open `example_main.do` in Stata, update the two path variables at the top to match your computer, and run the file.

```stata
loc code_directory   = "path/to/example_2_multiple_dofiles"
loc output_directory = "path/to/example_2_multiple_dofiles/output"
```

Statapar will launch three Stata processes simultaneously — one per model — and wait for all of them to finish before loading and displaying the results side by side.

## How it works

Each do-file is a completely self-contained analysis: it loads the data, runs the model, and saves the estimates. The only shared input is the output directory, which is passed in via a local macro:

```stata
statapar submit, dofile(model_ols.do)       locals(output_directory) values("path/to/output")
statapar submit, dofile(model_quadratic.do) locals(output_directory) values("path/to/output")
statapar submit, dofile(model_region_fe.do) locals(output_directory) values("path/to/output")
```

Notice that unlike Example 1, each `submit` call points to a **different** do-file. Statapar simply runs whatever do-file you point it to — it does not have to be the same one every time.
