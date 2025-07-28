
'
'  #########################################################################
'  #     
'  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'  #
'  # Copyright 2025 Rinke IT-Service All Rights Reserved.
'  # This file may Not be redistributed in whole Or significant part.
'  # Content of this file Is Protected By International Copyright Laws.
'  #
'  # https://www.rinke-it.de
'  #
'  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'  #
'  # @copyright Rinke IT-Service, www.rinke-it.de
'  #
'  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'  #
'  # Rinke IT-Service, Noerenbergskamp 8a, 44894 Bochum
'  #
'  # support@rinke-it.de
'  #
'  #########################################################################
'

Imports System.ComponentModel
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Text.Json
Imports Microsoft.AspNetCore.WebUtilities

Module Program
    Dim API_Endpoint_Url As String = ""
    Dim API_Endpoint_Port As Integer = 5001

    Dim API_Username As String = ""
    Dim API_Password As String = ""

    Dim limit As Integer = 500
    Dim filename As String = "d:\temp\stock.csv"

    Dim Stock As New List(Of ArtikelStock)

    Public Sub Main()
        Dim loginParams As New Dictionary(Of String, String) From {
            {"username", API_Username},
            {"password", API_Password},
            {"grant_type", "password"}
        }

        Dim options As New JsonSerializerOptions With {.WriteIndented = True}
        Dim requestJson As String = JsonSerializer.Serialize(loginParams, options)

        Dim client As New HttpClient()

        client.DefaultRequestHeaders.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))

        Dim loginRequest = client.PostAsync($"{API_Endpoint_Url}:{API_Endpoint_Port}/token", New StringContent(requestJson, Encoding.UTF8, "application/json")).Result
        Dim loginResponse = loginRequest.Content.ReadAsStringAsync().Result
        Dim loginResponseData = JsonSerializer.Deserialize(Of Dictionary(Of String, Object))(loginResponse)

        If Not loginResponseData.ContainsKey("access_token") OrElse String.IsNullOrEmpty(loginResponseData("access_token").ToString()) Then
            Console.WriteLine("no access token")
            Return
        End If

        client.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Bearer", loginResponseData("access_token").ToString())

        Try
            Dim paginationToken = ""

            While True
                Dim Params As New Dictionary(Of String, String) From {
                    {"max_result", limit.ToString()},
                    {"pagination_token", paginationToken}
                }

                Dim StockRequest = client.GetAsync(QueryHelpers.AddQueryString($"{API_Endpoint_Url}:{API_Endpoint_Port}/api/v2/stock", Params)).Result
                Dim StockResponse = StockRequest.Content.ReadAsStringAsync().Result
                Dim StockData = JsonSerializer.Deserialize(Of ResultStocks)(StockResponse)
                paginationToken = StockData.next_token
                Stock.AddRange(StockData.data)

                If String.IsNullOrEmpty(paginationToken) Then
                    Exit While
                End If
            End While

        Catch ex As Exception
            Console.WriteLine(ex.ToString())
        End Try
                
        SaveToCsv(Stock, filename)
        Console.WriteLine("...Done")
    End Sub

    Sub SaveToCsv(Of T)(data As List(Of T), path As String)
        Dim lines As New List(Of String)
        Dim props = TypeDescriptor.GetProperties(GetType(T)).OfType(Of PropertyDescriptor)()
        Dim header = String.Join(",", props.Select(Function(p) p.Name))
        lines.Add(header)

        Dim valueLines = data.Select(Function(row) String.Join(",", header.Split(","c).Select(Function(a) row.GetType().GetProperty(a).GetValue(row, Nothing))))
        lines.AddRange(valueLines)
        IO.File.WriteAllLines(path, lines.ToArray())
    End Sub

    Public Class ResultStocks
        Public Property success As Boolean
        Public Property message As String
        Public Property data As List(Of ArtikelStock)
        Public Property previous_token As String
        Public Property next_token As String
    End Class

    Public Class ArtikelStock
        Public Property sku As String
        Public Property ean As String
        Public Property stock As Double
        Public Property price As Double
        Public Property upe As Double
        Public Property restock_date As DateTime?
    End Class
End Module
