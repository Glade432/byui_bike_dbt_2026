[← Home](../README.md)

# Cheat sheet

## dbt Fusion

`dbtf` and `dbt` are the **same program** (Fusion). Use `dbtf` so you never accidentally run
old dbt-core.

| Command | Does |
|---|---|
| `dbtf --version` | Check Fusion is installed (should say **2.x**) |
| `dbtf debug` | Test your profile + BigQuery connection |
| `dbtf deps` | Install packages from `packages.yml` (dbt_utils) |
| `dbtf seed` | Load the CSVs in `seeds/` into BigQuery |
| `dbtf run` | Build all models |
| `dbtf run --select stg_riders` | Build one model |
| `dbtf run --select staging` | Build every model in a folder |
| `dbtf run --select +fct_rentals` | Build a model **and everything upstream of it** |
| `dbtf test` | Run the tests |
| `dbtf build` | Seed + run + test, in order. **The one you'll use most.** |
| `dbtf show --select stg_riders` | Preview a model's rows |
| `dbtf show --inline "select ..." --limit 20` | Run any SQL (no `limit` inside the quotes!) |
| `dbtf init` | Create a new project/profile (the workshop mentions it, but you already have a profile) |

## Jinja you'll type a lot

```sql
{{ source('bike_raw', 'raw_riders') }}   -- staging only: tables dbt didn't build
{{ ref('stg_riders') }}                  -- everything else: models dbt built
```

Casting and types: see the [SQL types + casting primer](sql_types_and_casting.md).

## Git

**The VS Code buttons are easiest:** Source Control (`Ctrl+Shift+G`) → message → **Commit** →
**Sync Changes**.

| Command | Does |
|---|---|
| `git status` | What's changed? |
| `git add .` | Stage all changes |
| `git commit -m "message"` | Save a snapshot |
| `git push` | Send commits to GitHub |
| `git pull` | Get the latest from GitHub |

## WSL / Linux

| Command | Does |
|---|---|
| `cd ~` | Go to your Linux home folder |
| `ls` | List files |
| `pwd` | Where am I? |
| `code .` | Open this folder in VS Code |
| `source ~/.bashrc` | Reload your settings (fixes `dbtf: command not found` after an install) |
| `/mnt/c/Users/<you>/` | Your Windows `C:\Users\<you>\` folder, seen from Linux |
