# Sava Jovanović

SQL projekat koji sadrži konačne testove i provere o tome šta smo naučili na kursu.

Pretpostavke:

- DEO A, zadatak 7 - Колико различитих играча је дало бар један гол у сезони 2024/25? / Pretpostavka je da se u golove ne ubrajaju auto golovi.


Model koji smo sastavili u poslednjem delu zadataka se sastoji od fact_card tabele činjenica i nekoliko tabela dimenzija (dim_team, dim_date, dim_player i dim_referee).  
Jedan ~~čovek sreće ne 'mao~~ red u tabeli fact_card označava jedan karton (žuti, drugi žuti ili crveni) koji se dogodio na nekom meču. Tako da ova tabela u sebi sadrži podatke o svim kartonima koji su se desili na svim utakmicama koje imamo u našim podacima. Mi sada kada imamo ovu tabelu činjenica, možemo da je povezujemo sa ostalim dimenzionim tabelama i da jednostavno filtriramo ili agregiramo podatke iz ove tabele.  
Veze za povezivanje dimenzionih tabela sa tabelom činjenica su: date_key, team_id, player_id, referee_id a primary key je event_id kao kolona sa jedinstvenim oznakama svakog kartonskog događaja.  
Neki od najznačajnijih analiza koje mozemo vrsiti su: kartoni po sezoni i po mesecu; po igraču, poziciji ili nacionalnosti; po sudijama i njihovoj nacionalnosti; po timovima.