
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

const https = require('https');

let API_Endpoint_Url = ''
let API_Endpoint_Port = 5001

let API_Username = ''
let API_Password = ''

let limit = 500
let filename = "d:\\temp\\stocks.csv"

let stock = [];

const GetAuth = (() => {
    return new Promise((resolve, reject) => {
        const login_params = JSON.stringify({
            'username': API_Username,
            'password': API_Password,
            'grant_type': "password"
        });

        const login_options = {
            hostname: API_Endpoint_Url,
            port: API_Endpoint_Port,
            path: "/token",    
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length' : Buffer.byteLength(login_params, 'utf8')    
            },
            body: login_params
        };
  
        const req = https.request(login_options, (res) => {    
            let responseData = '';
            res.on('data', (chunk) => { responseData += chunk; });    
            res.on('end', () => {                
                if (res.statusCode >= 200 && res.statusCode <= 299) {                     
                    resolve(JSON.parse(responseData)["access_token"]);
                } else {
                    reject("no login");
                }
            });
        });
        req.on('error', (error) => {
            console.error('Error:', error.message);
        });
        req.write(login_params);
        req.end();
    });    
});

const GetStock =((access_token, limit, pagination_token) => {
    return new Promise((resolve, reject) => {
        const login_options = {
            hostname: API_Endpoint_Url,
            port: API_Endpoint_Port,
            path: '/api/v2/stock?max_result=' + limit + "&pagination_token=" + pagination_token,    
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + access_token,
                'Content-Type': 'application/json',                
            }
        };
  
        const req = https.request(login_options, (res) => {    
            let responseData = '';
            res.on('data', (chunk) => { responseData += chunk; });    
            res.on('end', () => {                             
                if (res.statusCode >= 200 && res.statusCode <= 299) {    
                    data = JSON.parse(responseData);
                    pagination_token = data.next_token; 
                    stock_data = data.data;    
                    resolve({pagination_token, stock_data});
                } else {
                    reject();
                }
            });
        });
        req.on('error', (error) => {
            console.error('Error:', error.message);
        });
        req.end();
    });    
});

(async function(){
    let access_token = await GetAuth();
  
    let pagination_token = "";

    while(true) {        
        const stock_request = await GetStock(access_token, limit, pagination_token);
        pagination_token = stock_request.pagination_token; 
        stock = stock.concat(stock_request.stock_data);

        if(pagination_token == undefined)
            break;
    }

    const createCsvWriter = require('csv-writer').createObjectCsvWriter; // npm i csv-writer / https://www.npmjs.com/package/csv-writer
    const csvWriter = createCsvWriter({
        path: filename,
        header: [
            {id: 'sku', title: 'sku'},
            {id: 'ean', title: 'ean'},
            {id: 'stock', title: 'stock'},
            {id: 'price', title: 'price'},
            {id: 'upe', title: 'upe'},
            {id: 'restock_date', title: 'restock_data'}
        ]
    });

    csvWriter.writeRecords(stock)    
    .then(() => {
        console.log('...Done');
    });

})();

