
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

using Microsoft.AspNetCore.WebUtilities;
using System.ComponentModel;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

string API_Endpoint_Url = "";
int API_Endpoint_Port = 5001;

string API_Username = "";
string API_Password = "";

int limit = 500;
string filename = @"d:\temp\stock.csv";

List<ArtikelStock> Stock = [];

Dictionary<string, string> login_params = new Dictionary<string, string>()
{
    { "username", API_Username },
    { "password", API_Password },
    { "grant_type", "password" }
};

var options = new JsonSerializerOptions { WriteIndented = true };
string Request = JsonSerializer.Serialize(login_params, options);

HttpClient client = new HttpClient();

client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

var LoginRequest = await client.PostAsync(API_Endpoint_Url + ':' + API_Endpoint_Port + "/token", new StringContent(Request, Encoding.UTF8, "application/json") );
string LoginResponse = await LoginRequest.Content.ReadAsStringAsync();
Dictionary<string, Object> LoginResponseData = (Dictionary<string, Object>)JsonSerializer.Deserialize(LoginResponse, typeof(Dictionary<string, object>));

if(string.IsNullOrEmpty(LoginResponseData["access_token"].ToString()))
{
    Console.WriteLine("no access token");
    return;
}

client.DefaultRequestHeaders.Add("Authorization", "Bearer " + LoginResponseData["access_token"].ToString());

try
{   
    var StockRequest = await client.GetAsync(QueryHelpers.AddQueryString(API_Endpoint_Url + ':' + API_Endpoint_Port + "/api/v2/stock", new Dictionary<string, string> { { "max_result", limit.ToString() } }));
    string StockResponse = await StockRequest.Content.ReadAsStringAsync();    
    ResultStocks StockResponseData = (ResultStocks)JsonSerializer.Deserialize(StockResponse, typeof(ResultStocks));
    string PaginationToken = StockResponseData.next_token;
    Stock.AddRange(StockResponseData.data);

    while(true)
    {        
        var NextStockRequest = await client.GetAsync(QueryHelpers.AddQueryString(API_Endpoint_Url + ':' + API_Endpoint_Port + "/api/v2/stock", new Dictionary<string, string> { { "max_result", limit.ToString() }, { "pagination_token", PaginationToken } }));
        string NextStockResponse = await NextStockRequest.Content.ReadAsStringAsync();
        ResultStocks NextStockResponseData = (ResultStocks)JsonSerializer.Deserialize(NextStockResponse, typeof(ResultStocks));
        PaginationToken = NextStockResponseData.next_token;
        Stock.AddRange(NextStockResponseData.data);

        if (string.IsNullOrEmpty(PaginationToken))
            break;
    }
    
} catch(Exception ex)
{
    Console.WriteLine(ex.ToString());
}

SaveToCsv(Stock, filename);

Console.WriteLine("...Done");

void SaveToCsv<T>(List<T> Data, string path)
{
    var lines = new List<string>();
    IEnumerable<PropertyDescriptor> props = TypeDescriptor.GetProperties(typeof(T)).OfType<PropertyDescriptor>();
    var header = string.Join(",", props.ToList().Select(x => x.Name));
    lines.Add(header);
    var valueLines = Data.Select(row => string.Join(",", header.Split(',').Select(a => row.GetType().GetProperty(a).GetValue(row, null))));
    lines.AddRange(valueLines);
    File.WriteAllLines(path, lines.ToArray());
}

public class ResultStocks()
{
    public Boolean success { get; set; }
    public string message {  get; set; }
    public List<ArtikelStock> data { get; set; }
    public string? previous_token { get; set; }
    public string? next_token { get; set; }
}
public class ArtikelStock
{
    public string sku { get; set; }
    public string ean { get; set; }
    public double stock { get; set; }
    public double price { get; set; }
    public double upe { get; set; }
    public DateTime? restock_date { get; set; }
}