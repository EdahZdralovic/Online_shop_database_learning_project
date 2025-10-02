<?php
session_start();

// Uništavanje svih sesija
session_unset();
session_destroy();

// Preusmjeravanje na stranicu za prijavu
header('Location: index.php');
exit();
?>
