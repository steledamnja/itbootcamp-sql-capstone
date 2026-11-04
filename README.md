# ITBootCamp | SQL Capstone

**Stefan Damjanović** · Data Engineering · Databricks SQL

A practical SQL project analyzing football league data across two seasons. It combines relational queries, a league-wide analytical report, window functions, and an introductory star schema for disciplinary events.

## Environment

- **Platform:** Databricks SQL
- **Source schema:** `bootcamp.northern_star` (nine related league tables)
- **Analytical schema:** `bootcamp.capstone_disciplina` (created in Part D)
- **Data model:** [Entity–relationship diagram](docs/schema.md)

## Project Structure

| File | Work completed |
|---|---|
| [part_a.sql](part_a.sql) | **10 SQL questions:** Matches, stadium capacity, players, penalties, referees, and managers; multi-table joins, CTEs, and aggregations. |
| [part_b.sql](part_b.sql) | **Season 2024/25 report queries:** Results and goals, monthly trends, attendance, referees and cards, top scorers/assists, and data quality checks. |
| [report.pdf](report.pdf) | **League-wide report:** A concise summary of the six Part B analyses and their findings. |
| [part_c.sql](part_c.sql) | **5 window-function analyses:** Team goal shares, stadium rankings, last goal per club, changes in attendance, and cumulative points. |
| [part_d.sql](part_d.sql) | **Disciplinary star schema:** Four dimensions, a card-event fact table, and validation queries. |
| [docs/schema.md](docs/schema.md) | **Database documentation:** Mermaid ER diagram showing the source tables and their relationships. |

## SQL Techniques Demonstrated

- **Relational analysis:** `INNER JOIN`, `LEFT JOIN`, `COUNT(DISTINCT)`, grouping, and conditional aggregation with `CASE WHEN`.
- **Reusable query logic:** CTEs (`WITH`), `UNION ALL`, and a `team_matches` view.
- **Window functions:** `ROW_NUMBER()`, `DENSE_RANK()`, `LAG()`, `SUM() OVER`, `QUALIFY`, and `ROWS BETWEEN`.
- **Data modeling:** `CREATE OR REPLACE TABLE`, dimension/fact tables, date keys, and `SEQUENCE`/`EXPLODE` for a calendar dimension.
- **Data quality:** Checks for missing attendance and match events referencing unknown players.

## Disciplinary Star Schema — `fact_card`

Each row in `fact_card` represents **one card event** (`yellow_card`, `second_yellow`, or `red_card`).

The `event_id` identifies the event, while `match_id` identifies its match. The `date_key`, `team_id`, `player_id`, and `referee_id` link it to `dim_date`, `dim_team`, `dim_player`, and `dim_referee`, respectively.

Missing or unmatched players are assigned `player_id = -1`, representing an **Unknown Player** dimension member.

Keeping cards in a separate fact table enables analysis by **date, club, player, and referee**, without duplicating match-level records.

Validation queries compare fact-table row counts with source card events and identify unknown-player cases.

## Selected Findings

For the **2024/25 league season**, the analysis identified:

- **380 matches** played.
- **1,092 goals** scored (2.87 per match).
- **9 matches** with missing attendance data.
- **2 events** referencing players absent from the player table.

## Notes

The SQL scripts require access to the ITBootCamp training tables in Databricks. Source data is not included in this repository.

The original assignment questions are documented alongside the SQL queries.