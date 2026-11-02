--------------------------------------------------------------------- Део Г - моделирање: звезда за дисциплину ---------------------------------------------------------------------
-- Управа лиге жели да анализира картоне: по судији, клубу, играчу и датуму. Направите звездастушему.

-- Табела          Шта садржи
-- dim_team        Сви клубови из teams
-- dim_date        Календар - као на часу
-- dim_player      Сви играчи из players, плус непознати члан са player_id = -1
-- dim_referee     Сви судије из referees
-- fact_card       Један ред по картону (yellow_card, second_yellow, red_card) из match_events

-- У fact_card ставите: event_id, match_id, date_key, team_id, player_id, referee_id и врсту картона. Догађаји са играчем кога нема у players добијају player_id = -1.

-- ZADACI:
-- 1. У part_d.sql направите и напуните табеле.
CREATE OR REPLACE TABLE dim_team AS
SELECT * FROM teams;
-- Kreiranje dim_team tabele

CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);
-- dim_date tabela kao sto smo radili

CREATE OR REPLACE TABLE dim_player AS
SELECT * FROM players;
-- Kreiranje dim_referee tabele
INSERT INTO dim_player (player_id) VALUES (-1);
-- Dodat nepoznati član sa player_id = -1

CREATE OR REPLACE TABLE dim_referee AS
SELECT * FROM referees;
-- Kreiranje dim_referee tabele

CREATE OR REPLACE TABLE fact_card AS
SELECT e.event_id, m.match_id, CAST(DATE_FORMAT(m.kickoff_ts, 'yyyyMMdd') AS INT) date_key, e.team_id, e.player_id, m.referee_id, e.event_type
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card');
-- Kreiranje fact_card tabele

UPDATE fact_card c
SET player_id = -1
WHERE NOT EXISTS (SELECT 1 FROM players p WHERE c.player_id = p.player_id);
-- Izmena vrednosti u koloni player_id kod slučajeva gde taj player_id ne postoji u tabeli players
SELECT * FROM fact_card ORDER BY player_id;


-- 2. Упитом покажите да fact_card има исто редова колико има картонских догађаја.
SELECT 
    (SELECT COUNT(*) FROM fact_card) fact_card_rows,
    COUNT(event_type) card_event_rows 
FROM fact_card
WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card');
-- 2678 redova

-- 3. Колико картона има player_id = -1?
SELECT COUNT(event_type) unknown_player_cards
FROM fact_card
WHERE player_id = -1;
-- Taj nepoznati igrač je dobio 2 kartona


-- 4. У README.md, у пар реченица опишите модел: шта је један ред у fact_card, који су кључеви(везе) и зашто мислите да картони имају своју табелу чињеница.