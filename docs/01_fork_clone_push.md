[← Back: Install WSL](00_wsl.md) · **Page 1 of 7** · [Next: Profile + seed →](02_profile_and_seed.md)

# 1 · Fork, clone, push

This is exactly what you'll do at the workshop with their starter repo, so let's practice it
on this one.

| Word | Means |
|---|---|
| **Fork** | Your own copy of someone's repo, **on GitHub** |
| **Clone** | Download a repo **to your computer** |
| **Branch** | A separate line of work, so `main` stays clean |
| **Push** | Send your commits **up to GitHub** |

---

## 1 · Fork

1. Go to <https://github.com/MLMecham/byui_bike_dbt_2026>
2. Click **Fork** (top right) → **Create fork**.

✅ **Check:** the page title is now **`<your-username>/byui_bike_dbt_2026`**, with
*"forked from MLMecham/byui_bike_dbt_2026"* underneath.

## 2 · Clone (into Linux, not Windows!)

On **your fork's** page: green **Code** button → **HTTPS** → copy the URL. Then in the
**Ubuntu** terminal:

```bash
cd ~
git clone https://github.com/<your-username>/byui_bike_dbt_2026.git
cd byui_bike_dbt_2026
code .
```

> ⚠️ **Clone into `~` (your Linux home), NOT `/mnt/c/...` and NOT OneDrive.** Windows folders
> are slow from Linux, and the dbt extension's file watching breaks there.

When VS Code asks **"Do you trust the authors?"** → **Yes, I trust the authors**.

✅ **Check:** bottom-left says **`WSL: Ubuntu`**, and the Explorer shows `seeds/`, `models/`,
`docs/`.

## 3 · Make your own branch

Use the buttons:

1. **Bottom-left**, click the branch name **`main`**.
2. Pick **+ Create new branch...**
3. Name it `<yourname>-practice` (example: `mitch-practice`) → **Enter**.

✅ **Check:** bottom-left now shows your branch name instead of `main`.

## 4 · Change something, commit, push

1. Make a new file in the repo root called **`plan.md`** (right-click in Explorer →
   **New File**). Put this in it:

   ```markdown
   # My plan
   Name: <your name>
   One question I'd ask a bike-rental company's data:
   ```

   Fill it in and **save** (`Ctrl+S`).
2. Open **Source Control** (`Ctrl+Shift+G`, the branch icon on the left).
3. Type a message like `add my plan` → click **Commit**. If it asks *"stage all changes?"* →
   **Yes**.
4. Click **Publish Branch**.

✅ **Check:** on GitHub, open your fork → the **branch dropdown** (it says `main`) → your
branch is there, with `plan.md` in it.

<details>
<summary>▶ Prefer the terminal? Same thing in commands</summary>

```bash
git checkout -b mitch-practice
# ...make plan.md...
git add plan.md
git commit -m "add my plan"
git push -u origin mitch-practice
```

</details>

> 💡 Stay on this branch for the rest of today. At the end, commit and push again (in VS Code
> the button will say **Sync Changes**).

---

[← Back: Install WSL](00_wsl.md) · **Page 1 of 7** · [Next: Profile + seed →](02_profile_and_seed.md)
