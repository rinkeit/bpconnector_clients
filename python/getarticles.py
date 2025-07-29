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

import config
import requests
import json
import pandas 
import urllib3
import os
import progressbar
from pathlib import Path

limit = 500

data = []
export = []

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

Path(config.exportfolder).mkdir(parents=True, exist_ok=True)
Path(config.exportfolder + config.imagefolder).mkdir(parents=True, exist_ok=True)

# login
login_params = {
    'username': config.API_Username,
    'password': config.API_Password,
    'grant_type': "password"
}

login_request = json.loads(requests.post(config.API_Endpoint_Url + ':' + str(config.API_Endpoint_Port) + '/token', json = login_params, verify = config.API_Verify_SSL).text)

if(login_request["access_token"] == "") :
    print("no access token")
    exit()

print("login successful")

# Get stocks
request_header = {
    'Authorization': 'Bearer ' + login_request["access_token"]
}

pagination_token = ""
chunk = 0

while(True) :
    chunk += 1
    print("retrieve data (chunk " + str(chunk) + ", chunksize " + str(limit) +")")    
    request = json.loads(requests.get(config.API_Endpoint_Url + ':' + str(config.API_Endpoint_Port) + '/api/v2/article?pagination_token='+pagination_token+'&max_result=' +str(limit), headers = request_header, verify = config.API_Verify_SSL).text)    
    data.extend(request["data"])

    if(not "next_token" in request) :
        break       
  
    pagination_token = request["next_token"]

print("processing " + str(len(data)) + " articles")

p = progressbar.ProgressBar(maxval = len(data))
p.start()

counter = 1

for d in data :    
    p.update(counter)
    counter += 1    

    a = {
        'sku': d["sku"],
        'ean': d["ean"],      
        'short_description': d["short_description"],
        'description': d["description"],
        'upe': d["upe"],
        'gew': d["gew"],
        'short_description_de_DE': "".
        'description_de_DE': "",
        'short_description_fr_FR': "",
        'description_fr_FR': "",
        'short_description_en_EN': "",
        'description_en_EN': ""
    }    

    images = []
    for i in d["images"] :
         
        imagefilename = os.path.basename(i["webshop_url"])
        images.append(imagefilename)   

        if(config.articles_download_images) :
            imageresponse  = requests.get(i["webshop_url"])
        
            with open(config.exportfolder + config.imagefolder + "/" + imagefilename, mode="wb") as file:
                file.write(imageresponse.content)      

    a['images'] = ','.join(images)

    for t in d["translations"] :
        langid =  t["language_id"]

        a['short_description_' + langid] = t["short_description"]
        a['description_' + langid] = t["description"]

    export.append(a)
    
p.finish

export = pandas.DataFrame(export)
export.to_csv(config.exportfolder + config.articles_filename, header=True, index=False, sep=config.csv_seperator)

print("\n...Done")
