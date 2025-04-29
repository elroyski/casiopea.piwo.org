<?php
header('Content-Type: application/json');

$filename = __DIR__ . '/services.json';
if (!file_exists($filename)) {
    echo json_encode([]);
    exit;
}

$services = json_decode(file_get_contents($filename), true);

function isOnline($host, $port, $timeout = 2) {
    $fp = @fsockopen($host, $port, $errno, $errstr, $timeout);
    if ($fp) {
        fclose($fp);
        return true;
    }
    return false;
}

$result = [];

foreach ($services as $service) {
    $host = $service['host'];
    $port = $service['port'];
    $path = isset($service['path']) ? $service['path'] : '/';
    $https = isset($service['https']) && $service['https'] === true;
    $protocol = $https ? 'https' : 'http';
    $url = "$protocol://$host:$port$path";

    $online = isOnline($host, $port);

    $result[] = [
        'id' => $service['id'],
        'name' => $service['name'],
        'url' => $url,
        'online' => $online
    ];
}

echo json_encode($result);
