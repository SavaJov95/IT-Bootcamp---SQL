---------------------------------------------------------------------------- Део В - прозорске функције ----------------------------------------------------------------------------
-- Свако питање мора да користи бар једну прозорску функцију.

-- 1.Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећиудео?
WITH goals_stats AS (
SELECT 
    t.team_id,
    t.team_name,
    SUM(goals_for) total_goals_team
FROM team_matches m
JOIN teams t ON m.team_id = t.team_id
WHERE season = '2024/25'
GROUP BY t.team_id,
         t.team_name
)
SELECT 
    team_name,
    total_goals_team,
    SUM(total_goals_team) OVER() total_goals_league,
    ROUND(100.0 * total_goals_team / total_goals_league, 2) AS goals_share_pct,
    RANK() OVER(ORDER BY 100.0 * total_goals_team / SUM(total_goals_team) OVER() DESC) rnk
FROM goals_stats
QUALIFY rnk = 1;
-- Najveci udeo ima Kingsbridge City sa 7.6% datih golova u ukupnim golovima koji su pali u ligi.


-- 2.Која су три стадиона са највећом просечном посетом у сезони 2024/25?
WITH avg_att AS (
SELECT 
    stadium_id,
    AVG(attendance) average_attendance
FROM matches
WHERE season = '2024/25'
GROUP BY stadium_id
)
SELECT 
    stadium_name,
    ROUND(average_attendance, 0) aver_attendance,
    ROW_NUMBER() OVER(ORDER BY average_attendance DESC) rn
FROM avg_att a
JOIN stadiums s ON a.stadium_id = s.stadium_id
QUALIFY rn <= 3;
-- Harbourside Park, Kingsbridge Stadium i Northport Arena


-- 3.За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњигол дао најраније?
WITH last_goal_time AS (
SELECT 
    m.kickoff_ts,
    e.minute,
    e.added_time,
    t.team_name,
    p.first_name,
    p.last_name,
    ROW_NUMBER() OVER(PARTITION BY t.team_name ORDER BY m.kickoff_ts DESC, minute + COALESCE(added_time, 0) DESC) rn
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN teams t ON e.team_id = t.team_id
JOIN players p ON e.player_id = p.player_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
QUALIFY rn = 1
)
SELECT 
    team_name,
    kickoff_ts,
    minute,
    added_time
FROM last_goal_time
ORDER BY kickoff_ts, minute + COALESCE(added_time, 0);
-- Elmsworth Wanderers je svoj poslednji gol u sezonu dao jos 03. maja


-- 4.За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену уодносу на претходну домаћу утакмицу. Где је највећи пад?
SELECT 
    kickoff_ts,
    match_id,
    attendance,
    LAG(attendance) OVER(ORDER BY kickoff_ts, match_id) last_match_att,
    attendance - last_match_att AS att_diff
FROM matches m
JOIN teams t ON m.home_team_id = t.team_id
WHERE m.season = '2024/25' AND t.team_name = 'Northport United'
ORDER BY att_diff NULLS LAST;
-- Najveći pad je u utakmici sa id 2110, gde je na tribinama bilo 10.267 gledalaca manje nego na prethodnom meču


-- 5.Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој утакмици по реду и ког датума је прешао 50 бодова?
SELECT 
    kickoff_ts,
    match_id,
    points,
    SUM(points) OVER(ORDER BY kickoff_ts, match_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_total,
    ROW_NUMBER() OVER(ORDER BY SUM(points) OVER(ORDER BY kickoff_ts, match_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) rn
FROM team_matches m
JOIN teams t ON m.team_id = t.team_id
WHERE m.season = '2024/25' AND t.team_name = 'Northport City'
QUALIFY running_total >= 50;
-- Northport City je 12.01.2025. godine, u 21.meču sezone 2024/25, ostvarivši pobedu i nova tri boda prešao 50 bodova ukupno. 