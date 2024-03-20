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

DROP SEQUENCE personal_seq;
CREATE SEQUENCE personal_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE oddeleni_seq;
CREATE SEQUENCE oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE pacienty_seq;
CREATE SEQUENCE pacienty_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE leky_seq;
CREATE SEQUENCE leky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE hospitalizace_seq;
CREATE SEQUENCE hospitalizace_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE davky_seq;
CREATE SEQUENCE davky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE vysetreni_seq;
CREATE SEQUENCE vysetreni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE vysetreni_seq;
CREATE SEQUENCE vysetreni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE personal_oddeleni_seq;
CREATE SEQUENCE personal_oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE lekar_leky_seq;
CREATE SEQUENCE lekar_leky_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE sestra_davka_seq;
CREATE SEQUENCE sestra_davka_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE lek_davka_seq;
CREATE SEQUENCE lek_davka_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE TABLE personal (
    rodne_cislo NUMBER PRIMARY KEY CHECK ( REGEXP_LIKE(rodne_cislo, '$[0-9]{2}(?:[0257][1-9]|[1368][0-2])(?:0[1-9]|[12][0-9]|3[01])/?[0-9]{3,4}^') ),
    jmeno NVARCHAR2(100) NOT NULL,
    titul NVARCHAR2(50) NOT NULL,
    datum_nastupu DATE NOT NULL,
    kontakt VARCHAR2(13) NOT NULL
);

CREATE TABLE lekare (
    specializacia NVARCHAR2(40) NOT NULL,
    rodne_cislo NUMBER NOT NULL,

    CONSTRAINT rodne_cislo_lekare FOREIGN KEY (rodne_cislo) REFERENCES personal(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE oddeleni (
    id NUMBER PRIMARY KEY,
    nazev NVARCHAR2(40) NOT NULL,
    kapacita NUMBER NOT NULL,
    typ VARCHAR(20) NOT NULL CHECK ( REGEXP_LIKE(typ, '(urgentni)|(luzkove)|(transfuzni)|(infekcni)') )
);

CREATE TABLE pacienty (
    id NUMBER PRIMARY KEY, -- TODO: rodne cislo?
    jmeno NVARCHAR2(100) NOT NULL,
    titul NVARCHAR2(50) NOT NULL,
    kontakt VARCHAR2(13) NOT NULL,
    datum_narozeni DATE NOT NULL,
    pojistovna NUMBER NOT NULL, -- TODO: pridajme check na poistence?
    zdravotni_karta NUMBER NOT NULL -- TODO: same?
);

CREATE TABLE leky (
    id NUMBER PRIMARY KEY,
    nazev NVARCHAR2(40) NOT NULL,
    ucinna_latka NVARCHAR2(50) NOT NULL,
    sila_leku VARCHAR2(20) NOT NULL, -- TODO: ake data budu tu?
    kontradikce NVARCHAR2(100) NOT NULL
);

CREATE TABLE hospitalizace (
    id NUMBER PRIMARY KEY,
    cas_hospitalizaci TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis NVARCHAR2(200),
    pacient NUMBER NOT NULL,
    lekar NUMBER NOT NULL,
    oddeleni NUMBER NOT NULL,

    CONSTRAINT nemocny FOREIGN KEY (pacient) REFERENCES pacienty(id) ON DELETE CASCADE,
    CONSTRAINT osetrujici_lekar FOREIGN KEY (lekar) REFERENCES personal(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT na_oddeleni FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE
);

CREATE TABLE davky (
    id NUMBER PRIMARY KEY,
    cas_podani TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    mnozstvi NUMBER NOT NULL,
    hospitalicace NUMBER NOT NULL,
    pacienty NUMBER NOT NULL,

    CONSTRAINT v_ramci_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace(id) ON DELETE CASCADE,
    CONSTRAINT pro_pacienta FOREIGN KEY (pacienty) REFERENCES pacienty(id) ON DELETE CASCADE
);

CREATE TABLE vysetreni (
    id NUMBER PRIMARY KEY,
    cas_vysetreni TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis NVARCHAR2(200) NOT NULL,
    vysledek NVARCHAR2(200),
    oddeleni NUMBER NOT NULL,
    hospitalicace NUMBER NOT NULL,
    lekar NUMBER NOT NULL,

    CONSTRAINT prebiha_na FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE,
    CONSTRAINT prubeh_v_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace(id) ON DELETE CASCADE,
    CONSTRAINT prevedl FOREIGN KEY (lekar) REFERENCES personal(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE personal_oddeleni (
    id NUMBER PRIMARY KEY,
    telefon VARCHAR2(13) NOT NULL,
    uvazek VARCHAR2(13) NOT NULL, -- TODO: ake data budu tu?
    rodne_cislo NUMBER NOT NULL,
    id_oddeleni NUMBER NOT NULL,

    CONSTRAINT uvazek_k_oddeleni FOREIGN KEY (id_oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE,
    CONSTRAINT uvazek_k_personalu FOREIGN KEY (rodne_cislo) REFERENCES personal(rodne_cislo) ON DELETE CASCADE
);

CREATE TABLE lekar_leky (
    id NUMBER PRIMARY KEY,
    lekar NUMBER NOT NULL,
    lek NUMBER NOT NULL,

    CONSTRAINT predepisuje FOREIGN KEY (lekar) REFERENCES personal(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT je_predepsanej FOREIGN KEY (lek) REFERENCES leky(id) ON DELETE CASCADE
);

CREATE TABLE sestra_davka (
    id NUMBER PRIMARY KEY,
    sestra NUMBER NOT NULL,
    davka NUMBER NOT NULL,

    CONSTRAINT podala FOREIGN KEY (sestra) REFERENCES personal(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT podana_davka FOREIGN KEY (davka) REFERENCES davky(id) ON DELETE CASCADE
);

CREATE TABLE lek_davka (
    id NUMBER PRIMARY KEY,
    lek NUMBER NOT NULL,
    davka NUMBER NOT NULL,

    CONSTRAINT je_soucasti FOREIGN KEY (lek) REFERENCES leky(id) ON DELETE CASCADE,
    CONSTRAINT patricna_davka FOREIGN KEY (davka) REFERENCES davky(id) ON DELETE CASCADE
);
