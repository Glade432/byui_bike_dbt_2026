[← Home](../README.md)

# Troubleshooting

## WSL

| Problem | Fix |
|---|---|
| `wsl --install` prints a help screen | WSL is half-installed: `wsl --install -d Ubuntu` |
| `0x80370102` / "enable Virtual Machine Platform" | Virtualization is off in the BIOS. **Raise your hand.** |
| "The requested operation requires elevation" | PowerShell wasn't opened **as administrator** |
| Typing my password shows nothing | Normal! Type it and press Enter. |
| `ls /mnt/c/jane`: No such file or directory | You need `/Users/` in the middle: `/mnt/c/Users/jane` |
| `N: Some packages may have been kept back due to phasing` | Harmless. Keep going. |
| Forgot my Linux password | In **Windows PowerShell**: `wsl -u root passwd <your-linux-username>` |
| `code: command not found` in Ubuntu | Close **all** VS Code windows and the Ubuntu terminal, reopen Ubuntu, try again. Still broken? Reinstall VS Code with **"Add to PATH"** checked. |
| Warning about **UNC paths** when running a Windows program | Harmless. Ignore it. |

## dbt / Fusion

| Problem | Fix |
|---|---|
| `dbtf: command not found` but `dbt --version` says 2.x | `source ~/.bashrc` or open a new terminal ([details](00_wsl.md#f--dbt-fusion)) |
| `dbt --version` says **1.x** | That's old dbt-core from a Python venv. Run `deactivate` and use `dbtf`. |
| `Could not find profile named 'university_workshop'` | Typo in the block name, or it's indented inside another block. It starts at the far left. |
| keyfile / `No such file or directory` | Your keyfile is a `C:\` path. In WSL it must be `/mnt/c/...`. Run `readlink -f ~/.dbt/bigquery-key.json`. |
| `Not found: Dataset ..._raw` | You haven't seeded yet: `dbtf seed` |
| Dataset "was not found in location" | `location:` in your profile must match your other datasets (usually `US`). |
| `dbt_utils` / `date_spine` is undefined | `dbtf deps` |
| `Syntax error: Expected end of input but got keyword LIMIT` | You put `limit` inside `dbtf show --inline "..."`. Use `--limit 20` after the quotes. |
| `[warning] UnusedResourceConfigPath ... staging` | Harmless. Goes away once `models/staging/` has a model. |
| Column `ssn` not found | 🎉 Good. It shouldn't exist past staging. |
| Only one Jordan Smith left | You deduped on `full_name`. Dedup on the **id**. |

## Git / GitHub

| Problem | Fix |
|---|---|
| Push asks for a username/password | `gh auth login` again, and answer **Yes** to "Authenticate Git with your GitHub credentials". |
| `Author identity unknown` | `git config --global user.name "..."` and `user.email "..."` ([page 0, part E](00_wsl.md#e--git--github)) |
| Pushed to the wrong repo | `git remote -v` must show **your** fork, not `MLMecham/...` |

## No WSL? The Windows fallback

If WSL won't install (no admin rights, BIOS locked), you can run Fusion on Windows directly.

1. In **PowerShell** (no admin needed):

   ```powershell
   irm https://public.cdn.getdbt.com/fs/install/install.ps1 | iex
   ```

2. Clone the repo somewhere **outside OneDrive** (example: `C:\Users\<you>\code`).
3. In your `university_workshop` profile block, use the **Windows** keyfile path:
   `keyfile: C:\Users\<you>\.dbt\bigquery-key.json`
4. ⚠️ On Windows, the `dbtf` alias only exists in **PowerShell**. In **Git Bash**, type
   `dbt` instead, or run `echo "alias dbtf=dbt" >> ~/.bashrc` once and open a new terminal.
