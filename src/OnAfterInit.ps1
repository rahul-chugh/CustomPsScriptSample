<#

Feel free to modify this file by implementing your logic.

This script is invoked after initialization scripts completed running 
but before user has logged in.

This script runs under Administrator account but without any UI, 
meaning this script can't ask for user input. 

It's OK for this script to run a few minutes, as it runs before
users log in.

#>

Write-Host "Main script finished running at $(Get-Date)."

Set-Location "C:\Users\Administrator"
[string] $workDirectory = "./AWS-workshop-assets"

$sqlUsername = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).username
$sqlPassword = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).password
[string] $SQLDatabaseEndpoint = [System.Environment]::GetEnvironmentVariable("SQLDatabaseEndpoint")

[string] $SQLDatabaseEndpointTrimmed = $SQLDatabaseEndpoint.Replace(':1433','')
[string] $connectionString = "Server=$SQLDatabaseEndpointTrimmed;Database=GadgetsOnlineDB;User Id=$sqlUsername;Password=$sqlPassword;"

[string] $webConfigFolder = "$workDirectory\dotnet-modernization-gadgetsonline/GadgetsOnline/GadgetsOnline"
$webConfigPath = Join-Path $webConfigFolder "Web.config" 

$xml = [xml](Get-Content -Path $webConfigPath)
$xml.configuration.connectionStrings.add.connectionString = $connectionString
$xml.Save($webConfigPath)

Write-Host "Custom Script finished execution at $(Get-Date)."
