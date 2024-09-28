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
[string] $scriptPath = "$workDirectory\bobs-used-bookstore-classic\db-scripts\bobs-used-bookstore-classic-db.sql"

$sqlUsername = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).username
$sqlPassword = ((Get-SECSecretValue -SecretId "SQLServerRDSSecret").SecretString | ConvertFrom-Json).password

$endpointAddress = Get-RDSDBInstance | Select-Object -ExpandProperty Endpoint | select Address
[string] $SQLDatabaseEndpoint = $endpointAddress.Address

[string] $SQLDatabaseEndpointTrimmed = $SQLDatabaseEndpoint.Replace(':1433','')

# Set the database name
$databaseName = "BookStoreClassic"

# SQL query to check if the database exists
$checkDbQuery = "IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$databaseName') SELECT 1 ELSE SELECT 0"

# Run the sqlcmd command to check if the database exists
$checkDbResult = sqlcmd -U $sqlUsername -P $sqlPassword -S $SQLDatabaseEndpointTrimmed -Q $checkDbQuery -h -1 -W

# Trim any whitespace from the result
$checkDbResult = $checkDbResult.Trim()

if ($checkDbResult -eq "0") {
    Write-Host "Database '$databaseName' does not exist. Creating database..."
    # Run the sqlcmd command to create the database
    sqlcmd -U $sqlUsername -P $sqlPassword -S $SQLDatabaseEndpointTrimmed -i $scriptPath
} else {
    Write-Host "Database '$databaseName' already exists. Skipping creation."
}

[string] $connectionString = "Server=$SQLDatabaseEndpointTrimmed;Database=$databaseName;User Id=$sqlUsername;Password=$sqlPassword;"

[string] $webConfigFolder = "$workDirectory\bobs-used-bookstore-classic\app\Bookstore.Web\"
$webConfigPath = Join-Path $webConfigFolder "Web.config"

$webConfigXml = [xml](Get-Content -Path $webConfigPath)

$addElement = $webConfigXml.configuration.appSettings.add | Where-Object { $_.key -eq "ConnectionStrings/BookstoreDatabaseConnection" }
$addElement.value = $connectionString

$webConfigXml.Save($webConfigPath)

Write-Host "OnAfterInit script finished running at $(Get-Date)."