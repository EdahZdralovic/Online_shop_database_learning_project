<?php
session_start();
require 'baza/connection.php';

// Provjera da li je korisnik prijavljen
if (!isset($_SESSION['user_id'])) {
    header('Location: index.php');
    exit();
}

$user_id = $_SESSION['user_id'];

// Dohvati sve narudžbe i stavke za prijavljenog korisnika
$stmt = $pdo->prepare("
    SELECT N.ID AS NarudzbaID, N.DatumKreiranja, P.Naziv AS Proizvod, SN.Kolicina, 
           P.Cijena, P.Popust, (P.Cijena * SN.Kolicina * (1 - P.Popust / 100)) AS UkupnaCijena
    FROM NARUDZBA N
    JOIN STAVKE_NARUDZBE SN ON N.ID = SN.NarudzbaID
    JOIN PROIZVOD P ON SN.ProizvodID = P.ID
    WHERE N.KorisnikID = ?
    ORDER BY N.DatumKreiranja DESC
");
$stmt->execute([$user_id]);
$narudzbe = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Pregled Narudžbi</title>
</head>
<body>
    <h2>Vaše Narudžbe</h2>

    <?php if (empty($narudzbe)): ?>
        <p>Nema narudžbi za prikazivanje.</p>
    <?php else: ?>
        <table border="1" cellpadding="5" cellspacing="0">
            <tr>
                <th>ID Narudžbe</th>
                <th>Datum</th>
                <th>Proizvod</th>
                <th>Količina</th>
                <th>Cijena</th>
                <th>Popust</th>
                <th>Ukupna Cijena</th>
            </tr>
            <?php foreach ($narudzbe as $narudzba): ?>
                <tr>
                    <td><?= $narudzba['NarudzbaID'] ?></td>
                    <td><?= $narudzba['DatumKreiranja'] ?></td>
                    <td><?= htmlspecialchars($narudzba['Proizvod']) ?></td>
                    <td><?= $narudzba['Kolicina'] ?></td>
                    <td><?= $narudzba['Cijena'] ?> KM</td>
                    <td><?= $narudzba['Popust'] ?>%</td>
                    <td><?= number_format($narudzba['UkupnaCijena'], 2) ?> KM</td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

    <a href="nova_narudzba.php">Napravi novu narudžbu</a> |
    <a href="logout.php">Odjavite se</a>
</body>
</html>
