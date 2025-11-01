

CREATE DATABASE IF NOT EXISTS `online_trgovina`;
USE `online_trgovina`;

DELIMITER $$

DROP PROCEDURE IF EXISTS `azuriraj_zalihe`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `azuriraj_zalihe` (IN `id_proizvoda` INT, IN `kolicina` INT)   BEGIN
    DECLARE zaliha INT;

    SELECT Zaliha INTO zaliha FROM PROIZVOD WHERE ID = id_proizvoda;

    IF zaliha >= kolicina THEN
        UPDATE PROIZVOD
        SET Zaliha = Zaliha - kolicina
        WHERE ID = id_proizvoda;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nema dovoljno zaliha na stanju!';
    END IF;
END$$

DROP PROCEDURE IF EXISTS `postavi_na_akciju`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `postavi_na_akciju` (IN `f_popust` INT, IN `f_zaliha` INT, IN `f_period` INT)   BEGIN
    UPDATE PROIZVOD
    SET Popust = f_popust
    WHERE Zaliha >= f_zaliha AND NOT EXISTS (
        SELECT 1 FROM STAVKE_NARUDZBE
        WHERE ProizvodID = PROIZVOD.ID AND
              DATEDIFF(NOW(), DatumKreiranja) <= f_period
    );
END$$

DROP FUNCTION IF EXISTS `cijena_narudzbe`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `cijena_narudzbe` (`id_narudzba` INT) RETURNS DECIMAL(10,2)  BEGIN
    RETURN (
        SELECT SUM(P.Cijena * SN.Kolicina * (1 - P.Popust / 100))
        FROM STAVKE_NARUDZBE SN
        JOIN PROIZVOD P ON SN.ProizvodID = P.ID
        WHERE SN.NarudzbaID = id_narudzba
    );
END$$

DELIMITER ;

DROP TABLE IF EXISTS `arhiva`;
CREATE TABLE IF NOT EXISTS `arhiva` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `KorisnikID` int(11) NOT NULL,
  `DatumKreiranja` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Status` enum('Na čekanju','Potvrđeno','Otpremljeno','Dostavljeno') NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `KorisnikID` (`KorisnikID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `korisnik`;
CREATE TABLE IF NOT EXISTS `korisnik` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Ime` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Lozinka` varchar(255) NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Email` (`Email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `korisnik` (`ID`, `Ime`, `Email`, `Lozinka`) VALUES
(1, 'Admin', 'admin@pmf.unsa.ba', 'admin'),
(2, 'meho', 'meho@pmf.unsa.ba', 'bugojno1'),
(3, 'mirza', 'mirza@pmf.unsa.ba', 'bugojno1'),
(4, 'roki', 'roki@gmail.com', '$2y$10$kXyIGjwWAWdnRLruxHQE.uKpFmpYKGktF8uvTJxKE48ieObIfide.');

DROP TABLE IF EXISTS `log`;
CREATE TABLE IF NOT EXISTS `log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Stara_zaliha` int(11) NOT NULL,
  `Nova_zaliha` int(11) NOT NULL,
  `Datum_izmjene` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`ID`)
)

INSERT INTO `log` (`ID`, `Stara_zaliha`, `Nova_zaliha`, `Datum_izmjene`) VALUES
(1, 10, 9, '2024-12-15 15:32:29'),
(2, 20, 19, '2024-12-15 15:32:44'),
(3, 10, 8, '2024-12-15 15:38:43');

DROP TABLE IF EXISTS `narudzba`;
CREATE TABLE IF NOT EXISTS `narudzba` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `KorisnikID` int(11) NOT NULL,
  `DatumKreiranja` timestamp NOT NULL DEFAULT current_timestamp(),
  `Status` enum('Na čekanju','Potvrđeno','Otpremljeno','Dostavljeno') DEFAULT 'Na čekanju',
  PRIMARY KEY (`ID`),
  KEY `KorisnikID` (`KorisnikID`)
)


INSERT INTO `narudzba` (`ID`, `KorisnikID`, `DatumKreiranja`, `Status`) VALUES
(1, 4, '2024-12-15 15:32:29', 'Potvrđeno'),
(2, 4, '2024-12-15 15:32:44', 'Potvrđeno'),
(3, 3, '2024-12-15 15:38:43', 'Potvrđeno');

-- --------------------------------------------------------

--
-- Table structure for table `notifikacija`
--

DROP TABLE IF EXISTS `notifikacija`;
CREATE TABLE IF NOT EXISTS `notifikacija` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Poruka` text NOT NULL,
  `Datum` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`ID`)
)

DROP TABLE IF EXISTS `proizvod`;
CREATE TABLE IF NOT EXISTS `proizvod` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Naziv` varchar(100) NOT NULL,
  `Cijena` decimal(10,2) NOT NULL,
  `Zaliha` int(11) NOT NULL,
  `Popust` int(11) DEFAULT 0,
  PRIMARY KEY (`ID`)
)

INSERT INTO `proizvod` (`ID`, `Naziv`, `Cijena`, `Zaliha`, `Popust`) VALUES
(1, 'Sat Festina', 220.00, 5, 0),
(2, 'Ogrlica Oxette', 88.00, 9, 10),
(3, 'Nausnice Majorica', 350.00, 7, 5),
(4, 'Prsten', 255.00, 20, 0),
(5, 'Sat Seiko', 500.00, 3, 15),
(6, 'Sat Tissot PRX', 900.00, 5, 0),
(7, 'Lancic srebro', 40.00, 19, 5),
(8, 'Lancic zlato', 400.00, 10, 0),
(9, 'Pirsing srebro', 20.00, 8, 0);

DROP TRIGGER IF EXISTS `log_izmjena`;
DELIMITER $$
CREATE TRIGGER `log_izmjena` AFTER UPDATE ON `proizvod` FOR EACH ROW BEGIN
    INSERT INTO LOG (Stara_zaliha, Nova_zaliha, Datum_izmjene)
    VALUES (OLD.Zaliha, NEW.Zaliha, NOW());
END
$$
DELIMITER ;

DROP TABLE IF EXISTS `stavke_narudzbe`;
CREATE TABLE IF NOT EXISTS `stavke_narudzbe` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NarudzbaID` int(11) NOT NULL,
  `ProizvodID` int(11) NOT NULL,
  `Kolicina` int(11) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `NarudzbaID` (`NarudzbaID`),
  KEY `ProizvodID` (`ProizvodID`)
)

INSERT INTO `stavke_narudzbe` (`ID`, `NarudzbaID`, `ProizvodID`, `Kolicina`) VALUES
(1, 1, 2, 1),
(2, 2, 7, 1),
(3, 3, 9, 2);

DROP TRIGGER IF EXISTS `azuriraj_status_narudzbe`;
DELIMITER $$
CREATE TRIGGER `azuriraj_status_narudzbe` AFTER INSERT ON `stavke_narudzbe` FOR EACH ROW BEGIN
    UPDATE NARUDZBA
    SET Status = 'Potvrđeno'
    WHERE ID = NEW.NarudzbaID AND Status = 'Na čekanju';
END
$$
DELIMITER ;

ALTER TABLE `arhiva`
  ADD CONSTRAINT `arhiva_ibfk_1` FOREIGN KEY (`KorisnikID`) REFERENCES `korisnik` (`ID`);

ALTER TABLE `narudzba`
  ADD CONSTRAINT `narudzba_ibfk_1` FOREIGN KEY (`KorisnikID`) REFERENCES `korisnik` (`ID`);

ALTER TABLE `stavke_narudzbe`
  ADD CONSTRAINT `stavke_narudzbe_ibfk_1` FOREIGN KEY (`NarudzbaID`) REFERENCES `narudzba` (`ID`),
  ADD CONSTRAINT `stavke_narudzbe_ibfk_2` FOREIGN KEY (`ProizvodID`) REFERENCES `proizvod` (`ID`);

DELIMITER $$

DROP EVENT IF EXISTS `automatski_popust`$$
CREATE DEFINER=`root`@`localhost` EVENT `automatski_popust` ON SCHEDULE EVERY 1 DAY STARTS '2024-12-15 14:44:52' ON COMPLETION NOT PRESERVE ENABLE DO CALL postavi_na_akciju(20, 50, 2)$$

DROP EVENT IF EXISTS `provjeri_zalihe`$$
CREATE DEFINER=`root`@`localhost` EVENT `provjeri_zalihe` ON SCHEDULE EVERY 1 DAY STARTS '2024-12-15 14:45:23' ON COMPLETION NOT PRESERVE ENABLE DO INSERT INTO NOTIFIKACIJA (Poruka, Datum)
    SELECT 'Niske zalihe za određene proizvode', NOW()
    WHERE EXISTS (
        SELECT 1 FROM PROIZVOD WHERE Zaliha < 10
    )$$

DROP EVENT IF EXISTS `arhiviranje_narudzbi`$$
CREATE DEFINER=`root`@`localhost` EVENT `arhiviranje_narudzbi` ON SCHEDULE EVERY 1 MONTH STARTS '2024-12-15 14:45:48' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    INSERT INTO ARHIVA (ID, KorisnikID, DatumKreiranja, Status)
    SELECT ID, KorisnikID, DatumKreiranja, Status FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365;

    DELETE FROM STAVKE_NARUDZBE WHERE NarudzbaID IN (
        SELECT ID FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365
    );

    DELETE FROM NARUDZBA WHERE DATEDIFF(NOW(), DatumKreiranja) > 365;

END$$

DELIMITER ;
COMMIT;


