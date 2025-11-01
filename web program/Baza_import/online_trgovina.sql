CREATE DATABASE online_trgovina;
USE online_trgovina;

-- PRAVLJENJE TABELA

CREATE TABLE KORISNIK (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Ime VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Lozinka VARCHAR(255) NOT NULL
);

CREATE TABLE PROIZVOD (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Naziv VARCHAR(100) NOT NULL,
    Cijena DECIMAL(10, 2) NOT NULL,
    Zaliha INT NOT NULL,
    Popust INT DEFAULT 0
);

CREATE TABLE NARUDZBA (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    KorisnikID INT NOT NULL,
    DatumKreiranja TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Na čekanju', 'Potvrđeno', 'Otpremljeno', 'Dostavljeno') DEFAULT 'Na čekanju',
    FOREIGN KEY (KorisnikID) REFERENCES KORISNIK(ID)
);

CREATE TABLE STAVKE_NARUDZBE (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NarudzbaID INT NOT NULL,
    ProizvodID INT NOT NULL,
    Kolicina INT NOT NULL,
    FOREIGN KEY (NarudzbaID) REFERENCES NARUDZBA(ID),
    FOREIGN KEY (ProizvodID) REFERENCES PROIZVOD(ID)
);

CREATE TABLE LOG (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Stara_zaliha INT NOT NULL,
    Nova_zaliha INT NOT NULL,
    Datum_izmjene TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE NOTIFIKACIJA (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Poruka TEXT NOT NULL,
    Datum TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ARHIVA (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    KorisnikID INT NOT NULL,
    DatumKreiranja TIMESTAMP NOT NULL,
    Status ENUM('Na čekanju', 'Potvrđeno', 'Otpremljeno', 'Dostavljeno') NOT NULL,
    FOREIGN KEY (KorisnikID) REFERENCES KORISNIK(ID)
);

------ PRAVLJENJE TRIGGERA 

CREATE TRIGGER azuriraj_status_narudzbe
AFTER INSERT ON STAVKE_NARUDZBE
FOR EACH ROW
BEGIN
    UPDATE NARUDZBA
    SET Status = 'Potvrđeno'
    WHERE ID = NEW.NarudzbaID AND Status = 'Na čekanju';
END;

CREATE TRIGGER log_izmjena
AFTER UPDATE ON PROIZVOD
FOR EACH ROW
BEGIN
    INSERT INTO LOG (Stara_zaliha, Nova_zaliha, Datum_izmjene)
    VALUES (OLD.Zaliha, NEW.Zaliha, NOW());
END;

-- PRAVLJENJE PROCEDURE 

CREATE PROCEDURE azuriraj_zalihe(IN id_proizvoda INT, IN kolicina INT)
BEGIN
    DECLARE zaliha INT;

    SELECT Zaliha INTO zaliha FROM PROIZVOD WHERE ID = id_proizvoda;

    IF zaliha >= kolicina THEN
        UPDATE PROIZVOD
        SET Zaliha = Zaliha - kolicina
        WHERE ID = id_proizvoda;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nema dovoljno zaliha na stanju!';
    END IF;
END;

CREATE PROCEDURE postavi_na_akciju(IN f_popust INT, IN f_zaliha INT, IN f_period INT)
BEGIN
    UPDATE PROIZVOD
    SET Popust = f_popust
    WHERE Zaliha >= f_zaliha AND NOT EXISTS (
        SELECT 1 FROM STAVKE_NARUDZBE
        WHERE ProizvodID = PROIZVOD.ID AND
              DATEDIFF(NOW(), DatumKreiranja) <= f_period
    );
END;

-- PRAVLJENJE FUNKCIJE 

CREATE FUNCTION cijena_narudzbe(id_narudzba INT)
RETURNS DECIMAL(10, 2)
BEGIN
    RETURN (
        SELECT SUM(P.Cijena * SN.Kolicina * (1 - P.Popust / 100))
        FROM STAVKE_NARUDZBE SN
        JOIN PROIZVOD P ON SN.ProizvodID = P.ID
        WHERE SN.NarudzbaID = id_narudzba
    );
END;

-- PROCEDURA KORISNIKOVE NARUDZBE 

CREATE PROCEDURE korisnikove_narudzbe(IN korisnik_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE narudzba_id INT;
    DECLARE narudzba_cursor CURSOR FOR
        SELECT ID FROM NARUDZBA WHERE KorisnikID = korisnik_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN narudzba_cursor;

    read_loop: LOOP
        FETCH narudzba_cursor INTO narudzba_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        SELECT * FROM STAVKE_NARUDZBE WHERE NarudzbaID = narudzba_id;
    END LOOP;

    CLOSE narudzba_cursor;
END;

-- EVENTI POPUST, ZALIHA I  ARHIVIRANJE

CREATE EVENT automatski_popust
ON SCHEDULE EVERY 1 DAY
DO
    CALL postavi_na_akciju(20, 50, 2);

CREATE EVENT provjeri_zalihe
ON SCHEDULE EVERY 1 DAY
DO
    INSERT INTO NOTIFIKACIJA (Poruka, Datum)
    SELECT 'Niske zalihe za određene proizvode', NOW()
    WHERE EXISTS (
        SELECT 1 FROM PROIZVOD WHERE Zaliha < 10
    );

CREATE EVENT arhiviranje_narudzbi
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    INSERT INTO ARHIVA (ID, KorisnikID, DatumKreiranja, Status)
    SELECT ID, KorisnikID, DatumKreiranja, Status FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365;

    DELETE FROM STAVKE_NARUDZBE WHERE NarudzbaID IN (
        SELECT ID FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365
    );

    DELETE FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365;
END;
