<?php
session_start();
require 'baza/connection.php';

// Provjera da li je korisnik prijavljen
if (!isset($_SESSION['user_id'])) {
    header('Location: index.php');
    exit();
}

$user_id = $_SESSION['user_id'];

// Dohvati sve proizvode iz baze
$stmt = $pdo->query("SELECT * FROM PROIZVOD WHERE Zaliha > 0");
$proizvodi = $stmt->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $proizvod_id = $_POST['proizvod_id'];
    $kolicina = intval($_POST['kolicina']);

    // Validacija
    if ($kolicina <= 0) {
        $error = "Količina mora biti veća od 0.";
    } else {
        try {
            // Kreiranje nove narudžbe
            $pdo->beginTransaction();

            $stmt = $pdo->prepare("INSERT INTO NARUDZBA (KorisnikID) VALUES (?)");
            $stmt->execute([$user_id]);
            $narudzba_id = $pdo->lastInsertId();

            // Dodavanje stavke u narudžbu
            $stmt = $pdo->prepare("INSERT INTO STAVKE_NARUDZBE (NarudzbaID, ProizvodID, Kolicina) VALUES (?, ?, ?)");
            $stmt->execute([$narudzba_id, $proizvod_id, $kolicina]);

            // Smanji zalihe proizvoda
            $stmt = $pdo->prepare("UPDATE PROIZVOD SET Zaliha = Zaliha - ? WHERE ID = ?");
            $stmt->execute([$kolicina, $proizvod_id]);

            $pdo->commit();
            $success = "Narudžba je uspješno kreirana!";
        } catch (Exception $e) {
            $pdo->rollBack();
            $error = "Greška: " . $e->getMessage();
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Nova Narudžba</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="centar">
    <h2>Nova Narudžba</h2>

    <?php if (isset($success)) echo "<p style='color:green;'>$success</p>"; ?>
    <?php if (isset($error)) echo "<p style='color:red;'>$error</p>"; ?>

    <form method="POST" action="">
        <label for="proizvod">Odaberite proizvod:</label>
        <select name="proizvod_id" required>
            <?php foreach ($proizvodi as $proizvod): ?>
                <option value="<?= $proizvod['ID'] ?>">
                    <?= htmlspecialchars($proizvod['Naziv']) ?> - <?= $proizvod['Cijena'] ?> KM (Zaliha: <?= $proizvod['Zaliha'] ?>)
                </option>
            <?php endforeach; ?>
        </select>
        <br><br>
        <label for="kolicina">Količina:</label>
        <input type="number" name="kolicina" min="1" required>
        <br><br>
        <button type="submit">Naruči</button>
    </form>
    </div>

    <a href="pregled_narudzbi.php">Pogledajte vaše narudžbe</a> |
    <a href="logout.php">Odjavite se</a>
    <div class="foter_moj">Predmet: Baze Podataka. <br>  Zadaća broj 4.  <br>  Profesor: Adis Alihodzić <br> Student:Edah Ždralović </div>
    </div>
</body>
</html>