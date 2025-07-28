<?php
/*
*  #########################################################################
*  #     
*  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  #
*  # Copyright 2025 Rinke IT-Service All Rights Reserved.
*  # This file may not be redistributed in whole or significant part.
*  # Content of this file is Protected By International Copyright Laws.
*  #
*  # https://www.rinke-it.de
*  #
*  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  #
*  # @copyright Rinke IT-Service, www.rinke-it.de
*  #
*  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  #
*  # Rinke IT-Service, Noerenbergskamp 8a, 44894 Bochum
*  #
*  # support@rinke-it.de
*  #
*  #########################################################################
*/

$API_Endpoint_Url = '';
$API_Endpoint_Port = 5001;

$API_Username = '';
$API_Password = '';

$limit = 500;
$filename = 'd:/temp/stocks.csv';

$stock = [];

// Login
$login_params = [
    'username' => $API_Username,
    'password' => $API_Password,
    'grant_type' => 'password',
];

$login_response = http_post_json("{$API_Endpoint_Url}:{$API_Endpoint_Port}/token", $login_params);
$access_token = $login_response['access_token'] ?? '';

if (empty($access_token)) {
    echo "no access token\n";
    exit;
}

// Get stocks
$request_header = [
    'Authorization: Bearer ' . $access_token
];

$pagination_token = ""; 

while (true) {
    $url = "{$API_Endpoint_Url}:{$API_Endpoint_Port}/api/v2/stock?pagination_token={$pagination_token}&max_result={$limit}";
    $stock_response = http_get_json($url, $request_header);
    $stock = array_merge($stock, $stock_response['data']);

    if (!isset($stock_response['next_token'])) {
        break;
    }

    $pagination_token = $stock_response['next_token'];
}

// Save to CSV
$fp = fopen($filename, 'w');
if (!empty($stock)) {
    fputcsv($fp, array_keys($stock[0])); // Header
    foreach ($stock as $row) {
        fputcsv($fp, $row);
    }
}
fclose($fp);

echo "...Done\n";


// Helper functions
function http_post_json($url, $data) {
    $ch = curl_init($url);
    $payload = json_encode($data);
    curl_setopt_array($ch, [
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
        CURLOPT_VERBOSE => false,        
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => $payload
    ]);
    $response = curl_exec($ch);
    curl_close($ch);
    return json_decode($response, true);
}

function http_get_json($url, $headers = []) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
        CURLOPT_VERBOSE => false,     
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers
    ]);
    $response = curl_exec($ch);
    curl_close($ch);
    return json_decode($response, true);
}
