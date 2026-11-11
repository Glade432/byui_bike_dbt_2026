[← Back: Sources](03_sources.md) · **Page 4 of 7** · [Next: Dims + fact →](05_marts.md)

# 4 · Staging

**One staging model per source table.** Each one does the same four moves:

| Move | Example | Why |
|---|---|---|
| **Rename** | `RIDER` → `rider_id` | Clear, consistent names everywhere downstream |
| **Cast** (only what needs it) | `'2026-06-01 09:15:00'` (text) → timestamp | So date math works |
| **Dedup** | keep 1 row per `id` | So counts and joins aren't doubled |
| **New column** | `ride_minutes` | Simple, row-level logic everyone will want |

…plus **drop what nobody should use**: junk columns and the **SSN**.

> 🎯 **Finishing this page is today's goal.**

---

## Dedup with `QUALIFY`: the same as Snowflake

You did this in Snowflake. **BigQuery uses the exact same syntax:**

<table>
<tr><th>Snowflake (class project)</th><th>BigQuery (today)</th></tr>
<tr><td>

```sql
select *
from source
qualify row_number() over (
    partition by id
    order by signed_up_on
) = 1
```

</td><td>

```sql
select *
from source
qualify row_number() over (
    partition by id
    order by signed_up_on
) = 1
```

</td></tr>
</table>

Yes, they're identical. 🙂 What it does, using Vegeta (loaded twice):

| id | full_name | `row_number() over (partition by id ...)` | kept? |
|---|---|---|---|
| R-1009 | Prince Vegeta | **1** | ✅ |
| R-1009 | Prince Vegeta | **2** | ❌ |
| R-1017 | Son Goku | **1** | ✅ |
| R-1042 | Son Goku | **1** | ✅ |

`partition by id` restarts the count for every `id`. `= 1` keeps the first row of each group.

> 🐉 **Both Gokus get `1`** because they have **different ids**. They're two different
> people who happen to share a name. **Always dedup on the primary key, never on a name.**
> (A test on page 6 checks that both Gokus survive.)

<details>
<summary>▶ What QUALIFY is short for (the long way)</summary>

`QUALIFY` is a filter on a window function, so you don't need a subquery:

```sql
select * except (rn)
from (
    select *, row_number() over (partition by id order by signed_up_on) as rn
    from source
)
where rn = 1
```

</details>

## BigQuery casting cheat sheet

| From (text) | To | BigQuery |
|---|---|---|
| `'2026-06-01 09:15:00'` | timestamp | `cast(STARTED_AT as timestamp)` |
| `'2026-03-14'` | date | `cast(signed_up_on as date)` |
| `'2025-04-15T00:00:00'` | date | `date(cast(opened_at as timestamp))` |
| `1350` (cents) | dollars | `PRICE_CENTS / 100` |
| timestamp | date | `date(started_at)` |
| two timestamps | minutes between | `timestamp_diff(ended_at, started_at, minute)` |
| `a / b` where `b` might be 0 | no crash | `safe_divide(a, b)` |
| `'Son Goku'` | `'Son'` | `split(full_name, ' ')[offset(0)]` |

> 🧠 **Column names in BigQuery aren't case-sensitive.** `ID`, `id`, and `Id` all work. We
> still rename the SHOUTING ones so everything downstream looks the same.

---

## Model 1 · `stg_riders` (guided)

Create **`models/staging/stg_riders.sql`** and fill in the `____` blanks:

```sql
with source as (

    select * from {{ source('bike_raw', '____') }}

),

deduped as (

    select *
    from source
    qualify row_number() over (partition by ____ order by signed_up_on) = 1

),

renamed as (

    select
        id                                  as ____,          -- rename
        full_name,
        split(full_name, ' ')[offset(0)]    as first_name,    -- new column
        cast(signed_up_on as ____)          as signed_up_on   -- cast
        -- ssn: ????
    from deduped

)

select * from renamed
```

Build and check it:

```bash
dbtf run --select stg_riders
dbtf show --select stg_riders
```

✅ **Check:** there's **no `ssn` column**, and both Gokus are there:

```bash
dbtf show --inline "select * from {{ ref('stg_riders') }} where full_name = 'Son Goku'"
```

<details>
<summary>▶ Solution: <code>stg_riders.sql</code></summary>

```sql
with source as (

    select * from {{ source('bike_raw', 'raw_riders') }}

),

deduped as (

    -- dedup on the PRIMARY KEY (id), never on the name: there are two Son Gokus!
    select *
    from source
    qualify row_number() over (partition by id order by signed_up_on) = 1

),

renamed as (

    select
        id                                  as rider_id,      -- rename
        full_name,
        split(full_name, ' ')[offset(0)]    as first_name,    -- new column
        cast(signed_up_on as date)          as signed_up_on   -- cast
        -- ssn is NOT selected. It stops here.
    from deduped

)

select * from renamed
```

**"Prince Vegeta" → first_name = "Prince"?** Yep. Real data is messy. 👑

</details>

---

## Model 2 · `stg_stations` (your turn)

Create **`models/staging/stg_stations.sql`**. Same shape as `stg_riders`. Here's the spec:

| Raw column | Do this | Output column |
|---|---|---|
| `id` | rename | `station_id` |
| `station_name` | keep | `station_name` |
| `city` | keep | `city` |
| `opened_at` | cast text → **date** | `opened_on` |
| `docks` | keep (already a number: **no cast needed**) | `docks` |
| *(new)* | `docks >= 20` | `is_large_station` |
| `map_color_hex` | **drop** | — |

Dedup on `id` (remember `ST-03` showed up twice).

```bash
dbtf run --select stg_stations
dbtf show --select stg_stations
```

✅ **Check:** **6** rows, not 7.

<details>
<summary>▶ Solution: <code>stg_stations.sql</code></summary>

```sql
with source as (

    select * from {{ source('bike_raw', 'raw_stations') }}

),

deduped as (

    select *
    from source
    qualify row_number() over (partition by id order by opened_at) = 1

),

renamed as (

    select
        id                                  as station_id,        -- rename
        station_name,
        city,
        date(cast(opened_at as timestamp))  as opened_on,         -- cast: text -> timestamp -> date
        docks,                                                    -- already a number: no cast
        docks >= 20                         as is_large_station   -- new column
        -- map_color_hex: nobody needs it, so it's gone
    from deduped

)

select * from renamed
```

</details>

---

## Model 3 · `stg_rentals` (your turn, the big one)

Create **`models/staging/stg_rentals.sql`**. This table has SHOUTING column names:

| Raw column | Do this | Output column |
|---|---|---|
| `ID` | rename | `rental_id` |
| `RIDER` | rename | `rider_id` |
| `STATION_ID` | rename | `station_id` |
| `STARTED_AT` | cast text → **timestamp** | `started_at` |
| `ENDED_AT` | cast text → **timestamp** | `ended_at` |
| `MILES` | keep (already a number) | `miles` |
| `PRICE_CENTS` | ÷ 100 | `price_dollars` |
| `KIOSK_VERSION` | **drop** | — |
| *(new)* | date of `started_at` | `rental_date` |
| *(new)* | minutes between start and end | `ride_minutes` |
| *(new)* | miles ÷ hours | `mph` |

Dedup on `ID`.

**Hint:** the new columns need the *cast* timestamps, so add a **4th CTE** after `renamed`:

```sql
final as (

    select
        *,
        date(started_at)                              as rental_date,
        timestamp_diff(____, ____, minute)            as ride_minutes,
        round(safe_divide(miles, timestamp_diff(ended_at, started_at, minute) / 60), 1) as mph
    from renamed

)

select * from final
```

```bash
dbtf run --select stg_rentals
dbtf show --select stg_rentals
```

✅ **Check:** **215** rows (the raw table had 221).

```bash
dbtf show --inline "select count(*) as n from {{ ref('stg_rentals') }}"
```

<details>
<summary>▶ Solution: <code>stg_rentals.sql</code></summary>

```sql
with source as (

    select * from {{ source('bike_raw', 'raw_rentals') }}

),

deduped as (

    select *
    from source
    qualify row_number() over (partition by ID order by STARTED_AT) = 1

),

renamed as (

    select
        ID                                  as rental_id,     -- rename
        RIDER                               as rider_id,      -- rename
        STATION_ID                          as station_id,
        cast(STARTED_AT as timestamp)       as started_at,    -- cast
        cast(ENDED_AT as timestamp)         as ended_at,      -- cast
        MILES                               as miles,
        PRICE_CENTS / 100                   as price_dollars  -- cents -> dollars
        -- KIOSK_VERSION: dropped
    from deduped

),

final as (

    select
        *,
        date(started_at)                              as rental_date,   -- new column
        timestamp_diff(ended_at, started_at, minute)  as ride_minutes,  -- new column
        round(safe_divide(miles, timestamp_diff(ended_at, started_at, minute) / 60), 1) as mph
    from renamed

)

select * from final
```

</details>

---

## 🎉 Staging done

Run all three together:

```bash
dbtf run --select staging
```

✅ **Check:** `3 total | 3 success`. **Commit + push** (Source Control → message → Commit →
**Sync Changes**).

That's today's goal. If you have time, keep going. 👇

---

[← Back: Sources](03_sources.md) · **Page 4 of 7** · [Next: Dims + fact →](05_marts.md)
