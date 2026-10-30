---------------------------------------------------------------------------- Део А - питања о подацима ----------------------------------------------------------------------------

-- 1.
-- Колико утакмица је одиграно у фебруару 2025?
SELECT 
    COUNT(*) total_matches_feb_2025
FROM matches
WHERE kickoff_ts >= '2025-02-01' AND kickoff_ts < '2025-03-01' AND status = 'played';
-- 40 utakmica je odigrano u februaru 2025-te


-- 2.
-- Који стадион има највећи капацитет, а који је највећи стадион неког клуба?
SELECT 
    stadium_name,
    capacity
FROM stadiums
ORDER BY capacity DESC;
-- najveci kapacitet ima National Stadium - 80.000 gledalaca ali na tom stadionu ne igra ni jedan klub
SELECT
    t.team_name,
    s.stadium_name,
    s.capacity
FROM stadiums s
JOIN teams t ON s.stadium_id = t.stadium_id
ORDER BY capacity DESC;
-- najveci stadion nekog kluba je Harbourside Park, na kojem igra Northport United i ima kapacitet od 52.000 gledalaca


-- 3.
-- Колико играча у лиги има српско држављанство (
-- nationality = 'Serbia'
-- )?
SELECT
    COUNT(*) players_from_serbia
FROM players
WHERE nationality = 'Serbia';
-- ima ih 42


-- 4.
-- Колико утакмица је завршено резултатом 1:1?
SELECT 
    * 
FROM matches
WHERE home_goals = 1 AND away_goals = 1;
-- 94 utakmica je zavrseno tim rezultatom


-- 5.
-- Колика је просечна посета по сезони?
SELECT 
    season,
    ROUND(AVG(attendance), 0) avg_attendance
FROM matches
GROUP BY season;
-- U sezoni 2023/24 - 24.253 gledalaca a u sezoni 2024/25 - 24.199 gledalaca


-- 6.
-- Колико голова је дато из пенала по сезони?
SELECT 
    season,
    COUNT(*) penalty_goals
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
WHERE e.event_type = 'penalty_goal'
GROUP BY season;
-- U sezoni 2023/24 - 104 golova iz penala a u sezoni 2024/25 - 109 uspešno izvedenih jedanaesteraca


-- 7.
-- Колико различитих играча је дало бар један гол у сезони 2024/25?
SELECT DISTINCT 
    COUNT(DISTINCT e.player_id) goal_scorers_2024_25
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal');
-- 308 razlicitih igraca je postiglo pogodak protivničkoj ekipi u sezoni 2024/25


-- 8.
-- Који судија је највише пута судио утакмице клуба Northport United?
SELECT
    r.referee_id,
    r.referee_name,
    COUNT(*) northport_united_matches_associated
FROM matches m
JOIN teams h ON m.home_team_id = h.team_id
JOIN teams a ON m.away_team_id = a.team_id
JOIN referees r ON m.referee_id = r.referee_id
WHERE h.team_name = 'Northport United' OR a.team_name = 'Northport United'
GROUP BY r.referee_id,
         r.referee_name
ORDER BY COUNT(*) DESC;
-- Peter Lindgren je čak u 9 utakmica sudio utakmice kluba Northport United 


-- 9.
-- Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар једанпенал, дат или промашен?
WITH ref_penalty_games AS (
SELECT 
    r.referee_id,
    r.referee_name,
    COUNT(DISTINCT e.match_id) matches_with_penalties_by_referee
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN referees r ON m.referee_id = r.referee_id
WHERE m.season = '2024/25' AND e.event_type IN ('penalty_miss', 'penalty_goal')
GROUP BY r.referee_id,
        r.referee_name
)
SELECT 
    referee_name,
    matches_with_penalties_by_referee,
    SUM(matches_with_penalties_by_referee) OVER() total_penalty_matches,
    100.0 * matches_with_penalties_by_referee / total_penalty_matches AS penalty_games_share_pct
FROM ref_penalty_games
ORDER BY penalty_games_share_pct DESC;
-- Peter Lindgren je sudio 9 od 105 utakmica sa bar jednim penalom iliti 8.57% takvih utakmica


-- 10.
-- Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио наполувремену? Рачунајте и домаће и гостујуће утакмице.
