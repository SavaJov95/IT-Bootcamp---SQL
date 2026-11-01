---------------------------------------------------------------------------- Део Б - извештај о сезони 2024/25 ----------------------------------------------------------------------------

-- Управа лиге тражи кратак извештај о сезони 2024/25. Предајете два фајла: извештај у формату поизбору (Markdown, Txt или PDF) и
-- part_b.sql
-- са свим упитима које сте користили. За свакиодељак у извештају дајте малу табелу или неколико бројева, и реченицу или две шта ти бројевизначе.


-- 1.Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа домаћина, нерешених и победа гостију.
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

-- 2.По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици усваком месецу. Који месец се издваја?
SELECT 
    DATE_FORMAT(kickoff_ts, 'MMMM') month,
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


-- 3.Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и утакмица без публике.
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
    ROUND(avg_attendance, 0) avg_attendance,
    ROUND(100.0 * avg_attendance / capacity, 2) AS capacity_usage_pct
FROM avg_att;

SELECT 
    ROUND(AVG(attendance), 0) avg_attendance_2024_25
FROM matches
WHERE status = 'played' AND season = '2024/25';

SELECT 
    *
FROM matches m
WHERE status = 'played' AND season = '2024/25' AND (attendance IS NULL OR attendance = 0);
-- 9 utakmica bez podataka o posecenosti u sezoni 2024/25 a svaka za koju imamo podataka, imala je publiku


-- 4.Судије: за сваког судију број утакмица и картони по утакмици.
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
    r.referee_name,
    r.total_matches,
    t.ref_total_cards,
    t.ref_total_cards / r.total_matches cards_per_game
FROM ref_matches r
JOIN total_cards t ON r.referee_id = t.referee_id
ORDER BY cards_per_game DESC;


-- 5.Играчи: пет најбољих стрелаца и пет најбољих асистената.
SELECT
    p.first_name,
    p.last_name,
    t.team_name,
    COUNT(*) goals
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN players p ON e.player_id = p.player_id
JOIN teams t ON e.team_id = t.team_id
WHERE m.status = 'played' AND m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id,
         p.first_name,
         p.last_name,
         t.team_name
ORDER BY goals DESC
LIMIT 5;
-- Najbolji strelci : Mattéo O'Brien sa 34 golova, Leo Marsh sa 32 golova, José Muñoz sa 24 golova, Marko Stanković sa 17 golova i Leo Marsh sa 16 golova 

SELECT 
    p.first_name,
    p.last_name,
    t.team_name,
    COUNT(*) assists
FROM matches m
JOIN match_events e ON m.match_id = e.match_id
JOIN players p ON e.related_player_id = p.player_id
JOIN teams t ON e.team_id = t.team_id
WHERE m.status = 'played' AND m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id,
         p.first_name,
         p.last_name,
         t.team_name
ORDER BY assists DESC
LIMIT 5;
-- Najbolji asistenti : Pablo Fernández sa 9 asistencija, Filip Petrović sa 7 asistencija, Lucas Pereira sa 7 asistencija, Eirik Solberg sa 7 asistencija i Mikkel Nielsen sa 6 asistencija 


-- 6.Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без тренера), са упитима који их проналазе.
SELECT 
    m.match_id,
    SUM(DISTINCT m.home_goals) + SUM(DISTINCT m.away_goals),
    COUNT(e.event_type)
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
WHERE e.event_type IN ('goal', 'penalty_goal', 'own_goal')
GROUP BY m.match_id
HAVING SUM(DISTINCT m.home_goals) + SUM(DISTINCT m.away_goals) <> COUNT(e.event_type);
-- nadjena utakmica 2227 sa neslaganjem podataka o rezultatu

SELECT * FROM matches WHERE match_id = 2227;
-- u tabeli matches imamo informaciju da je match sa id-jem 2227 zavrsen rezultatom 3:1 za domacina, team_id 21 i 12

SELECT * FROM match_events WHERE match_id = 2227 AND event_type IN ('goal', 'penalty_goal', 'own_goal');
-- u tabeli match_events imamo informaciju da je isti meč zavrsen rezultatom 2:1 za domacina, team_id 21, podaci se ne slazu


SELECT 
    * 
FROM match_events e
LEFT JOIN players p ON e.player_id = p.player_id
WHERE p.player_id IS NULL;
-- imamo fudbalera sa id-jem 99999, koji uopste i ne postoji u tabeli players ali je evidentiran u 
-- tabeli dogadjaji i to u 2 razlicita tima i na 2 razlicita meca kako je dobio zute kartone