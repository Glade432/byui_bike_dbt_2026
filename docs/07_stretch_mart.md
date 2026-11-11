[← Back: Tests](06_tests.md) · **Page 7 of 7** · [Home →](../README.md)

# 7 · Stretch: build a mart

Dims and facts are **building blocks**. A **mart** answers **one specific business
question**, so someone can open it and read the answer.

This is the part of the workshop where you pick your own question. Practice here:

> ### ❓ Which stations make the most money, and is it on weekdays or weekends?

## Build `mart_station_weekends`

Create **`models/marts/mart_station_weekends.sql`**. One row per **station × weekday/weekend**:

| Column | From |
|---|---|
| `station_name`, `city` | `dim_stations` |
| `is_weekend` | `fct_rentals` |
| `rides` | `count(*)` |
| `revenue` | `sum(price_dollars)` |
| `avg_ride_minutes` | `round(avg(ride_minutes), 1)` |

**Hints:** join `fct_rentals` to `dim_stations` on `station_id`. Then `group by` the three
non-number columns.

```bash
dbtf build --select mart_station_weekends
dbtf show --inline "select * from {{ ref('mart_station_weekends') }} order by revenue desc" --limit 12
```

<details>
<summary>▶ Solution: <code>mart_station_weekends.sql</code></summary>

```sql
with rentals as (

    select * from {{ ref('fct_rentals') }}

),

stations as (

    select * from {{ ref('dim_stations') }}

)

select
    stations.station_name,
    stations.city,
    rentals.is_weekend,
    count(*)                             as rides,
    sum(rentals.price_dollars)           as revenue,
    round(avg(rentals.ride_minutes), 1)  as avg_ride_minutes
from rentals
inner join stations
    on rentals.station_id = stations.station_id
group by 1, 2, 3
```

</details>

## Write it up (this is the workshop deliverable!)

At the workshop you'll present **an insight backed by numbers** and **a next step**. Practice
in your `plan.md`:

```markdown
## Insight
<station> made the most money: $___ on weekdays vs $___ on weekends.

## Next step
<what would you tell the bike company to do?>
```

### 🐉 Bonus question

Vegeta vs. Goku: **who rides more, and who spends more?** (Careful: there are two Gokus.)

```bash
dbtf show --inline "select rider_id, full_name, total_rides, lifetime_spend from {{ ref('dim_riders') }} where full_name in ('Son Goku', 'Prince Vegeta')"
```

<details>
<summary>▶ Answer</summary>

Vegeta takes the **most rides**, but the busier Goku (`R-1017`) **spends the most**. Longer
rides cost more. Rivals to the end. 🤝

</details>

**Commit + push.** You're ready for the workshop. 🚲

---

[← Back: Tests](06_tests.md) · **Page 7 of 7** · [Home →](../README.md)
