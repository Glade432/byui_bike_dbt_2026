[← Back: Fork, clone, push](01_fork_clone_push.md) · **Page 2 of 7** · [Next: Sources →](03_sources.md)

# 2 · Profile + seed

## 1 · Add a profile block

This repo's `dbt_project.yml` says `profile: university_workshop`. That's the **same name the
workshop starter repo uses**, so the block you make now works on workshop day too.

Open your profiles file. Thanks to the symlink, this **is** your Windows file:

```bash
code ~/.dbt/profiles.yml
```

**Keep everything that's already there.** Paste this at the **bottom**:

```yaml
university_workshop:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account

      project: dbt-fall-2026-smith          # <-- same as your gcp_setup block
      dataset: dbt_smith_john               # <-- same as your gcp_setup block
      keyfile: /mnt/c/Users/Jane/.dbt/bigquery-key.json   # <-- your Windows username

      location: US
      threads: 4
```

Copy `project:` and `dataset:` from your existing `gcp_setup:` block. **Don't copy its
`keyfile:` line.**

> ### Why a new block instead of reusing `gcp_setup`?
> Your `gcp_setup` keyfile is a **Windows** path (`C:\Users\...`). Linux can't read `C:\`
> paths. Same key file, two ways to spell where it is:
>
> | Block | Used from | keyfile |
> |---|---|---|
> | `gcp_setup` | Windows (class project) | `C:\Users\Jane\.dbt\bigquery-key.json` |
> | `university_workshop` | WSL (today + workshop) | `/mnt/c/Users/Jane/.dbt/bigquery-key.json` |
>
> **Not sure of the exact path?** This prints it for you:
> ```bash
> readlink -f ~/.dbt/bigquery-key.json
> ```

Save the file.

## 2 · `dbtf debug`

In the VS Code terminal (`` Ctrl+` ``), from the repo folder:

```bash
dbtf debug
```

✅ **Check:** **All checks passed!**

<details>
<summary>⚠️ It failed?</summary>

| Error says | Fix |
|---|---|
| profile **not found** / `university_workshop` | Block name typo, or you pasted it *inside* another block. It must start at the far left, with no spaces. |
| **keyfile** / No such file | Wrong path. Run `readlink -f ~/.dbt/bigquery-key.json` and paste exactly that. |
| **location** / dataset not found in location | `location:` must match `gcp_setup` (usually `US`). |
| `dbtf: command not found` | See the [dbtf gotcha](00_wsl.md#f--dbt-fusion). |

</details>

## 3 · `dbtf deps`

```bash
dbtf deps
```

This installs **dbt_utils**, a package of handy macros (listed in `packages.yml`). We use it
to build `dim_date`. dbt packages are dbt code, not Python, so there's still no `uv`.

## 4 · `dbtf seed`

```bash
dbtf seed
```

✅ **Check:** `3 total | 3 success`.

> 💡 You'll also see `[warning] UnusedResourceConfigPath ... models.byui_bike_dbt.staging`.
> That's fine. `dbt_project.yml` has settings for a `staging/` folder that's still empty.
> The warning goes away once you build staging models.

## 5 · Go look at the raw data

In the **BigQuery console** (<https://console.cloud.google.com/bigquery>), your project now
has a dataset called **`<your dataset>_raw`** (example: `dbt_smith_john_raw`) with 3 tables.
Click **raw_riders** → **Preview**.

Or stay in VS Code. Seeds can be `ref`'d, so `dbtf show` can peek at them:

```bash
dbtf show --select raw_riders
```

**Three things to notice:**

1. 😬 **`ssn`** is right there. Social Security numbers (fake ones, starting `000`). Staging
   is where we make sure they **never go any further**.
2. **Duplicate rows.** Run this:

   ```bash
   dbtf show --inline "select id, count(*) as copies from {{ ref('raw_riders') }} group by id having count(*) > 1"
   ```

   Three riders were loaded twice: `R-1009`, `R-1023`, and `R-1030`.
3. **Two Jordan Smiths:**

   ```bash
   dbtf show --inline "select * from {{ ref('raw_riders') }} where full_name = 'Jordan Smith'"
   ```

   Same name, but a **different `id`** and a different signup date. **Are these duplicates?**
   🤔 Remember your answer for page 4.

> ⚠️ **`dbtf show --inline` tip:** don't put `limit` in your SQL (it errors). Use the
> `--limit` flag instead: `dbtf show --inline "select ..." --limit 20`

---

[← Back: Fork, clone, push](01_fork_clone_push.md) · **Page 2 of 7** · [Next: Sources →](03_sources.md)
