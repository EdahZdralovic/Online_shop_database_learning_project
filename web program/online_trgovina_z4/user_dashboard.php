<?php
session_start();
require 'baza/connection.php';

if ($_SESSION['role'] !== 'user') {
    header('Location: index.php');
    exit();
}

// Dohvaćanje proizvoda
$proizvodi = $pdo->query("SELECT * FROM PROIZVOD")->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <link rel="stylesheet" href="style.css">
    <title>Korisnički Panel</title>
</head>
<body>
    <div class="centar">
    <h2>Dobrodošli!</h2>
    <h3>Proizvodi</h3>
    <form method="POST" action="nova_narudzba.php">
        <label>Odaberite proizvod:</label>
        <select name="proizvod_id">
            <?php foreach ($proizvodi as $proizvod): ?>
                <option value="<?= $proizvod['ID'] ?>">
                    <?= $proizvod['Naziv'] ?> - <?= $proizvod['Cijena'] ?> KM
                </option>
            <?php endforeach; ?>
        </select>
        <input type="number" name="kolicina" placeholder="Količina" required>
        <button type="submit">Naruči</button>
    </form>
        
    <a href="pregled_narudzbi.php">Vaše narudžbe</a>
    <a href="logout.php">Odjavite se</a>
    </div>
    <div class="foter_moj">Predmet: Baze Podataka. <br>  Zadaća broj 4.  <br>  Profesor: Adis Alihodzić <br> Student:Edah Ždralović </div>
    </div>
</body>
</html>
