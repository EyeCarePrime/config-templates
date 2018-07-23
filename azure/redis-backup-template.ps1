param (
        [Parameter(Mandatory=$true)]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory=$true)]
        [string]
        $redisCacheName,

        [Parameter(Mandatory=$true)]
        [string]
        $storageAccountName,

        [Parameter(Mandatory=$true)]
        [string]
        $storageAccountKey,

        [Parameter(Mandatory=$true)]
        [string]
        $containerName
    )

$ConfirmPreference = "None"
$connectionName = "AzureRunAsConnection"

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$storageAccountContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

$sasKeyForContainer = New-AzureStorageContainerSASToken -Name $containerName -Permission "rwdl" -StartTime ([System.DateTime]::Now).AddMinutes(-15) -ExpiryTime ([System.DateTime]::Now).AddHours(5) -Context $storageAccountContext -FullUri

$dateStamp = [int][double]::Parse((Get-Date -UFormat %s))

$backupName = $resourceGroupName + "-" + $dateStamp

Export-AzureRmRedisCache -Confirm:$false -Verbose -Debug -ResourceGroupName $resourceGroupName -Name $redisCacheName -Prefix $backupName -Container ($sasKeyForContainer)