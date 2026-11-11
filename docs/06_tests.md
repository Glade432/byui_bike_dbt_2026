[← Back: Dims + fact](05_marts.md) · **Page 6 of 7** · [Next: Stretch mart →](07_stretch_mart.md)

# 6 · Tests

Two kinds of tests:

| | **Schema (generic) tests** | **Singular tests** |
|---|---|---|
| Live in | `.yml` files next to your models | `.sql` files in **`tests/`** |
| Written as | one word: `unique`, `not_null`, ... | a `select` that finds **bad rows** |
| Good for | keys and relationships (every project needs these) | business rules ("no bike goes faster than 30 mph") |
| Passes when | — | the query returns **0 rows** |

---

## 1 · Schema tests for staging

Create **`models/staging/_stg_bike.yml`**. `stg_riders` is done for you. Add the other two:

```yaml
models:
  - name: stg_riders
    description: "One row per rider. Deduped on rider_id. The SSN never makes it this far."
    columns:
      - name: rider_id
        description: "Primary key."
        data_tests:
          - unique
          - not_null

  - name: stg_stations
    description: "One row per bike station."
    columns:
      - name: ____          # primary key: unique + not_null
        data_tests:
          - ____
          - ____
      - name: city
        data_tests:
          - accepted_values:
              arguments:
                values: ["Rexburg", "Idaho Falls", "Rigby"]

  - name: stg_rentals
    # your turn: primary key gets unique + not_null
```

> ⚠️ **Fusion syntax:** tests that take settings (`accepted_values`, `relationships`) put them
> under **`arguments:`**. Older tutorials skip that line, and Fusion warns about it.

## 2 · Schema tests for marts

Create **`models/marts/_marts.yml`**. The **`relationships`** test is the important new one: it
checks that every `rider_id` in the fact table **exists** in `dim_riders`.

```yaml
models:
  - name: dim_riders
    columns:
      - name: rider_id
        data_tests: [unique, not_null]

  - name: dim_stations
    columns:
      - name: station_id
        data_tests: [unique, not_null]

  - name: dim_date
    columns:
      - name: date_day
        data_tests: [unique, not_null]

  - name: fct_rentals
    columns:
      - name: rental_id
        data_tests: [unique, not_null]
      - name: rider_id
        data_tests:
          - relationships:
              arguments:
                to: ref('dim_riders')
                field: rider_id
      - name: station_id
        # your turn: relationships to dim_stations
```

## 3 · Two singular tests

Create **`tests/assert_same_name_riders_survive.sql`**:

```sql
-- There are TWO different riders named Jordan Smith (different rider_ids).
-- If your dedup used the name instead of the id, one of them vanished.
-- Returns a row (= fails) unless exactly 2 made it through staging.
select count(*) as jordan_smith_count
from {{ ref('stg_riders') }}
where full_name = 'Jordan Smith'
having count(*) != 2
```

Create **`tests/assert_no_impossible_speeds.sql`**:

```sql
-- A bike can't go faster than 30 mph.
-- This test PASSES when this query returns zero rows.
select
    rental_id,
    rider_id,
    miles,
    ride_minutes,
    mph
from {{ ref('stg_rentals') }}
where mph > 30
```

---

## 4 · Build everything

`dbtf build` = **seed + run + test**, in the right order, all at once:

```bash
dbtf build
```

**It fails.** That's on purpose. 💥

```
Failed test  assert_no_impossible_speeds
Skipped model fct_rentals
Skipped model dim_riders
...
Test failed (3 failed row(s)): assert_no_impossible_speeds
```

Two things to notice:

1. **Downstream models got SKIPPED.** `dbtf build` won't build `fct_rentals` on top of a
   staging model that failed its tests. **Bad data stops at staging.** That's the whole
   point of testing there.
2. **3 failed rows.** Who are they?

```bash
dbtf show --inline "select rental_id, rider_id, miles, ride_minutes, mph from {{ ref('stg_rentals') }} where mph > 30"
```

| rental_id | rider_id | miles | ride_minutes | mph |
|---|---|---|---|---|
| RNT-00086 | R-1009 | 150.02 | 1 | **9001.2** |
| RNT-00087 | R-1017 | 48.0 | 1 | 2880.0 |
| RNT-00088 | R-1009 | 310.4 | 2 | 9312.0 |

Two riders, three rides, all impossible: 48 to 310 miles in one or two minutes.

## 5 · Fix it in staging

These rides are **impossible** (a broken kiosk, probably). Go back to
**`models/staging/stg_rentals.sql`** and filter them out in the **last** line. Then:

```bash
dbtf build
```

✅ **Check:** **0 errors**, everything green. 🎉

> 🧠 **Why fix it in staging and not in the fact?** Staging is the one place every model reads
> from. Fix it once there and `dim_riders`, `fct_rentals`, and anything built later are all
> clean.
>
> 🧠 **Notice:** riders `R-1009` and `R-1017` are still in `dim_riders`. We removed bad
> **rentals**, not **riders**. Check: `dbtf show --select dim_riders --limit 5`

<details>
<summary>▶ Solution: the fix in <code>stg_rentals.sql</code></summary>

Change the last line from:

```sql
select * from final
```

to:

```sql
select * from final
where mph <= 30   -- drop impossible rides
```

**In real life**, you might *flag* these instead of deleting them
(`mph > 30 as is_suspicious`) so someone can investigate the kiosk. Filtering is fine for
today.

</details>

<details>
<summary>▶ Solution: full <code>models/staging/_stg_bike.yml</code></summary>

```yaml
models:
  - name: stg_riders
    description: "One row per rider. Deduped on rider_id. The SSN never makes it this far."
    columns:
      - name: rider_id
        description: "Primary key."
        data_tests:
          - unique
          - not_null

  - name: stg_stations
    description: "One row per bike station."
    columns:
      - name: station_id
        description: "Primary key."
        data_tests:
          - unique
          - not_null
      - name: city
        data_tests:
          - accepted_values:
              arguments:
                values: ["Rexburg", "Idaho Falls", "Rigby"]

  - name: stg_rentals
    description: "One row per bike rental."
    columns:
      - name: rental_id
        description: "Primary key."
        data_tests:
          - unique
          - not_null
```

</details>

<details>
<summary>▶ Solution: full <code>models/marts/_marts.yml</code></summary>

```yaml
models:
  - name: dim_riders
    description: "One row per rider, with their ride totals."
    columns:
      - name: rider_id
        data_tests: [unique, not_null]

  - name: dim_stations
    description: "One row per station."
    columns:
      - name: station_id
        data_tests: [unique, not_null]

  - name: dim_date
    description: "One row per day of 2026."
    columns:
      - name: date_day
        data_tests: [unique, not_null]

  - name: fct_rentals
    description: "One row per rental. The middle of the star."
    columns:
      - name: rental_id
        data_tests: [unique, not_null]
      - name: rider_id
        data_tests:
          - relationships:
              arguments:
                to: ref('dim_riders')
                field: rider_id
      - name: station_id
        data_tests:
          - relationships:
              arguments:
                to: ref('dim_stations')
                field: station_id
```

</details>

**Commit + push.** You've now done the whole workshop loop: **source → stage → model → test
→ fix → ship.**

---

[← Back: Dims + fact](05_marts.md) · **Page 6 of 7** · [Next: Stretch mart →](07_stretch_mart.md)
