# Create a rediscache backup cleanup process that can be scheduled
param (
        [Parameter(Mandatory=$true)]
        [int]
        $daysToKeep,

        [Parameter(Mandatory=$true)]
        [string]
        $storageAccount,

        [Parameter(Mandatory=$true)]
        [string]
        $storageAccessKey,

        [Parameter(Mandatory=$true)]
        [string]
        $storageContainer,
    )

$context = New-AzureStorageContext -Debug -Verbose -StorageAccountName $storageAccount -StorageAccountKey $storageAccessKey
New-AzureStorageContainer -Debug -Verbose -Name $storageContainer -Context $context -Permission Blob -ErrorAction SilentlyContinue

$EGBlobs = Get-AzureStorageBlob -Debug -Verbose -Container $storageContainer -Context $context | sort-object LastModified | select lastmodified, name

foreach($blob in $EGBlobs)
{
    echo "Processing $blob.name"
    if($blob.lastmodified -lt (get-date).AddDays($daysToKeep*-1))
    {
        echo "Deleting $blob.name"
        Remove-AzureStorageBlob -Debug -Verbose -Blob $blob.name -Container $storageContainer -Context $context
    }
}