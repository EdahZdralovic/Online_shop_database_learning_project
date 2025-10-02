<?php
require 'baza/connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $ime = $_POST['ime'];
    $email = $_POST['email'];
    $lozinka = password_hash($_POST['lozinka'], PASSWORD_BCRYPT);

    // Provera da li email već postoji
    $stmt = $pdo->prepare("SELECT * FROM KORISNIK WHERE Email = ?");
    $stmt->execute([$email]);

    if ($stmt->rowCount() > 0) {
        $error = "Email adresa je već registrovana!";
    } else {
        // Upisivanje korisnika u bazu
        $insert = $pdo->prepare("INSERT INTO KORISNIK (Ime, Email, Lozinka) VALUES (?, ?, ?)");
        $insert->execute([$ime, $email, $lozinka]);
        header('Location: index.php');
        exit();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registracija korisnika</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h2>Registracija korisnika</h2>

    <?php if (isset($error)) echo "<p style='color:red;'>$error</p>"; ?>

    <form method="POST" action="">
        <label>Ime: </label>
        <input type="text" name="ime" required><br><br>

        <label>Email: </label>
        <input type="email" name="email" required><br><br>

        <label>Lozinka: </label>
        <input type="password" name="lozinka" required><br><br>

        <button type="submit">Registrujte se</button>
    </form>

    <p>Već imate nalog? <a href="index.php">Prijavite se ovdje</a></p>
    <div class="foter_moj">Predmet: Baze Podataka. <br>  Zadaća broj 4.  <br>  Profesor: Adis Alihodzić <br> Student:Edah Ždralović </div>
    </div>
</body>
</html>
