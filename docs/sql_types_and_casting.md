[← Back to Staging](04_staging.md) · [Home](../README.md)

# SQL data types + casting (a 5-minute primer)

New to SQL? Read this before (or during) [page 4](04_staging.md). Every example here was run
in BigQuery. Paste any of them into the terminal to try it yourself.

---

## What's a data type?

Every column has a **type** that says what kind of value lives in it. The type decides what you
can **do** with the value:

| Value | As text (`STRING`) | As the right type |
|---|---|---|
| `'10'` vs `'9'` | `'10' < '9'` is **true** 🤯 (compares letter by letter: `1` comes before `9`) | `10 < 9` is **false** ✅ |
| `'2026-06-01'` | can't add days, can't subtract dates | `date_add(...)`, `date_diff(...)` work |
| `'1350'` | can't sum it | `sum(...)` works |

Try the first one:

```bash
dbtf show --inline "select '10' < '9' as text_compare, 10 < 9 as number_compare"
```

```
│ text_compare ┆ number_compare │
│ true         ┆ false          │
```

**That's why raw data needs casting.** Raw tables often store everything as text, because it's
the safest way to load *anything*. Staging turns it back into real types.

---

## Common types

The ones you'll actually use, with their Snowflake names for comparison:

| BigQuery | Snowflake | Holds | Example | In our bike data |
|---|---|---|---|---|
| `STRING` | `VARCHAR` | text | `'Jordan Smith'` | `full_name`, `city`, ids |
| `INT64` | `NUMBER` / `INT` | whole numbers | `42` | `docks`, `PRICE_CENTS` |
| `FLOAT64` | `FLOAT` | decimals (approximate) | `3.7` | `MILES`, `mph` |
| `NUMERIC` | `NUMBER(38,9)` | decimals (exact): **money** | `13.50` | *(could use for `price_dollars`)* |
| `BOOL` | `BOOLEAN` | `true` / `false` | `true` | `is_large_station`, `is_weekend` |
| `DATE` | `DATE` | a calendar day | `2026-06-01` | `rental_date`, `signed_up_on` |
| `TIMESTAMP` | `TIMESTAMP_TZ` | an exact moment (UTC) | `2026-06-01 09:15:00 UTC` | `started_at`, `ended_at` |
| `DATETIME` | `TIMESTAMP_NTZ` | date + time, **no** time zone | `2026-06-01 09:15:00` | *(not used today)* |

> 🧠 **Text values go in 'single quotes'.** Numbers and `true`/`false` don't.
> `'42'` is a string; `42` is a number.

---

## How to cast

```sql
cast(<value or column> as <TYPE>)
```

| You write | You get |
|---|---|
| `cast('42' as int64)` | `42` |
| `cast('3.7' as float64)` | `3.7` |
| `cast(3.7 as int64)` | `4` (**rounds**, doesn't chop) |
| `cast(42 as string)` | `'42'` |
| `cast('2026-03-14' as date)` | `2026-03-14` |
| `cast('2026-06-01 09:15:00' as timestamp)` | `2026-06-01 09:15:00 UTC` |
| `date(cast('2025-04-15T00:00:00' as timestamp))` | `2025-04-15` (two steps: text → timestamp → date) |
| `cast(1 as bool)` | `true` |

Try a few at once:

```bash
dbtf show --inline "select cast('42' as int64) as a, cast('3.7' as float64) as b, cast(3.7 as int64) as c"
```

---

## When a cast fails

`cast` **errors** if the text doesn't look like the type:

| You write | BigQuery says |
|---|---|
| `cast('3.7' as int64)` | `Bad int64 value: 3.7` |
| `cast('06/01/2026' as date)` | `Invalid date: '06/01/2026'` (dates must look like `YYYY-MM-DD`) |

Two ways out:

**1. `safe_cast`** gives you `NULL` instead of an error:

```bash
dbtf show --inline "select safe_cast('banana' as int64) as a, safe_cast('2026-13-45' as date) as b"
```

Both come back empty (`NULL`). Useful, but **careful**: it hides bad data quietly. A
`not_null` test afterward will catch it.

**2. `parse_date`** for non-standard date formats. You tell it the pattern:

```sql
parse_date('%m/%d/%Y', '06/01/2026')   -- 2026-06-01
```

(`%m` month, `%d` day, `%Y` 4-digit year. There's also `parse_timestamp` for timestamps.)

---

## Not a cast, but close: math gotchas

| You write | You get | Why |
|---|---|---|
| `1350 / 100` | `13.5` | In BigQuery, `/` **always** returns a decimal (`FLOAT64`) |
| `div(7, 2)` | `3` | Whole-number division, remainder dropped |
| `5 / 0` | ❌ error | Use `safe_divide(5, 0)` → `NULL` |
| `round(13.456, 2)` | `13.46` | |

---

## 🏋️ Quick practice

Predict the answer, then run it.

1. `select cast('7' as int64) + cast('3' as int64)`
2. `select '7' || '3'`  *(`||` glues text together)*
3. `select date_diff(cast('2026-08-31' as date), cast('2026-06-01' as date), day)`
4. `select safe_cast('N/A' as float64)`

```bash
dbtf show --inline "select cast('7' as int64) + cast('3' as int64) as q1, '7' || '3' as q2"
```

<details>
<summary>▶ Answers</summary>

1. `10`: two numbers, added.
2. `'73'`: two strings, glued. Same characters, totally different result. **Types matter.**
3. `91`: days between June 1 and Aug 31 (the bike season!).
4. `NULL`: `'N/A'` isn't a number, and `safe_cast` doesn't error.

</details>

---

[← Back to Staging](04_staging.md) · [Home](../README.md)
