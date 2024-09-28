<#

Feel free to modify this file by implementing your logic.

This script is invoked after initialization scripts completed running 
but before user has logged in.

This script runs under Administrator account but without any UI, 
meaning this script can't ask for user input. 

It's OK for this script to run a few minutes, as it runs before
users log in.

#>

Write-Host "OnAfterInit script started running at $(Get-Date)."

Set-Location "C:\Users\Administrator"
[string] $workDirectory = "C:\Users\Administrator\AWS-workshop-assets"

$sqlUsername = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).username
$sqlPassword = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).password
[string] $SQLDatabaseEndpoint = [System.Environment]::GetEnvironmentVariable("SQLDatabaseEndpoint")

[string] $SQLDatabaseEndpointTrimmed = $SQLDatabaseEndpoint.Replace(':1433','')
[string] $connectionString = "Server=$SQLDatabaseEndpointTrimmed;Database=BookStoreClassic;User Id=$sqlUsername;Password=$sqlPassword;"

[string] $webConfigFolder = "$workDirectory\bobs-used-bookstore-classic\app\Bookstore.Web\"
$webConfigPath = Join-Path $webConfigFolder "Web.config"

$webConfigXml = [xml](Get-Content -Path $webConfigPath)

$addElement = $webConfigXml.configuration.appSettings.add | Where-Object { $_.key -eq "ConnectionStrings/BookstoreDatabaseConnection" }
$addElement.value = $connectionString

$webConfigXml.Save($webConfigPath)

$xml.configuration.connectionStrings.add.connectionString = $connectionString
$xml.Save($webConfigPath)

Write-Host "OnAfterInit script finished running at $(Get-Date)."