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

import requests
import json
import pandas 

API_Endpoint_Url = ''
API_Endpoint_Port = 5001

API_Username = ''
API_Password = ''

limit = 500
filename = "d:/temp/stocks.csv"

stock = []

# login
login_params = {
    'username': API_Username,
    'password': API_Password,
    'grant_type': "password"
}

login_request = json.loads(requests.post(API_Endpoint_Url + ':' + str(API_Endpoint_Port) + '/token', json = login_params).text)

if(login_request["access_token"] == "") :
    print("no access token")
    exit()

# Get stocks
request_header = {
    'Authorization': 'Bearer ' + login_request["access_token"]
}

pagination_token = ""

while(True) :
    stock_request = json.loads(requests.get(API_Endpoint_Url + ':' + str(API_Endpoint_Port) + '/api/v2/stock?pagination_token='+pagination_token+'&max_result=' +str(limit), headers = request_header).text)    
    stock.extend(stock_request["data"])
    
    if(not "next_token" in stock_request) :
        break
        
    pagination_token = stock_request["next_token"]

data = pandas.DataFrame(stock)
data.to_csv(filename, header=True, index=False)

print("...Done")
