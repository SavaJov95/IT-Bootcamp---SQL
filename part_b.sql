---------------------------------------------------------------------------- Део Б - извештај о сезони 2024/25 ----------------------------------------------------------------------------

-- Управа лиге тражи кратак извештај о сезони 2024/25. Предајете два фајла: извештај у формату поизбору (Markdown, Txt или PDF) и
-- part_b.sql
-- са свим упитима које сте користили. За свакиодељак у извештају дајте малу табелу или неколико бројева, и реченицу или две шта ти бројевизначе.


-- 1.
-- Преглед сезоне:
-- број утакмица и голова, просечан број голова по утакмици, удео победадомаћина, нерешених и победа гостију.
SELECT 
    COUNT(*) total_matches,
    SUM(home_goals + away_goals) total_goals,
    AVG(home_goals + away_goals) avg_goals,
    ROUND(100.0 * SUM(CASE WHEN home_goals > away_goals THEN 1 END) / COUNT(*), 2) total_home_wins_pct,
    ROUND(100.0 * SUM(CASE WHEN home_goals = away_goals THEN 1 END) / COUNT(*), 2) total_draws_pct,
    ROUND(100.0 * SUM(CASE WHEN home_goals < away_goals THEN 1 END) / COUNT(*), 2) total_away_wins_pct
FROM matches
WHERE status = 'played' AND season = '2024/25';
-- број утакмица - 380, голова - 1092, просечан број голова по утакмици - 2.87, удео победадомаћина 41.32%, нерешених 25% и победа гостију 33.68%

-- 2.
-- По месецима:
-- број утакмица и голова по месецима, и просечан број голова по утакмици усваком месецу. Који месец се издваја?
SELECT 
    MONTH(kickoff_ts) month,
    COUNT(*) monthly_matches,
    SUM(home_goals + away_goals) monthly_goals,
    ROUND(AVG(home_goals + away_goals), 1) monthly_avg_goals
FROM matches
WHERE status = 'played' AND season = '2024/25'
GROUP BY month
ORDER BY monthly_avg_goals DESC;
-- Avgust(osmi mesec) se izdvaja po broju prosečnih golova po meču sa 3.5 golova po utakmici 
-- dok se decembar izdvaja po broju golova palih u mesecu sa ukupno 145 pogodaka. 
-- To je zato sto decembar ima cak 52 odigranih utakmica.


-- 3.
-- Публика:
-- просечна посета и попуњеност по стадиону; утакмице без податка о посети иутакмица без публике.
WITH avg_att AS (
SELECT 
    s.stadium_id,
    s.capacity,
    s.stadium_name,
    AVG(m.attendance) avg_attendance
FROM matches m
JOIN stadiums s ON m.stadium_id = s.stadium_id
WHERE m.status = 'played' AND season = '2024/25'
GROUP BY s.stadium_id,
         s.capacity,
         s.stadium_name
)
SELECT 
    stadium_name,
    avg_attendance,
    ROUND(100.0 * avg_attendance / capacity, 2) AS capacity_usage_pct
FROM avg_att;

SELECT 
    *
FROM matches m
WHERE status = 'played' AND season = '2024/25' AND (attendance IS NULL OR attendance = 0);
-- 9 utakmica bez podataka o posecenosti u sezoni 2024/25 a svaka za koju imamo podataka, imala je publiku

SELECT 
    AVG(attendance) avg_attendance_2024_25
FROM matches
WHERE status = 'played' AND season = '2024/25';
-- 24199.5 gledalaca u proseku


-- 4.
-- Судије:
-- за сваког судију број утакмица и картони по утакмици.
WITH ref_matches AS (
SELECT 
    r.referee_id,
    r.referee_name,
    COUNT(*) total_matches
FROM matches m
JOIN referees r ON m.referee_id = r.referee_id
WHERE m.status = 'played' AND m.season = '2024/25'
GROUP BY r.referee_id,
         r.referee_name
),
total_cards AS (
SELECT 
    r.referee_id,
    r.referee_name,
    COUNT(*) ref_total_cards
FROM referees r
JOIN matches m ON m.referee_id = r.referee_id
JOIN match_events e ON m.match_id = e.match_id
WHERE m.status = 'played' AND m.season = '2024/25' AND e.event_type IN ('yellow_card', 'red_card', 'second_yellow')
GROUP BY r.referee_id,
         r.referee_name
)
SELECT 
    r.referee_id,
    r.referee_name,
    r.total_matches,
    t.ref_total_cards,
    t.ref_total_cards / r.total_matches cards_per_game
FROM ref_matches r
JOIN total_cards t ON r.referee_id = t.referee_id
ORDER BY cards_per_game DESC;
-- Peter Lindgren je pokazao najvise kartona po utakmici - 4.25.


-- 5.
-- Играчи:
-- пет најбољих стрелаца и пет најбољих асистената.
SELECT 
    p.player_id,
    p.first_name,
    p.last_name,
    COUNT(*) goals
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN players p ON e.player_id = p.player_id
WHERE m.status = 'played' AND m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id,
         p.first_name,
         p.last_name
ORDER BY goals DESC;
-- Najbolji strelci : Mattéo O'Brien sa 34 golova, Leo Marsh sa 32 golova, José Muñoz sa 24 golova, Marko Stanković sa 17 golova i Leo Marsh sa 16 golova 

SELECT 
    p.player_id,
    p.first_name,
    p.last_name,
    COUNT(*) assists
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN players p ON e.related_player_id = p.player_id
WHERE m.status = 'played' AND m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id,
         p.first_name,
         p.last_name
ORDER BY assists DESC;
-- Najbolji asistenti : Pablo Fernández sa 9 asistencija, Filip Petrović sa 7 asistencija, Lucas Pereira sa 7 asistencija, Eirik Solberg sa 7 asistencija i Mikkel Nielsen sa 6 asistencija 


-- 6.
-- Квалитет података:
-- бар два проблема на која сте наишли у подацима (на пример утакмицачији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан безтренера), са упитима који их проналазе.