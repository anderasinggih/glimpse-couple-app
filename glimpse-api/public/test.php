<?php
// Enable full error display for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h3>Glimpse Standalone Diagnostic Portal</h3>";

// 1. Check Laravel log file for recent errors
$logPath = __DIR__ . '/../storage/logs/laravel.log';
if (file_exists($logPath)) {
    echo "<h4>Latest Laravel Log Entries:</h4>";
    $lines = file($logPath);
    $lastLines = array_slice($lines, -150);
    echo "<pre style='background:#f4f4f4; padding:10px; border:1px solid #ccc; max-height: 400px; overflow: auto;'>" . htmlspecialchars(implode("", $lastLines)) . "</pre>";
} else {
    echo "<p>No Laravel log file found at $logPath</p>";
}

// 2. Check Database Connection
echo "<h4>Testing Database Connection:</h4>";
$envPath = __DIR__ . '/../.env';
if (file_exists($envPath)) {
    $env = file_get_contents($envPath);
    preg_match('/DB_CONNECTION=(.*)/', $env, $conn);
    preg_match('/DB_HOST=(.*)/', $env, $host);
    preg_match('/DB_DATABASE=(.*)/', $env, $db);
    preg_match('/DB_USERNAME=(.*)/', $env, $user);
    preg_match('/DB_PASSWORD=(.*)/', $env, $pass);
    
    $dbConn = isset($conn[1]) ? trim($conn[1]) : '';
    $dbHost = isset($host[1]) ? trim($host[1]) : '';
    $dbName = isset($db[1]) ? trim($db[1]) : '';
    $dbUser = isset($user[1]) ? trim($user[1]) : '';
    $dbPass = isset($pass[1]) ? trim($pass[1]) : '';
    
    echo "<p>Connection: $dbConn, Host: $dbHost, DB: $dbName, User: $dbUser</p>";
    
    if ($dbConn === 'mysql') {
        try {
            $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName", $dbUser, $dbPass);
            echo "<p style='color:green'>Connection Successful!</p>";
            
            echo "<h4>Database Content Dump:</h4>";
            
            // Fetch users
            echo "<h5>Users:</h5>";
            $stmt = $pdo->query("SELECT id, name, email, couple_id, invite_code FROM users");
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo "<pre>" . print_r($users, true) . "</pre>";
            
            // Fetch couples
            echo "<h5>Couples:</h5>";
            $stmt = $pdo->query("SELECT id, anniversary_start_date, is_active FROM couples");
            $couples = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo "<pre>" . print_r($couples, true) . "</pre>";
            
            // Fetch last 5 flashes
            echo "<h5>Last 5 Flashes:</h5>";
            $stmt = $pdo->query("SELECT id, couple_id, sender_id, photo_url, created_at FROM flashes ORDER BY id DESC LIMIT 5");
            $flashes = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo "<pre>" . print_r($flashes, true) . "</pre>";
            
            // Fetch last 5 messages
            echo "<h5>Last 5 Messages:</h5>";
            $stmt = $pdo->query("SELECT id, couple_id, sender_id, message, created_at FROM messages ORDER BY id DESC LIMIT 5");
            $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo "<pre>" . print_r($messages, true) . "</pre>";
            
        } catch (PDOException $e) {
            echo "<p style='color:red'>Connection Failed: " . htmlspecialchars($e->getMessage()) . "</p>";
        }
    }
} else {
    echo "<p>.env file not found</p>";
}
