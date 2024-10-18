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
$webConfigPath = Join-Path $webConfigFolder "Web.config
$webConfigXml = [xml](Get-Content -Path $webConfigPath)
$webConfigXml.configuration.connectionStrings.add.connectionString = $connectionString
$webConfigXml.Save($webConfigPath)

$vsixInstallerPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VSIXInstaller.exe"
$vsExtensionPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\Extensions"
$targetPublisher = 'Amazon Web Services'

$manifestFiles = Get-ChildItem -Path $vsExtensionPath -Recurse -Filter "extension.vsixmanifest"

$filteredExtensionsList = @()

foreach ($manifestFile in $manifestFiles) {
    try {
        [xml]$xmlContent = Get-Content $manifestFile.FullName
        
        $publisher = $xmlContent.PackageManifest.Metadata.Identity.Publisher
        $displayNameNode = $xmlContent.PackageManifest.Metadata.DisplayName
        $identifier = $xmlContent.PackageManifest.Metadata.Identity.Id
        
        if ($publisher -eq $targetPublisher) {
            $filteredExtensionsList += [PSCustomObject]@{
                Id          = $identifier
                DisplayName = $displayNameNode
                Publisher   = $publisher
                FilePath    = $manifestFile.FullName
            }
        }
    }
    catch {
        Write-Host "Error processing file: $($manifestFile.FullName)" -ForegroundColor Yellow
    }
}

foreach ($extension in $filteredExtensionsList) {
    try {
        if (Test-Path $vsixInstallerPath) {
            $arguments = ("/q", "/u:$extension.Id")

            Start-Process -FilePath $vsixInstallerPath -ArgumentList $arguments -Wait

        } else {
            Write-Host "VSIXInstaller.exe not found. Please verify the Visual Studio installation path."
        }
    }
    catch {
        Write-Host "Error uninstalling the extension:" -ForegroundColor Red
        Write-Host $extension -ForegroundColor Red
    }
}

$bucketName = "windows-dev-env-ec2"
$folderPath = "artifacts/"

$localPath = [System.Environment]::GetFolderPath('Desktop')

if (-not (Test-Path $localPath)) {
    Write-Host "Creating local directory: $localPath"
    New-Item -Path $localPath -ItemType Directory
} else {
    Write-Host "Local directory already exists: $localPath"
}

$fileName = "AWSToolkitPackage.vsix"
$s3Url = "https://$bucketName.s3.amazonaws.com/$folderPath$fileName"

$vsixFilePath = Join-Path $localPath $fileName

Write-Host "Downloading $fileName from S3 bucket..."
Invoke-WebRequest -Uri $s3Url -OutFile $vsixFilePath

try {
    if (Test-Path $vsixFilePath) {
        if (Test-Path $vsixInstallerPath) {
            $arguments = @("$vsixFilePath", "/q")

            Start-Process -FilePath $vsixInstallerPath -ArgumentList $arguments -Wait

        } else {
            Write-Host "VSIXInstaller.exe not found. Please verify the Visual Studio installation path."
        }
    } else {
        Write-Host "VSIX package not found after download."
    }
}
catch {
    Write-Host "Error uninstalling the extension:" -ForegroundColor Red
    Write-Host $extension -ForegroundColor Red
}


Write-Host "OnAfterInit script finished running at $(Get-Date)."