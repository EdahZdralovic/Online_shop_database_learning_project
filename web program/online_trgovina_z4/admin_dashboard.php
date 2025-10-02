<?php
session_start();
require 'baza/connection.php';

if ($_SESSION['role'] !== 'admin') {
    header('Location: index.php');
    exit();
}

// Dodavanje proizvoda
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_product'])) {
    $naziv = $_POST['naziv'];
    $cijena = $_POST['cijena'];
    $zaliha = $_POST['zaliha'];

    $stmt = $pdo->prepare("INSERT INTO PROIZVOD (Naziv, Cijena, Zaliha) VALUES (?, ?, ?)");
    $stmt->execute([$naziv, $cijena, $zaliha]);
    header('Location: admin_dashboard.php');
    exit();
}

// Brisanje proizvoda
if (isset($_GET['delete_id'])) {
    $stmt = $pdo->prepare("DELETE FROM PROIZVOD WHERE ID = ?");
    $stmt->execute([$_GET['delete_id']]);
    header('Location: admin_dashboard.php');
    exit();
}

// Dohvaćanje proizvoda
$proizvodi = $pdo->query("SELECT * FROM PROIZVOD")->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    
    <title>Admin Panel</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h2>Upravljanje proizvodima</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Naziv</th>
            <th>Cijena</th>
            <th>Zaliha</th>
            <th>Popust</th>
            <th>Akcije</th>
        </tr>
        <?php foreach ($proizvodi as $proizvod): ?>
        <tr>
            <td><?= $proizvod['ID'] ?></td>
            <td><?= $proizvod['Naziv'] ?></td>
            <td><?= $proizvod['Cijena'] ?> KM</td>
            <td><?= $proizvod['Zaliha'] ?></td>
            <td><?= $proizvod['Popust'] ?>%</td>
            <td>
                <a href="?delete_id=<?= $proizvod['ID'] ?>">Obriši</a>
            </td>
        </tr>
        <?php endforeach; ?>
    </table>

    <h3>Dodaj novi proizvod</h3>
    <form method="POST" action="">
        <input type="text" name="naziv" placeholder="Naziv" required>
        <input type="number" name="cijena" placeholder="Cijena" step="0.01" required>
        <input type="number" name="zaliha" placeholder="Zaliha" required>
        <button type="submit" name="add_product">Dodaj</button>
    </form>

    <a href="logout.php">Odjavite se</a>
    <div class="foter_moj">Predmet: Baze Podataka. <br>  Zadaća broj 4.  <br>  Profesor: Adis Alihodzić <br> Student:Edah Ždralović </div>
    </div>
</body>
</html>
