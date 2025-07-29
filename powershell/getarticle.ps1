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
$articles = @() 

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { -Not $API_Verify_SSL }

New-Item -ItemType Directory -Force -Path $exportfolder | Out-Null
New-Item -ItemType Directory -Force -Path $exportfolder$imagefolder | Out-Null

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
    $request = Invoke-WebRequest -Uri $API_Endpoint_Url':'$API_Endpoint_Port'/api/v2/article?pagination_token='$pagination_token'&max_result='$limit -Method GET -Headers $request_header -ContentType "application/json" 
    $encoded = [System.Text.Encoding]::UTF8.GetString($request.RawContentStream.ToArray()) | ConvertFrom-Json     
        
    $data.AddRange($encoded.data)   
   
    $pagination_token = $encoded.next_token

    if([string]::IsNullOrEmpty($pagination_token)) {
        break
    }
}

$Count = $data.Count
Write-Host "processing $Count articles"

$Counter = 0
$wc = New-Object System.Net.WebClient

foreach($d in $data) {    
    Write-Progress -PercentComplete ($Counter/100*100) -Status "Processing Items" -Activity "Item $item of $Count"
    $counter++
       
    $a = @{
       sku = $d.sku; 
       ean = $d.ean; 
       short_description = $d.short_description; 
       description = $d.description; 
       upe = $d.upe; 
       gew = $d.gew;
       short_description_de_DE = "";
       description_de_DE = "";
       short_description_fr_FR = "";
       description_fr_FR = "";
       short_description_en_EN = "";
       description_en_EN = "";
    }
    
    $images = @()

    foreach($i in $d.images) {        
        $imagefilename = Split-Path $i.webshop_url -leaf        
        $images += $imagefilename       
      
        if($articles_download_images) {
            $imagePath = Join-Path -Path (Join-Path $exportfolder $imagefolder) -ChildPath $imagefilename   
            
            if(-Not [System.IO.File]::Exists($imagePath) -Or $articles_overwrite_images) {
                try {
                    $wc.DownloadFile($i.webshop_url, $imagePath)
                } catch [System.Net.WebException],[System.IO.IOException] {
                    "couldn't download image " + $i.webshop_url
                } catch {
                    "An error occurred that could not be resolved."
                }
            }
        }
    }

    $a.images = $images -join ','
    
    foreach ($t in $d.translations) {       
        $lang_id = $t.language_id
        $a["short_description_$lang_id"] = $t.short_description
        $a["description_$lang_id"] = $t.description       
    }       

    $articles += [PSCustomObject]$a
}

$articles| Export-Csv -Path (Join-Path $exportfolder $articles_filename) -NoTypeInformation -Delimiter $csv_seperator -Encoding UTF8

Write-Host "...Done"
