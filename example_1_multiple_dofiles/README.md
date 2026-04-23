# Example 1: Running different do-files in parallel

This example shows how to use `statapar` to run **multiple different do-files in parallel**. Unlike Example 2, each job runs a completely different script — not the same script with different inputs.

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

1. Download `example_1.zip` and extract it to a folder.
2. Open `example_main.do` in Stata, set `code_directory` at the top to the folder you extracted to, and run the file.

```stata
loc code_directory = "path/to/example_1_multiple_dofiles"
```

`output_directory` is set automatically as a global pointing to the `output` subfolder — you don't need to set it manually.

3. Run `example_main.do`. Statapar will launch three Stata processes simultaneously — one per model — and wait for all of them to finish before loading and displaying the results side by side.

## How it works

`example_main.do` opens separate Stata processes, each one running a different do-file. Global macros from the calling session are automatically available inside each job. `output_directory` is defined as a global in `example_main.do` and is automatically forwarded to each job, so the model do-files can use `${output_directory}` directly to save their estimates:

```stata
loc code_directory      = "path/to/example_1_multiple_dofiles"
global output_directory = "`code_directory'/output"

statapar init
statapar submit, dofile("`code_directory'/model_ols.do")
statapar submit, dofile("`code_directory'/model_quadratic.do")
statapar submit, dofile("`code_directory'/model_region_fe.do")
statapar run
```

Notice that unlike Example 2, each `submit` call points to a **different** do-file. Statapar simply runs whatever do-file you point it to — it does not have to be the same one every time.
