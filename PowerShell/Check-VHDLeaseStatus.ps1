# Author: Manjunath
# This script will fetch the Lease Status of VHDs in the selected Azure Subscription.


$ErrorActionPreference = "SilentlyContinue"

# Login to Azure Account
try
{
    Login-AzureRmAccount -ErrorAction Stop
}
catch
{
    # The exception lands in [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationCanceledException]
    Write-Host "User Cancelled The Authentication" -ForegroundColor Yellow
    exit
}


# Prompting the user to select the subscription
Get-AzureRmSubscription | Out-GridView -OutputMode Single -Title "Please select a subscription" | ForEach-Object {$selectedSubscriptionID = $PSItem.SubscriptionId}
Write-Host "You have selected the subscription: $selectedSubscriptionID. Proceeding with fetching the inventory. `n" -ForegroundColor green

# Setting the selected subscription
Select-AzureRmSubscription -SubscriptionId $selectedSubscriptionID

Write-Host "The output will be stored in the location -> c:\AzureUnusedVHDs\VHDlist.txt" -ForegroundColor Green

if(Test-Path "c:\AzureUnusedVHDs") {
    Remove-Item "c:\AzureUnusedVHDs" -Recurse
}

New-Item c:\AzureUnusedVHDs -ItemType directory -Force

$storage = Get-AzureRmStorageAccount

foreach ($storageIterator in $storage) {
    $storageAccountName = $storageIterator.StorageAccountName
    $storageAccountContext = $storageIterator.Context
    $storageAccountContainer = Get-AzureStorageContainer -Context $storageAccountContext

    $blob = Get-AzureStorageBlob -Container $storageAccountContainer.Name -Context $storageAccountContext

    Write-Host "`n`n" "Storage Account Name: "$storageAccountName
    "`n`n Storage Account Name: " + $storageAccountName | Out-File c:\AzureUnusedVHDs\VHDlist.txt -Append

    foreach ($blobIterator in $blob) {
        Write-Host "`n" "Blob Name: " $blobIterator.Name " -- LeaseStatus: " $blobIterator.ICloudBlob.Properties.LeaseStatus

        "`n" + "Blob Name: " + $blobIterator.Name + " -- LeaseStatus: " + $blobIterator.ICloudBlob.Properties.LeaseStatus | Out-File c:\AzureUnusedVHDs\VHDlist.txt -Append
    }

    Write-Host "`n-------------- "
    "`n-------------- " | Out-File c:\AzureUnusedVHDs\VHDlist.txt -Append

}
