USE bootcamp.northern_star;

SELECT * FROM matches_flat;

-- 1. Колико утакмица је одиграно у фебруару 2025?

SELECT COUNT(*) AS game_number
FROM matches
WHERE status = 'played'
        AND kickoff_ts >= '2025-02-01'
        AND kickoff_ts < '2025-03-01';


-- A1 - Broj odigranih utakmica u februaru je 40.

-- 2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?

SELECT stadium_name, capacity
FROM stadiums
ORDER BY capacity DESC
LIMIT 1;

SELECT s.stadium_name, s.capacity
FROM stadiums s JOIN teams t ON s.stadium_id = t.stadium_id
ORDER BY s.capacity DESC
LIMIT 1;

-- A2 - National Stadium, 80000.
-- A2 - Najveci stadijum povezan sa klubom je Harbourside Park, 52000.

-- 3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?

SELECT COUNT(*) AS serbian_players
FROM players
WHERE nationality = 'Serbia';

-- A3 - Srpsko drzavljanstvo ima 42 igraca.

-- 4. Колико утакмица је завршено резултатом 1:1?

SELECT COUNT(*) AS matches_1_1
FROM matches
WHERE status = 'played'
        AND home_goals = 1
        AND away_goals = 1;

-- A4 - 94 utakmice je zavrseno rezultatom 1:1.

-- 5. Колика је просечна посета по сезони?

SELECT season,
    ROUND(AVG(attendance), 2) AS avg_attendance
FROM matches
WHERE status = 'played'
GROUP BY season
ORDER BY season;

-- A5 - 2023/24 avg_attendance 24276.2 and 2024/25 avg_attendance 24199.49

-- 6. Колико голова је дато из пенала по сезони?

SELECT m.season,
    COUNT(*) AS penalty_goals
FROM match_events e JOIN matches m ON e.match_id = m.match_id
WHERE m.status = 'played' AND e.event_type = 'penalty_goal'
GROUP BY m.season
ORDER BY m.season;

-- A6 - 2023/24 penalty_goals 104 and 2024/25 penalty_goals 109.

-- 7. Колико различитих играча је дало бар један гол у сезони 2024/25?

SELECT COUNT(DISTINCT e.player_id) AS distinct_scorers
FROM match_events e JOIN matches m ON e.match_id = m.match_id
WHERE m.season = '2024/25'
        AND m.status = 'played'
        AND e.event_type IN ('goal', 'penalty_goal');

-- A7 - 308 razlicitih igraca je dalo bar jedan gol u sezoni 2024/25.

-- 8. Који судија је највише пута судио утакмице клуба Northport United?

SELECT r.referee_name,
    COUNT(*) AS games_refereed
FROM matches m 
JOIN referees r ON m.referee_id = r.referee_id
JOIN teams t ON t.team_id IN (m.home_team_id, m.away_team_id)
WHERE m.status = 'played' AND t.team_name = 'Northport United'
GROUP BY r.referee_name
ORDER BY games_refereed DESC
LIMIT 1;

-- A8 - Peter Lindgren je najvise puta sudio utakmice kluba Northport United, 9.

-- 9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један пенал, дат или промашен?

WITH penalty_matches AS (
    SELECT DISTINCT match_id
    FROM match_events
    WHERE event_type IN ('penalty_goal', 'penalty_miss')
        )
SELECT r.referee_name,
    COUNT(*) AS total_matches,
    COUNT(pm.match_id) AS matches_with_penalty,
    ROUND(100 * COUNT(pm.match_id) / COUNT(*), 2) AS penalty_pct
FROM matches m JOIN referees r ON m.referee_id = r.referee_id
LEFT JOIN penalty_matches pm ON m.match_id = pm.match_id
WHERE m.season = '2024/25' AND m.status = 'played'
GROUP BY r.referee_name
ORDER BY penalty_pct DESC
LIMIT 1;

-- A9 - Peter Lindgren 45%

-- 10. Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на полувремену? Рачунајте и домаће и гостујуће утакмице.

WITH behind_as_half AS (
    SELECT match_id,
        kickoff_ts,
        home_team_id AS team_id,
        CASE
            WHEN home_goals > away_goals THEN 3
            WHEN home_goals = away_goals THEN 1
            ELSE 0
        END AS points
    FROM matches
    WHERE status = 'played'
        AND home_goals_ht < away_goals_ht

    UNION ALL

    SELECT match_id,
        kickoff_ts,
        away_team_id,
        CASE
            WHEN away_goals > home_goals THEN 3
            WHEN away_goals > home_goals THEN 3
            ELSE 0
        END 
    FROM matches
    WHERE status = 'played'
        AND away_goals_ht < home_goals_ht
        ),
assigned AS (
    SELECT
        *,
        ms.manager_name,
        ROW_NUMBER () OVER ( b.match_id, b.team_id ORDER BY ms.start_date DESC, ms.spell_id DESC
        )AS rn

    FROM behind_as_half b JOIN manager_spells ms ON b.team_id = ms.team_id
        AND DATE(b.kickoff_ts) >= ms.start_date
        AND (ms.end_date IS NULL OR DATE(b.kickoff_ts) <= ms.start_date)
    )

SELECT manager_name,
    SUM(points) AS earned_points
FROM assigned
WHERE rn = 1
GROUP BY manager_name
ORDER BY earned_points DESC
LIMIT 1;

-- A10
