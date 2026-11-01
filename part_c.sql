USE bootcamp.northern_star;

SELECT * FROM matches_flat;

-- Део В - прозорске функције
-- Свако питање мора да користи бар једну прозорску функцију.

-- 1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи удео?

WITH goals AS (
    SELECT
        home_team_id AS team_id,
        home_goals AS goals_for
    FROM matches
    WHERE season = '2024/25' AND status = 'played'

    UNION ALL

    SELECT 
        away_team_id,
        away_goals
    FROM matches
    WHERE season = '2024/25' AND status = 'played'
            )
SELECT
    t.team_name,
    SUM(g.goals_for) AS total_goals,
    ROUND(100 * SUM(g.goals_for) / SUM(SUM(g.goals_for)) OVER (), 2) AS goals_pct

FROM goals g JOIN teams t ON g.team_id = t.team_id
GROUP BY t.team_name
ORDER BY goals_pct DESC;

-- Kingsbridge City ima najveci udeo, 7.60%.

-- 2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?

SELECT
    s.stadium_name,
    ROUND(AVG(m.attendance), 2) AS avg_attendance,
    DENSE_RANK() OVER (ORDER BY AVG(m.attendance) DESC) AS rn
FROM matches m
JOIN stadiums s ON m.stadium_id = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played'
GROUP BY s.stadium_id, s.stadium_name
QUALIFY rn <= 3
ORDER BY rn;

-- Tri stadiona sa najvecom prosecnom posetom u sezoni 2024/25 su Harbourside Park, Kingsbridge Stadium i Northport Arena.

-- 3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи гол дао најраније?

WITH last_goals AS (
    SELECT
        e.team_id,
        e.player_id,
        e.event_type,
        m.kickoff_ts,
        e.minute,
        e.added_time,
        ROW_NUMBER() OVER (PARTITION BY e.team_id ORDER BY m.kickoff_ts DESC, e.minute DESC,
            COALESCE(e.added_time, 0) DESC, e.event_id DESC) AS rn
        FROM match_events e
        JOIN matches m ON e.match_id = m.match_id
        WHERE m.season = '2024/25' AND m.status = 'played' AND e.event_type IN ('goal', 'penalty_goal', 'own_goal')
            )
SELECT
    t.team_name,
    p.first_name,
    p.last_name,
    l.kickoff_ts,
    l.minute,
    l.event_type
FROM last_goals l JOIN teams t ON l.team_id = t.team_id
LEFT JOIN players p ON l.player_id = p.player_id
WHERE l.rn = 1
ORDER BY l.kickoff_ts, l.minute;

-- Elmsworth Wanderers je klub koji je svoj poslednji goal postigao najranije.

-- 4. За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену у односу на претходну домаћу утакмицу. Где је највећи пад?

SELECT
    m.match_id,
    m.kickoff_ts,
    m.attendance,
    LAG(m.attendance) OVER (ORDER BY m.kickoff_ts, m.match_id) AS previous_attendance,
    m.attendance - LAG(m.attendance) OVER (ORDER BY m.kickoff_ts, m.match_id) AS attendance_difference
FROM matches m JOIN teams t ON m.home_team_id = t.team_id
WHERE m.season = '2024/25' AND m.status = 'played' AND t.team_name = 'Northport United'
ORDER BY attendance_difference ASC NULLS LAST;

-- Najveci pad 10267 datuma 2024-11-10.

-- 5. Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој утакмици по реду и ког датума је прешао 50 бодова?

CREATE OR REPLACE VIEW team_matches AS
    WITH sides AS (
        SELECT 
            match_id, season, matchday, kickoff_ts,
            home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
            venue,
            home_goals AS goals_for, away_goals AS goals_against
        FROM matches WHERE status = 'played'
        UNION ALL
        SELECT 
            match_id, season, matchday, kickoff_ts,
            away_team_id, home_team_id, 'away',
            away_goals, home_goals
        FROM matches WHERE status = 'played'
)
SELECT 
    *,
    CASE WHEN goals_for > goals_against THEN 'W'
         WHEN goals_for = goals_against THEN 'D' 
         ELSE 'L' 
    END AS result,
    CASE WHEN goals_for > goals_against THEN 3
         WHEN goals_for = goals_against THEN 1 
         ELSE 0 
    END AS points
FROM sides;

SELECT
    match_id,
    kickoff_ts,
    points,
    ROW_NUMBER() OVER (ORDER BY kickoff_ts, match_id) AS match_no,
    SUM(points) OVER (ORDER BY kickoff_ts, match_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_points
FROM team_matches
WHERE season = '2024/25' AND team_id = 2
ORDER BY match_no;

-- U 21oj utakmici 2025-01-12 je presao 50 bodova, 51.