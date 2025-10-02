<?php
$host = 'localhost';       // Host servera
$db = 'online_trgovina';   // Ime vaše baze
$user = 'root';            // Podrazumijevani MySQL korisnik
$pass = '';                // Prazno ako nemate šifru za root

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Uspješna konekcija sa bazom!";
} catch (PDOException $e) {
    die("Greška pri konekciji: " . $e->getMessage());
}
?>