/*
    IDS projekt - Nemocnica (zadanie c. 30 z IUS)
    Autori: János László Vasík (xvasik05), Václav Zapletal (xzaple40)
 */

-- DROP tabulek
DROP TABLE personal CASCADE CONSTRAINTS;
DROP TABLE lekare CASCADE CONSTRAINTS;
DROP TABLE oddeleni CASCADE CONSTRAINTS;
DROP TABLE pacienty CASCADE CONSTRAINTS;
DROP TABLE leky CASCADE CONSTRAINTS;
DROP TABLE hospitalizace CASCADE CONSTRAINTS;
DROP TABLE davky CASCADE CONSTRAINTS;
DROP TABLE vysetreni CASCADE CONSTRAINTS;

DROP TABLE personal_oddeleni;
DROP TABLE lekar_leky;
DROP TABLE sestra_davka;
DROP TABLE lek_davka;

PURGE RECYCLEBIN;
-----------------------------------------

-- Vytvareni tabulek
CREATE TABLE personal
(
    rodne_cislo   VARCHAR2(11) PRIMARY KEY CHECK ( REGEXP_LIKE(rodne_cislo, '[0-9]{2}[0156][0-9][0-3][0-9]/[0-9]{3,4}') ),
    jmeno         NVARCHAR2(100) NOT NULL,
    titul         NVARCHAR2(50)  NOT NULL,
    datum_nastupu DATE           NOT NULL,
    kontakt       VARCHAR2(13)   NOT NULL
);

-- Generalizace, lekar dedi atributy personalu a je pridana specializace.
CREATE TABLE lekare
(
    rodne_cislo   VARCHAR2(11) PRIMARY KEY REFERENCES personal (rodne_cislo) ON DELETE CASCADE,
    specializacia NVARCHAR2(40) NOT NULL
);

CREATE TABLE oddeleni
(
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazev       NVARCHAR2(40) NOT NULL,
    kapacita    NUMBER        NOT NULL,
    volne_mista NUMBER        NOT NULL,
    typ         NVARCHAR2(20) NOT NULL CHECK ( REGEXP_LIKE(typ, '(urgentní)|(lůžkové)|(transfuzní)|(infekcní)') )
);

CREATE TABLE pacienty
(
    rodne_cislo     VARCHAR2(11) PRIMARY KEY CHECK (REGEXP_LIKE(rodne_cislo, '[0-9]{2}[0156][0-9][0-3][0-9]/[0-9]{3,4}') ),
    jmeno           NVARCHAR2(100) NOT NULL,
    titul           NVARCHAR2(50)  NOT NULL,
    kontakt         VARCHAR2(13)   NOT NULL,
    datum_narozeni  DATE           NOT NULL,
    pojistovna      NUMBER         NOT NULL CHECK ( REGEXP_LIKE(pojistovna, '(111)|(201)|(205)|(207)|(209)|(211)|(213)') ),
    zdravotni_karta NUMBER         NOT NULL
);

CREATE TABLE leky
(
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazev        NVARCHAR2(40)  NOT NULL,
    ucinna_latka NVARCHAR2(50)  NOT NULL,
    sila_leku    VARCHAR2(20)   NOT NULL,
    kontradikce  NVARCHAR2(100) NOT NULL
);

CREATE TABLE hospitalizace
(
    id                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_hospitalizaci TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    cas_ukonceni      TIMESTAMP WITH LOCAL TIME ZONE,
    popis             NVARCHAR2(200),
    pacient           VARCHAR2(11)                   NOT NULL,
    lekar             VARCHAR2(11)                   NOT NULL,
    oddeleni          NUMBER                         NOT NULL,

    CONSTRAINT nemocny FOREIGN KEY (pacient) REFERENCES pacienty (rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT osetrujici_lekar FOREIGN KEY (lekar) REFERENCES lekare (rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT na_oddeleni FOREIGN KEY (oddeleni) REFERENCES oddeleni (id) ON DELETE CASCADE
);

CREATE TABLE davky
(
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_podani    TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    mnozstvi      NUMBER                         NOT NULL,
    hospitalicace NUMBER                         NOT NULL,
    pacienty      VARCHAR2(11)                   NOT NULL,

    CONSTRAINT v_ramci_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace (id) ON DELETE CASCADE,
    CONSTRAINT pro_pacienta FOREIGN KEY (pacienty) REFERENCES pacienty (rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE vysetreni
(
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_vysetreni TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis         NVARCHAR2(200)                 NOT NULL,
    vysledek      NVARCHAR2(200),
    oddeleni      NUMBER                         NOT NULL,
    hospitalicace NUMBER                         NOT NULL,
    lekar         VARCHAR2(11)                   NOT NULL,

    CONSTRAINT prebiha_na FOREIGN KEY (oddeleni) REFERENCES oddeleni (id) ON DELETE CASCADE,
    CONSTRAINT prubeh_v_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace (id) ON DELETE CASCADE,
    CONSTRAINT prevedl FOREIGN KEY (lekar) REFERENCES lekare (rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE personal_oddeleni
(
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    telefon     VARCHAR2(13)  NOT NULL,
    uvazek      NVARCHAR2(13) NOT NULL,
    rodne_cislo VARCHAR2(11)  NOT NULL,
    id_oddeleni NUMBER        NOT NULL,

    CONSTRAINT uvazek_k_oddeleni FOREIGN KEY (id_oddeleni) REFERENCES oddeleni (id) ON DELETE CASCADE,
    CONSTRAINT uvazek_k_personalu FOREIGN KEY (rodne_cislo) REFERENCES personal (rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE lekar_leky
(
    id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lekar VARCHAR2(11) NOT NULL,
    lek   NUMBER       NOT NULL,

    CONSTRAINT predepisuje FOREIGN KEY (lekar) REFERENCES lekare (rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT je_predepsanej FOREIGN KEY (lek) REFERENCES leky (id) ON DELETE CASCADE
);

CREATE TABLE sestra_davka
(
    id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sestra VARCHAR2(11) NOT NULL,
    davka  NUMBER       NOT NULL,

    CONSTRAINT podala FOREIGN KEY (sestra) REFERENCES personal (rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT podana_davka FOREIGN KEY (davka) REFERENCES davky (id) ON DELETE CASCADE
);

CREATE TABLE lek_davka
(
    id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lek   NUMBER NOT NULL,
    davka NUMBER NOT NULL,

    CONSTRAINT je_soucasti FOREIGN KEY (lek) REFERENCES leky (id) ON DELETE CASCADE,
    CONSTRAINT patricna_davka FOREIGN KEY (davka) REFERENCES davky (id) ON DELETE CASCADE
);
-----------------------------------------

-- Triggery

-- Dekrementace volnych mist na oddeleni pri vytvoreni nove hospitalizace
CREATE OR REPLACE TRIGGER decrement_volne_mista
    AFTER INSERT
    ON hospitalizace
    FOR EACH ROW
DECLARE
    n_volne_mista NUMBER;
BEGIN
    SELECT volne_mista INTO n_volne_mista FROM oddeleni WHERE id = :NEW.oddeleni;
    IF :NEW.cas_ukonceni IS NULL AND n_volne_mista = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Na tomto oddeleni neni volne misto.');
        RAISE_APPLICATION_ERROR(-20001, 'Na tomto oddeleni neni volne misto.');
    ELSE
        UPDATE oddeleni
        SET volne_mista = volne_mista - 1
        WHERE id = :NEW.oddeleni;
    END IF;
END;

-- Inkrementace volnych mist na oddeleni pri ukonceni hospitalizace
CREATE OR REPLACE TRIGGER increment_volne_mista
    AFTER UPDATE
    ON hospitalizace
    FOR EACH ROW
BEGIN
    IF :OLD.cas_ukonceni IS NULL AND :NEW.cas_ukonceni IS NOT NULL THEN
        UPDATE oddeleni
        SET volne_mista = volne_mista + 1
        WHERE id = :OLD.oddeleni;
    END IF;
END;
-----------------------------------------

-- Procedury

-- Výpočet podílu pirazených hospitalizaci pro lekare na oddelení
CREATE OR REPLACE PROCEDURE podil_prace(oddeleni_id IN oddeleni.id%TYPE) IS
    CURSOR c_lekar IS
        SELECT po.rodne_cislo
        FROM personal_oddeleni po
        WHERE po.id_oddeleni = oddeleni_id
          AND po.rodne_cislo IN (SELECT rodne_cislo FROM lekare);
    celk_pocet   NUMBER := 0;
    podil_lekare NUMBER;
    procento     NUMBER;
BEGIN
    SELECT COUNT(id) INTO celk_pocet FROM hospitalizace WHERE oddeleni = oddeleni_id;
    FOR l IN c_lekar
        LOOP
            SELECT COUNT(id)
            INTO podil_lekare
            FROM hospitalizace
            WHERE oddeleni = oddeleni_id
              AND lekar = l.rodne_cislo;
            procento := ROUND(podil_lekare / celk_pocet * 100, 2);
            DBMS_OUTPUT.PUT_LINE('Lekar ' || l.rodne_cislo || ' ma podil ' || procento || '% na oddeleni ' ||
                                 oddeleni_id);
        END LOOP;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Neni zadne hospitalizace na tomto oddeleni.');
END;

-- Prevod tel. cisel pacientu na format +420
CREATE OR REPLACE PROCEDURE formatuj_kontakty IS
    CURSOR c_kontakt IS
        SELECT kontakt
        FROM pacienty;
    v_kontakt pacienty.kontakt%TYPE;
BEGIN
    FOR p IN c_kontakt
        LOOP
            IF REGEXP_LIKE(p.kontakt, '\+[0-9]{12}') THEN
                CONTINUE;
            ELSIF REGEXP_LIKE(p.kontakt, '[0-9]{10}') THEN
                v_kontakt := '+42' || p.kontakt;
                UPDATE pacienty
                SET kontakt = v_kontakt
                WHERE kontakt = p.kontakt;
            ELSE
                DBMS_OUTPUT.PUT_LINE('Kontakt ' || p.kontakt || ' nelze formátovat.');
            END IF;
        END LOOP;
END;

-----------------------------------------

-- Přístupová práva
GRANT ALL ON personal TO xvasik05;
GRANT ALL ON lekare TO xvasik05;
GRANT ALL ON oddeleni TO xvasik05;
GRANT ALL ON pacienty TO xvasik05;
GRANT ALL ON leky TO xvasik05;
GRANT ALL ON hospitalizace TO xvasik05;
GRANT ALL ON davky TO xvasik05;
GRANT ALL ON vysetreni TO xvasik05;
GRANT ALL ON personal_oddeleni TO xvasik05;
GRANT ALL ON lekar_leky TO xvasik05;
GRANT ALL ON sestra_davka TO xvasik05;
GRANT ALL ON lek_davka TO xvasik05;

GRANT EXECUTE ON podil_prace TO xvasik05;
GRANT EXECUTE ON formatuj_kontakty TO xvasik05;
GRANT SELECT ON hospitalizace_pacienta TO xvasik05;

-- Vlozeni dat
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000101/0001', 'Jan', 'MUDr.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000102/0002', 'Jana', 'MUDr.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000103/0003', 'Janko', 'DiS.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000104/0004', 'Janka', 'DiS.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');

INSERT INTO lekare (rodne_cislo, specializacia)
VALUES ('000101/0001', 'Chirurg');
INSERT INTO lekare (rodne_cislo, specializacia)
VALUES ('000102/0002', 'Všeobecný');

INSERT INTO oddeleni (nazev, kapacita, volne_mista, typ)
VALUES ('Chirurgia', 1, 1, 'urgentní');
INSERT INTO oddeleni (nazev, kapacita, volne_mista, typ)
VALUES ('Všeobecné', 20, 20, 'lůžkové');

INSERT INTO pacienty (rodne_cislo, jmeno, titul, kontakt, datum_narozeni, pojistovna, zdravotni_karta)
VALUES ('100000/1000', 'Janko', 'Ing.', '0123456789', TO_DATE('2000-01-01', 'YYYY/MM/DD'), 111, 123456789);
INSERT INTO pacienty (rodne_cislo, jmeno, titul, kontakt, datum_narozeni, pojistovna, zdravotni_karta)
VALUES ('200000/2000', 'Janka', 'Ing.', '+420123456789', TO_DATE('2000-01-01', 'YYYY/MM/DD'), 201, 123456789);

INSERT INTO leky (nazev, ucinna_latka, sila_leku, kontradikce)
VALUES ('Aspirin', 'Acetylsalicylová kyselina', '100mg', 'Nemocní s žaludečními vředy');
INSERT INTO leky (nazev, ucinna_latka, sila_leku, kontradikce)
VALUES ('Paralen', 'Paracetamol', '500mg', 'Nemocní s poškozenou jaterní funkcí');

INSERT INTO hospitalizace (cas_hospitalizaci, cas_ukonceni, popis, pacient, lekar, oddeleni)
VALUES (TO_DATE('2000-01-01', 'YYYY/MM/DD'), TO_DATE('2000-01-02', 'YYYY/MM/DD'), 'Popis', '100000/1000', '000101/0001',
        1);
INSERT INTO hospitalizace (cas_hospitalizaci, cas_ukonceni, popis, pacient, lekar, oddeleni)
VALUES (TO_DATE('2000-01-01', 'YYYY/MM/DD'), TO_DATE('2000-01-07', 'YYYY/MM/DD'), 'Popis', '200000/2000', '000102/0002',
        2);

INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 100, 1, '100000/1000');
INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-01 08:05:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 50, 2, '200000/2000');
INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-02 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 200, 1, '100000/1000');

INSERT INTO vysetreni (cas_vysetreni, popis, vysledek, oddeleni, hospitalicace, lekar)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 'Popis', 'Výsledek', 1, 1, '000101/0001');
INSERT INTO vysetreni (cas_vysetreni, popis, vysledek, oddeleni, hospitalicace, lekar)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 'Popis', 'Výsledek', 2, 2, '000102/0002');

INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('0123456789', 'Zkrácený', '000101/0001', 1);
INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('0123456789', 'Plný', '000102/0002', 2);
INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('0123456789', 'Zkrácený', '000103/0003', 1);
INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('0123456789', 'Plný', '000104/0004', 2);
INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('0123456789', 'Zkrácený', '000101/0001', 2);

INSERT INTO lekar_leky (lekar, lek)
VALUES ('000101/0001', 1);
INSERT INTO lekar_leky (lekar, lek)
VALUES ('000102/0002', 2);

INSERT INTO sestra_davka (sestra, davka)
VALUES ('000103/0003', 1);
INSERT INTO sestra_davka (sestra, davka)
VALUES ('000104/0004', 2);
INSERT INTO sestra_davka (sestra, davka)
VALUES ('000103/0003', 3);

INSERT INTO lek_davka (lek, davka)
VALUES (1, 1);
INSERT INTO lek_davka (lek, davka)
VALUES (2, 2);
INSERT INTO lek_davka (lek, davka)
VALUES (1, 3);
-----------------------------------------

-- Seznam lékařů a jejich specializace
SELECT p.jmeno AS lekar_jmeno, l.specializacia AS lekar_specializace
FROM lekare l
         JOIN personal p ON l.rodne_cislo = p.rodne_cislo;

-- Seznam pacientů a jejich příslušné hospitalizace:
SELECT p.jmeno AS pacient_jmeno, h.cas_hospitalizaci, h.popis
FROM pacienty p
         JOIN hospitalizace h ON p.rodne_cislo = h.pacient;

-- Všichni pacienti, kteří byli hospitalizováni na oddělení chirurgie.
SELECT p.jmeno, p.datum_narozeni, p.pojistovna, p.zdravotni_karta
FROM pacienty p
         JOIN hospitalizace h ON p.rodne_cislo = h.pacient
         JOIN oddeleni o ON h.oddeleni = o.id
WHERE o.nazev = 'Chirurgia';

-- Počet hospitalizací na každém oddělení
SELECT o.nazev AS oddeleni, COUNT(h.id) AS pocet_hospitalizaci
FROM oddeleni o
         JOIN hospitalizace h ON o.id = h.oddeleni
GROUP BY o.nazev;

-- Celkový počet podaných léků na každém oddělení
SELECT o.nazev AS oddeleni, COUNT(d.id) AS celkovy_pocet_podanych_leku
FROM oddeleni o
         JOIN hospitalizace h ON o.id = h.oddeleni
         JOIN davky d ON h.id = d.hospitalicace
GROUP BY o.nazev;

-- Všetci pacienti, kterím byl podán lék Aspirin
SELECT p.jmeno, p.datum_narozeni, p.pojistovna, p.zdravotni_karta
FROM pacienty p
         JOIN davky d ON p.rodne_cislo = d.pacienty
WHERE EXISTS(SELECT *
             FROM lek_davka ld
                      JOIN leky l ON ld.lek = l.id
             WHERE l.nazev = 'Aspirin'
               AND ld.davka = d.id);

-- Všetci lekári, ktorí sa venovali pacientovi Janko.
SELECT p.titul, p.jmeno, l.specializacia
FROM lekare l
         JOIN personal p ON l.rodne_cislo = p.rodne_cislo
WHERE l.rodne_cislo
          IN (SELECT h.lekar
              FROM hospitalizace h
                       JOIN pacienty p ON h.pacient = p.rodne_cislo
              WHERE p.jmeno = 'Janko');
-----------------------------------------

-- Provádení triggerů

-- Dekrementace volnych mist na oddeleni pri vytvoreni nove hospitalizace
SELECT volne_mista
FROM oddeleni
WHERE id = 2; -- 19
INSERT INTO hospitalizace (cas_hospitalizaci, popis, pacient, lekar, oddeleni)
VALUES (TO_DATE('2001-01-01', 'YYYY/MM/DD'), 'Popis', '100000/1000', '000102/0002', 2);
SELECT volne_mista
FROM oddeleni
WHERE id = 2; -- 18

-- INSERT INTO hospitalizace (cas_hospitalizaci, popis, pacient, lekar, oddeleni)
-- VALUES (TO_DATE('2000-01-01', 'YYYY/MM/DD'), 'Popis', '100000/1000', '000101/0001', 1); -- 0 volnych mist, error

-- Inkrementace volnych mist na oddeleni pri ukonceni hospitalizace
SELECT volne_mista
FROM oddeleni
WHERE id = 2; -- 18
UPDATE hospitalizace
SET cas_ukonceni = TO_DATE('2000-01-10', 'YYYY/MM/DD')
WHERE id = 3;
SELECT volne_mista
FROM oddeleni
WHERE id = 2; -- 19
-----------------------------------------

-- Provádění uložených procedur

BEGIN
    podil_prace(2); -- podil 100% - 0% na oddeleni 2

    INSERT INTO hospitalizace (cas_hospitalizaci, popis, pacient, lekar, oddeleni)
    VALUES (TO_DATE('2001-01-01', 'YYYY/MM/DD'), 'Popis', '100000/1000', '000101/0001', 2);

    podil_prace(2); -- podil 66.67% - 33.34% na oddeleni 2
END;

DECLARE
    v_kontakt pacienty.kontakt%TYPE;
BEGIN
    SELECT kontakt INTO v_kontakt FROM pacienty WHERE rodne_cislo = '100000/1000';
    DBMS_OUTPUT.PUT_LINE(v_kontakt); -- 0123456789
    formatuj_kontakty;
    SELECT kontakt INTO v_kontakt FROM pacienty WHERE rodne_cislo = '100000/1000';
    DBMS_OUTPUT.PUT_LINE(v_kontakt); -- +420123456789
END;
-----------------------------------------
-- Materializovaný pohled
DROP MATERIALIZED VIEW hospitalizace_pacienta;

-- Tento dotaz spouští xvasik05
CREATE MATERIALIZED VIEW hospitalizace_pacienta
REFRESH COMPLETE ON DEMAND
AS
SELECT p.rodne_cislo, p.jmeno, h.cas_hospitalizaci, h.cas_ukonceni, h.popis
FROM xzaple40.pacienty p
JOIN xzaple40.hospitalizace h ON p.rodne_cislo = h.pacient;

-----------------------------------------

-- Explain plan demonstrace

-- Před optimalizací
EXPLAIN PLAN FOR
SELECT o.nazev AS oddeleni, COUNT(h.id) AS pocet_hospitalizaci
FROM oddeleni o
JOIN hospitalizace h ON o.id = h.oddeleni
GROUP BY o.nazev;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Vytvořeni indexu tabulky hospitalicace pro sloupec oddělení. Prohledavaní v hospitalizacich bude prováděno pomocí daneho indexu namísto prohledavaní cele tabulky. 
-- Tim padem se urychlí i agregačni funkce COUNT() a to vede ke zrychlení operace GROUP BY.
CREATE INDEX index_hosp_odd ON hospitalizace(oddeleni);

-- DROP INDEX index_hosp_odd;

-- Po optimalizaci (sníží se cost)
EXPLAIN PLAN FOR
SELECT o.nazev AS oddeleni, COUNT(h.id) AS pocet_hospitalizaci
FROM oddeleni o
JOIN hospitalizace h ON o.id = h.oddeleni
GROUP BY o.nazev;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-----------------------------------------
