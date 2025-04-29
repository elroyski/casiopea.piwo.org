<?php
header('Content-Type: application/json');

$ip = $_GET['ip'] ?? null;
if (!$ip) {
    echo json_encode(['online' => false]);
    exit;
}

exec("ping -c 1 -W 1 " . escapeshellarg($ip), $output, $status);

echo json_encode([
    'online' => $status === 0
]);
