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
from pathlib import Path

limit = 500

data = []

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

Path(config.exportfolder).mkdir(parents=True, exist_ok=True)

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

    request = json.loads(requests.get(config.API_Endpoint_Url + ':' + str(config.API_Endpoint_Port) + '/api/v2/stock?pagination_token='+pagination_token+'&max_result=' +str(limit), headers = request_header, verify = config.API_Verify_SSL).text)    
    data.extend(request["data"])

    if(not "next_token" in request) :
        break

    pagination_token = request["next_token"]

print("processing " + str(len(data)) + " articles")

data = pandas.DataFrame(data)
data.to_csv(config.exportfolder + config.stocks_filename, header=True, index=False, sep=config.csv_seperator)

print("...Done")
