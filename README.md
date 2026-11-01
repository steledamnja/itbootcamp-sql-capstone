# itbootcamp-sql-capstone

SQL capstone project for the ITBootcamp Data Engineering program.

**Stefan Damnjanovic**

The project focuses on SQL data analysis, relational databases, joins, aggregations, and window functions using Databricks SQL.

## Project Structure

- **Part A (`part_a.sql`):** SQL queries for exploring and analyzing league data.
- **Part B (`part_b.sql`):** Season 2024/25 analysis, including goals, attendance, referees, players, and data quality.
- **Report (`report.pdf`):** Summary of the season analysis and key findings.
- **Part C (`part_c.sql`):** Window functions for ranking, running totals, and comparing results.
- **Part D (`part_d.sql`):** Star schema for analyzing disciplinary events.

## Data Assumptions

Match statistics include only completed matches. Missing values are treated separately from zero values. Regular goals and penalty goals are included in goalscoring statistics.

## Part D — Discipline Star Schema

A star schema was created with `fact_card` as the central fact table and four dimension tables: `dim_team`, `dim_date`, `dim_player`, and `dim_referee`.

Each row in `fact_card` represents one card event (yellow card, second yellow card, or red card).

The `event_id` identifies each event, while `date_key`, `team_id`, `player_id`, and `referee_id` link to the dimension tables. The `match_id` identifies the match.

Cards have a separate fact table because multiple cards can occur in one match. This allows easier analysis by team, player, referee, and date.

Unknown players are assigned `player_id = -1` to prevent data loss.
