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

. "$PSScriptRoot\config.ps1"

$limit = 500

$data = [System.Collections.Generic.List[System.Object]]::new()

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { -Not $API_Verify_SSL }

New-Item -ItemType Directory -Force -Path $exportfolder

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

Write-Host "login successful"

# Get stocks
$request_header = @{
    'Authorization'='Bearer '+$login_request.access_token
}

$pagination_token = ""
$chunk = 0

While($true) {
    $chunk += 1
    Write-Host "retrieve data (chunk $chunk, chunksize $limit)"

    $request = Invoke-WebRequest -Uri $API_Endpoint_Url':'$API_Endpoint_Port'/api/v2/stock?pagination_token='$pagination_token'&max_result='$limit -Method GET -Headers $request_header -ContentType "application/json" | ConvertFrom-Json    
    $data.AddRange($request.data)    
    $pagination_token = $request.next_token
    
    if([string]::IsNullOrEmpty($pagination_token)) {
        break
    }
}

$Count = $data.Count
Write-Host "processing $Count articles"

$data| Export-Csv -Path (Join-Path $exportfolder $stocks_filename) -NoTypeInformation

Write-Host "...Done"
