#
#  #########################################################################
#  #     
#  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  #
#  # Copyright 2025 Rinke IT-Service All Rights Reserved.
#  # This file may not be redistributed in whole or significant part.
#  # Content of this file is Protected By International Copyright Laws.
#  #
#  # https://www.rinke-it.de
#  #
#  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  #
#  # @copyright Rinke IT-Service, www.rinke-it.de
#  #
#  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  #
#  # Rinke IT-Service, Noerenbergskamp 8a, 44894 Bochum
#  #
#  # support@rinke-it.de
#  #
#  #########################################################################
#

$API_Endpoint_Url = ''
$API_Endpoint_Port = 5001

$API_Username = ''
$API_Password = ''

$limit = 500
$filename = "d:\temp\stocks.csv"

$stock = [System.Collections.Generic.List[System.Object]]::new()

$login_params = @{
    'username'=$API_Username
    'password'=$API_Password
    'grant_type'="password"
}

# Login
$login_request = Invoke-WebRequest -Uri $API_Endpoint_Url':'$API_Endpoint_Port'/token' -Method POST -Body ($login_params|ConvertTo-Json) -ContentType "application/json" | ConvertFrom-Json

if([string]::IsNullOrEmpty($login_request.access_token)) {
    Write-Host "no access token"
    Exit
}

# Get stocks
$request_header = @{
    'Authorization'='Bearer '+$login_request.access_token
}

$stock_request = Invoke-WebRequest -Uri $API_Endpoint_Url':'$API_Endpoint_Port'/api/v2/stock?max_result='$limit -Method GET -Headers $request_header -ContentType "application/json" | ConvertFrom-Json
$pagination_token = $stock_request.next_token
$stock.AddRange($stock_request.data)

While(-not [string]::IsNullOrEmpty($pagination_token)) {
    $stock_request = Invoke-WebRequest -Uri $API_Endpoint_Url':'$API_Endpoint_Port'/api/v2/stock?pagination_token='$pagination_token'&max_result='$limit -Method GET -Headers $request_header -ContentType "application/json" | ConvertFrom-Json    
    $stock.AddRange($stock_request.data)
    $pagination_token = $stock_request.next_token
}

$stock| Export-Csv -Path $filename -NoTypeInformation

Write-Host "...Done"
