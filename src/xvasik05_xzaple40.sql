/*
    IDS projekt - Nemocnica (zadanie c. 30 z IUS)
    Autori: Janos Laszlo Vasik (xvasik05), Václav Zapletal (xzaple40)
 */

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

-- DROP SEQUENCE oddeleni_seq;
-- CREATE SEQUENCE oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE leky_seq;
-- CREATE SEQUENCE leky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE hospitalizace_seq;
-- CREATE SEQUENCE hospitalizace_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE davky_seq;
-- CREATE SEQUENCE davky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE vysetreni_seq;
-- CREATE SEQUENCE vysetreni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE personal_oddeleni_seq;
-- CREATE SEQUENCE personal_oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE lekar_leky_seq;
-- CREATE SEQUENCE lekar_leky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE sestra_davka_seq;
-- CREATE SEQUENCE sestra_davka_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

-- DROP SEQUENCE lek_davka_seq;
-- CREATE SEQUENCE lek_davka_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE TABLE personal (
    rodne_cislo VARCHAR2(11) PRIMARY KEY CHECK ( REGEXP_LIKE(rodne_cislo, '[0-9]{2}[0156][0-9][0-3][0-9]/[0-9]{3,4}') ),
    jmeno NVARCHAR2(100) NOT NULL,
    titul NVARCHAR2(50) NOT NULL,
    datum_nastupu DATE NOT NULL,
    kontakt VARCHAR2(13) NOT NULL
);

-- Generalizace, lekar dedi atributy personalu a je pridana specializace.
CREATE TABLE lekare (
    rodne_cislo VARCHAR2(11) PRIMARY KEY REFERENCES personal(rodne_cislo) ON DELETE CASCADE, 
    specializacia NVARCHAR2(40) NOT NULL
);

CREATE TABLE oddeleni (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazev NVARCHAR2(40) NOT NULL,
    kapacita NUMBER NOT NULL,
    typ NVARCHAR2(20) NOT NULL CHECK ( REGEXP_LIKE(typ, '(urgentní)|(lůžkové)|(transfuzní)|(infekcní)') )
);

CREATE TABLE pacienty (
    rodne_cislo VARCHAR2(11) PRIMARY KEY CHECK (REGEXP_LIKE(rodne_cislo, '[0-9]{2}[0156][0-9][0-3][0-9]/[0-9]{3,4}') ),
    jmeno NVARCHAR2(100) NOT NULL,
    titul NVARCHAR2(50) NOT NULL,
    kontakt VARCHAR2(13) NOT NULL,
    datum_narozeni DATE NOT NULL,
    pojistovna NUMBER NOT NULL CHECK ( REGEXP_LIKE(pojistovna, '(111)|(201)|(205)|(207)|(209)|(211)|(213)') ),
    zdravotni_karta NUMBER NOT NULL
);

CREATE TABLE leky (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazev NVARCHAR2(40) NOT NULL,
    ucinna_latka NVARCHAR2(50) NOT NULL,
    sila_leku VARCHAR2(20) NOT NULL,
    kontradikce NVARCHAR2(100) NOT NULL
);

CREATE TABLE hospitalizace (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_hospitalizaci TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis NVARCHAR2(200),
    pacient VARCHAR2(11) NOT NULL,
    lekar VARCHAR2(11) NOT NULL,
    oddeleni NUMBER NOT NULL,

    CONSTRAINT nemocny FOREIGN KEY (pacient) REFERENCES pacienty(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT osetrujici_lekar FOREIGN KEY (lekar) REFERENCES lekare(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT na_oddeleni FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE
);

CREATE TABLE davky (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_podani TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    mnozstvi NUMBER NOT NULL,
    hospitalicace NUMBER NOT NULL,
    pacienty VARCHAR2(11) NOT NULL,

    CONSTRAINT v_ramci_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace(id) ON DELETE CASCADE,
    CONSTRAINT pro_pacienta FOREIGN KEY (pacienty) REFERENCES pacienty(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE vysetreni (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cas_vysetreni TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis NVARCHAR2(200) NOT NULL,
    vysledek NVARCHAR2(200),
    oddeleni NUMBER NOT NULL,
    hospitalicace NUMBER NOT NULL,
    lekar VARCHAR2(11) NOT NULL,

    CONSTRAINT prebiha_na FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE,
    CONSTRAINT prubeh_v_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace(id) ON DELETE CASCADE,
    CONSTRAINT prevedl FOREIGN KEY (lekar) REFERENCES lekare(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE personal_oddeleni (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    telefon VARCHAR2(13) NOT NULL,
    uvazek NVARCHAR2(13) NOT NULL,
    rodne_cislo VARCHAR2(11) NOT NULL,
    id_oddeleni NUMBER NOT NULL,

    CONSTRAINT uvazek_k_oddeleni FOREIGN KEY (id_oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE,
    CONSTRAINT uvazek_k_personalu FOREIGN KEY (rodne_cislo) REFERENCES personal(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE lekar_leky (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lekar VARCHAR2(11) NOT NULL,
    lek NUMBER NOT NULL,

    CONSTRAINT predepisuje FOREIGN KEY (lekar) REFERENCES lekare(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT je_predepsanej FOREIGN KEY (lek) REFERENCES leky(id) ON DELETE CASCADE
);

CREATE TABLE sestra_davka (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sestra VARCHAR2(11) NOT NULL,
    davka NUMBER NOT NULL,

    CONSTRAINT podala FOREIGN KEY (sestra) REFERENCES personal(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT podana_davka FOREIGN KEY (davka) REFERENCES davky(id) ON DELETE CASCADE
);

CREATE TABLE lek_davka (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lek NUMBER NOT NULL,
    davka NUMBER NOT NULL,

    CONSTRAINT je_soucasti FOREIGN KEY (lek) REFERENCES leky(id) ON DELETE CASCADE,
    CONSTRAINT patricna_davka FOREIGN KEY (davka) REFERENCES davky(id) ON DELETE CASCADE
);

INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000101/0001', 'Jan', 'Ing.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000102/0002', 'Jana', 'Ing.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000103/0003', 'Janko', 'Ing.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');
INSERT INTO personal (rodne_cislo, jmeno, titul, datum_nastupu, kontakt)
VALUES ('000104/0004', 'Janka', 'Ing.', TO_DATE('2000-01-01', 'YYYY/MM/DD'), '123456789');

INSERT INTO lekare (rodne_cislo, specializacia) VALUES ('000101/0001', 'Chirurg');
INSERT INTO lekare (rodne_cislo, specializacia) VALUES ('000102/0002', 'Všeobecný');

INSERT INTO oddeleni (nazev, kapacita, typ) VALUES ('Chirurgia', 20, 'urgentní');
INSERT INTO oddeleni (nazev, kapacita, typ) VALUES ('Všeobecné', 20, 'lůžkové');

INSERT INTO pacienty (rodne_cislo, jmeno, titul, kontakt, datum_narozeni, pojistovna, zdravotni_karta)
VALUES ('000101/0001', 'Janko', 'Ing.', '123456789', TO_DATE('2000-01-01', 'YYYY/MM/DD'), 111, 123456789);
INSERT INTO pacienty (rodne_cislo, jmeno, titul, kontakt, datum_narozeni, pojistovna, zdravotni_karta)
VALUES ('000102/0002', 'Janka', 'Ing.', '123456789', TO_DATE('2000-01-01', 'YYYY/MM/DD'), 201, 123456789);

INSERT INTO leky (nazev, ucinna_latka, sila_leku, kontradikce)
VALUES ('Aspirin', 'Acetylsalicylová kyselina', '100mg', 'Nemocní s žaludečními vředy');
INSERT INTO leky (nazev, ucinna_latka, sila_leku, kontradikce)
VALUES ('Paralen', 'Paracetamol', '500mg', 'Nemocní s poškozenou jaterní funkcí');

INSERT INTO hospitalizace (cas_hospitalizaci, popis, pacient, lekar, oddeleni)
VALUES (TO_DATE('2000-01-01', 'YYYY/MM/DD'), 'Popis', '000101/0001', '000101/0001', 1);
INSERT INTO hospitalizace (cas_hospitalizaci, popis, pacient, lekar, oddeleni)
VALUES (TO_DATE('2000-01-01', 'YYYY/MM/DD'), 'Popis', '000102/0002', '000102/0002', 2);

INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 1, 1, '000101/0001');
INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-01 08:05:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 1, 2, '000102/0002');
INSERT INTO davky (cas_podani, mnozstvi, hospitalicace, pacienty)
VALUES (TO_TIMESTAMP('2000-01-02 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 1, 1, '000102/0002');

INSERT INTO vysetreni (cas_vysetreni, popis, vysledek, oddeleni, hospitalicace, lekar)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 'Popis', 'Výsledek', 1, 1, '000101/0001');
INSERT INTO vysetreni (cas_vysetreni, popis, vysledek, oddeleni, hospitalicace, lekar)
VALUES (TO_TIMESTAMP('2000-01-01 08:00:00.00', 'YYYY-MM-DD HH24:MI:SS.FF'), 'Popis', 'Výsledek', 2, 2, '000102/0002');

INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('123456789', 'Plný', '000101/0001', 1);
INSERT INTO personal_oddeleni (telefon, uvazek, rodne_cislo, id_oddeleni)
VALUES ('123456789', 'Zkrácený', '000102/0002', 2);

INSERT INTO lekar_leky (lekar, lek) VALUES ('000101/0001', 1);
INSERT INTO lekar_leky (lekar, lek) VALUES ('000102/0002', 2);

INSERT INTO sestra_davka (sestra, davka) VALUES ('000103/0003', 1);
INSERT INTO sestra_davka (sestra, davka) VALUES ('000104/0004', 2);
INSERT INTO sestra_davka (sestra, davka) VALUES ('000103/0003', 3);

INSERT INTO lek_davka (lek, davka) VALUES (1, 1);
INSERT INTO lek_davka (lek, davka) VALUES (2, 2);
INSERT INTO lek_davka (lek, davka) VALUES (1, 3);
