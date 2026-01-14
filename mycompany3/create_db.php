<?php
// Read .env file
$env_file = __DIR__ . '/.env';
$env_vars = [];
if (file_exists($env_file)) {
    $lines = file($env_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        list($key, $value) = explode('=', $line, 2);
        $env_vars[trim($key)] = trim($value);
    }
}

$db_host = $env_vars['DB_HOST'] ?? '127.0.0.1';
$db_port = $env_vars['DB_PORT'] ?? '3306';
$db_name = $env_vars['DB_DATABASE'] ?? 'nabatat';
$db_user = $env_vars['DB_USERNAME'] ?? 'root';
$db_pass = $env_vars['DB_PASSWORD'] ?? '';

try {
    $dsn = 'mysql:host=' . $db_host . ';port=' . $db_port;
    $pdo = new PDO($dsn, $db_user, $db_pass);
    $pdo->exec('CREATE DATABASE IF NOT EXISTS `' . $db_name . '`');
    echo 'Database ' . $db_name . ' created or already exists.' . PHP_EOL;
} catch (PDOException $e) {
    echo 'Error: ' . $e->getMessage() . PHP_EOL;
    exit(1);
}
