
/*


 */
DROP TABLE personal;
DROP TABLE lekare;
DROP TABLE oddeleni;
DROP TABLE personal_oddeleni;

DROP SEQUENCE oddeleni_seq;
CREATE SEQUENCE oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

DROP SEQUENCE personal_oddeleni_seq;
CREATE SEQUENCE personal_oddeleni_seq START WITH 1 INCREMENT BY 1 NOCYCLE;

CREATE TABLE personal (
    rodne_cislo NUMBER PRIMARY KEY CHECK ( REGEXP_LIKE(rodne_cislo, '$[0-9]{2}(?:[0257][1-9]|[1368][0-2])(?:0[1-9]|[12][0-9]|3[01])/?[0-9]{3,4}^') ),
    jmeno VARCHAR2(100) NOT NULL,
    titul VARCHAR2(50) NOT NULL,
    datum_nastupu DATE NOT NULL,
    kontakt VARCHAR2(13) NOT NULL
);

CREATE TABLE lekare (
    specializacia VARCHAR2(40) NOT NULL,
    rodne_cislo NUMBER NOT NULL,

    CONSTRAINT rodne_cislo_lekare FOREIGN KEY (rodne_cislo) REFERENCES personal(rodne_cislo)
);

CREATE TABLE oddeleni (
    id NUMBER PRIMARY KEY,
    nazev VARCHAR2(40) NOT NULL,
    kapacita NUMBER NOT NULL,
    typ VARCHAR(20) NOT NULL CHECK ( REGEXP_LIKE(typ, '(urgentni)|(luzkove)|(transfuzni)|(infekcni)') )
);

CREATE TABLE pacienty (
    id NUMBER PRIMARY KEY, -- TODO: rodne cislo?
    jmeno VARCHAR2(100) NOT NULL,
    titul VARCHAR2(50) NOT NULL,
    kontakt VARCHAR2(13) NOT NULL,
    datum_narozeni DATE NOT NULL,
    pojistovna NUMBER NOT NULL, -- TODO: pridajme check na poistence?
    zdravotni_karta NUMBER NOT NULL -- TODO: same?
);

CREATE TABLE leky (
    id NUMBER PRIMARY KEY,
    nazev VARCHAR2(40) NOT NULL,
    ucinna_latka VARCHAR2(50) NOT NULL,
    sila_leku VARCHAR2(20) NOT NULL,
    kontradikce VARCHAR2(100) NOT NULL
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

CREATE TABLE hospitalizace (
    id NUMBER PRIMARY KEY,
    cas_hospitalizaci TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis VARCHAR2(200),
    pacient NUMBER NOT NULL,
    lekar NUMBER NOT NULL,
    oddeleni NUMBER NOT NULL,

    CONSTRAINT nemocny FOREIGN KEY (pacient) REFERENCES pacienty(id) ON DELETE CASCADE,
    CONSTRAINT osetrujici_lekar FOREIGN KEY (lekar) REFERENCES personal(rodne_cislo) ON DELETE CASCADE,
    CONSTRAINT na_oddeleni FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE
);

CREATE TABLE vysetreni (
    id NUMBER PRIMARY KEY,
    cas_vysetreni TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    popis VARCHAR2(200) NOT NULL,
    vysledek VARCHAR2(200),
    oddeleni NUMBER NOT NULL,
    hospitalicace NUMBER NOT NULL,
    lekar NUMBER NOT NULL,

    CONSTRAINT na_oddeleni FOREIGN KEY (oddeleni) REFERENCES oddeleni(id) ON DELETE CASCADE,
    CONSTRAINT v_ramci_hospitalizaci FOREIGN KEY (hospitalicace) REFERENCES hospitalizace(id) ON DELETE CASCADE,
    CONSTRAINT prevedl FOREIGN KEY (lekar) REFERENCES personal(rodne_cislo) ON DELETE CASCADE
);
