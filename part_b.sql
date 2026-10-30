USE bootcamp.northern_star;

SELECT * FROM matches_flat;

-- Део Б - извештај о сезони 2024/25 - Управа лиге тражи кратак извештај о сезони 2024/25. Предајете два фајла: извештај у формату по избору (Markdown, Txt или PDF) и part_b.sql са свим упитима које сте користили. За сваки одељак у извештају дајте малу табелу или неколико бројева, и реченицу или две шта ти бројеви значе.


-- 1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа домаћина, нерешених и победа гостију.

SELECT
    COUNT(*) AS total_matches,
    SUM(home_goals + away_goals) AS total_goals,
    ROUND(AVG(home_goals + away_goals), 2) AS avg_goals,
    SUM(CASE WHEN home_goals > away_goals THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN home_goals = away_goals THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN home_goals < away_goals THEN 1 ELSE 0 END) AS away_wins,
    ROUND(100 * SUM(CASE WHEN home_goals > away_goals THEN 1 ELSE 0 END) / COUNT(*), 2) AS home_win_pct,
    ROUND(100 * SUM(CASE WHEN home_goals = away_goals THEN 1 ELSE 0 END) / COUNT(*), 2) AS draw_pct,
    ROUND(100 * SUM(CASE WHEN home_goals < away_goals THEN 1 ELSE 0 END) / COUNT(*), 2) AS away_win_pct

FROM matches
WHERE season = '2024/25' AND status = 'played';

-- B1 - 380 utakmica; 1092 golova; prosek golova 2.87; pobeda domacina 157 41,32%; 95 neresenih utakmica; pobeda gostiju 128 33.68%

-- 2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у сваком месецу. Који месец се издваја?

SELECT
    DATE_FORMAT(kickoff_ts, 'yyyy-MM') AS month,
    COUNT(*) AS total_matches,
    SUM(home_goals + away_goals) AS total_goals,
    ROUND(AVG(home_goals + away_goals), 2) AS avg_goals
FROM matches
WHERE season = '2024/25' AND status = 'played'
GROUP BY DATE_FORMAT(kickoff_ts, 'yyyy-MM')
ORDER BY month;

-- B2 - Avgust 2024 ima najveci prosek golova po utakmici 3.54 dok decembar ima najveci broj golova i to 145.

-- 3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и утакмица без публике.

SELECT 
        s.stadium_name,
        s.capacity,
        COUNT(*) AS total_matches,
        COUNT(m.attendance) AS known_attendance,
        COUNT(*) - COUNT(m.attendance) AS missing_attendance,
        SUM(CASE 
                WHEN m.attendance = 0 THEN 1
                ELSE 0
            END) AS matches_without_crowd,
            ROUND(AVG(m.attendance), 2) AS avg_attendance,
            ROUND(100 * AVG(m.attendance) / s.capacity, 2) occupancy_pct
FROM matches m JOIN bootcamp.northern_star.stadiums s ON m.stadium_id = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played'
GROUP BY s.stadium_id, s.stadium_name, s.capacity
ORDER BY occupancy_pct DESC;

-- B3 - Najveca prosecna popunjenost na stadijumu Elmsworth Lane; 9 Utakmica bez podataka o poseti; nema utakmica sa evidentiranih 0 gledaoca.

-- 4. Судије: за сваког судију број утакмица и картони по утакмици.

WITH cards AS (
    SELECT 
        match_id,
        COUNT(*) AS card_count
    FROM match_events
    WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card')
    GROUP BY match_id
        )
SELECT
    r.referee_name,
    COUNT(*) AS total_matches,
    SUM(COALESCE(c.card_count, 0)) AS total_cards,
    ROUND(1 * SUM(COALESCE(c.card_count, 0)) / COUNT(*), 2) AS avg_cards

FROM matches m JOIN referees r ON m.referee_id = r. referee_id
LEFT JOIN cards c ON m.match_id = c.match_id
WHERE m.season = '2024/25' AND status = 'played'
GROUP BY r.referee_id, r.referee_name
ORDER BY avg_cards DESC, r.referee_name;

-- 4B - Peter Lindgren ima najveci prosek od 4.25 kartona po utakmici.

-- 5. Играчи: пет најбољих стрелаца и пет најбољих асистената.

SELECT 
    p.first_name,
    p.last_name,
    COUNT(*) AS total_goals
FROM match_events e JOIN matches m ON e.match_id = m.match_id
    JOIN players p ON e.player_id = p.player_id
WHERE m.season = '2024/25' AND m.status = 'played' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY total_goals DESC, p.player_id
LIMIT 5;

SELECT 
    p.first_name,
    p.last_name,
    COUNT(*) AS total_assists
FROM match_events e JOIN matches m ON e.match_id = m.match_id
    JOIN players p ON e.related_player_id = p.player_id
WHERE m.season = '2024/25' AND m.status = 'played' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY total_assists DESC, p.player_id
LIMIT 5;

-- B5 - Pet najboljih strelaca su Mattéo O’Brien 34, Leo Marsh 32, José Muñoz 24, Marko Stanković 17 and Leo Marsh 16. Sa najvise asistencija i to 9 Pablo Fernández

-- 6. Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без тренера), са упитима који их проналазе.

SELECT
    match_id,
    kickoff_ts,
    attendance
FROM matches
WHERE season = '2024/25' AND attendance IS NULL
ORDER BY match_id;

SELECT
    e.event_id,
    e.match_id,
    e.player_id
FROM match_events e LEFT JOIN players p ON e.player_id = p.player_id
WHERE e.player_id IS NOT NULL AND p.player_id IS NULL;

-- B6 - Devet utakmica nema evidentiran broj gledalaca. Postoje dva dogadjaja sa nepostojecim igracem.
