<?php
session_start();
require 'baza/connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'];
    $password = $_POST['password'];

    // Dohvati korisnika iz baze
    $stmt = $pdo->prepare("SELECT * FROM KORISNIK WHERE Email = ? LIMIT 1");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // Provjera korisnika i lozinke BEZ šifrovanja
    if ($user && $password === $user['Lozinka']) {
        $_SESSION['user_id'] = $user['ID'];
        $_SESSION['role'] = ($email === 'admin@pmf.unsa.ba') ? 'admin' : 'user';

        // Preusmjeravanje na odgovarajući dashboard
        header('Location: ' . ($_SESSION['role'] === 'admin' ? 'admin_dashboard.php' : 'user_dashboard.php'));
        exit();
    } else {
        $error = "Neispravni podaci za prijavu.";
    }
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    
    <title>Prijava korisnika</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="centar">
    <h2 class = "naslov">Prijava korisnika</h2>
    <?php if (isset($error)) echo "<p>$error</p>"; ?>
    <form method="POST" action="">
        <label>Email: </label>
        <input type="email" name="email" required>
        <label>Lozinka: </label>
        <input type="password" name="password" required>
        <button class ="dugme"type="submit">Prijavite se</button>
    </form>
    <p>Niste registrovani? <a href="registruj.php">Registruj se ovdje</a></p>
    <div class="foter_moj">Predmet: Baze Podataka. <br>  Zadaća broj 4.  <br>  Profesor: Adis Alihodzić <br> Student:Edah Ždralović </div>
    </div>
</body>
</html>
