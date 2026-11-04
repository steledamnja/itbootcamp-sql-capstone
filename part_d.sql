CREATE SCHEMA IF NOT EXISTS bootcamp.capstone_disciplina;

USE bootcamp.capstone_disciplina;

-- Део Г - моделирање: звезда за дисциплину
-- Управа лиге жели да анализира картоне: по судији, клубу, играчу и датуму. Направите звездасту шему.
-- 1. У part_d.sql направите и напуните табеле
-- Табела Шта садржи
-- dim_team Сви клубови из teams

CREATE OR REPLACE TABLE dim_team AS
SELECT * FROM bootcamp.northern_star.teams;

-- dim_date Календар - као на часу

CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);

SELECT * FROM dim_date;

-- dim_player Сви играчи из players, плус непознати члан са player_id = -1

CREATE OR REPLACE TABLE dim_player AS
SELECT
    player_id, first_name, last_name, known_as,
    birth_date, nationality, position, preferred_foot, height_cm
FROM bootcamp.northern_star.players

UNION ALL

SELECT
    -1, 'Nepoznat', 'igrac', NULL,
    NULL, 'Nepoznato', 'UNKNOWN', NULL, NULL;

-- dim_referee Сви судије из referees

CREATE OR REPLACE TABLE dim_referee AS
SELECT * FROM bootcamp.northern_star.referees;

-- fact_card Један ред по картону (yellow_card, second_yellow, red_card) из match_events У fact_card ставите: event_id, match_id, date_key, team_id, player_id, referee_id и врсту картона. Догађаји са играчем кога нема у players добијају player_id = -1.

CREATE OR REPLACE TABLE fact_card AS
SELECT
    e.event_id,
    e.match_id,
    CAST(DATE_FORMAT(m.kickoff_ts, 'yyyyMMdd') AS INT) AS date_key,
    e.team_id,
    COALESCE(p.player_id, -1) AS player_id,
    m.referee_id,
    e.event_type AS card_type
FROM bootcamp.northern_star.match_events e JOIN bootcamp.northern_star.matches m ON e.match_id = m.match_id
LEFT JOIN bootcamp.northern_star.players p ON e.player_id = p.player_id
WHERE e.event_type IN ('yellow_card', 'second_yellow', 'red_card');


-- 2. Упитом покажите да fact_card има исто редова колико има картонских догађаја

SELECT
    (SELECT COUNT(*)
    FROM bootcamp.northern_star.match_events
    WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card')) AS original_cards,
    (SELECT COUNT(*) FROM fact_card) AS fact_card_rows;

-- 3. Колико картона има player_id = -1?

SELECT COUNT(*) AS unknown_player_cards
FROM fact_card
WHERE player_id = -1;

-- 4. У README.md, у пар реченица опишите модел: шта је један ред у fact_card, који су кључеви (везе) и зашто мислите да картони имају своју табелу чињеница.