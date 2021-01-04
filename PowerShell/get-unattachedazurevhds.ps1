<#
AUTHOR:
Manjunath

DATE:
17 July 2018

DESCRIPTION:
This script will create two files - unattached_managed_disks.csv,  unattached_un_managed_disks.csv

These two files will contain details about VHD files that are not attached to an Azure virtual machine.

#>

# List to store details of unattached managed disks
$unattached_managed_disk_object = $null
$unattached_managed_disk_object = @()

# Obtaining list of Managed disks
$managed_disk_list = Get-AzureRmDisk

# Obtaining list of Storage Accounts
$storage = Get-AzureRmStorageAccount

# List to store details of unattached managed disks
$unattached_un_managed_disk_object = $null
$unattached_un_managed_disk_object = @()



###########################################################
# Obtaining list of unattached MANAGED disks
###########################################################


    Write-Host " `n`n*************** Obtaining list of unattached MANAGED disks *************** " -ForegroundColor Cyan

    foreach($managed_disk_list_iterator in $managed_disk_list){
        if($managed_disk_list_iterator.ManagedBy -EQ $null){
            
            write-host "Collecting data about an unattached managed disk... `n" -ForegroundColor Gray
            # Creating a temporary PSObject to store the details of unattached managed disks
            $unattached_managed_disk_object_temp = new-object PSObject 
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $managed_disk_list_iterator.ResourceGroupName
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "Name" -Value $managed_disk_list_iterator.Name
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "DiskSizeGB" -Value $managed_disk_list_iterator.DiskSizeGB
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "Location" -Value $managed_disk_list_iterator.Location

            # Adding the objects to the final list
            $unattached_managed_disk_object += $unattached_managed_disk_object_temp
        }
    }

    Write-Host "Creating CSV file for Unattached Managed Disks ==> unattached_managed_disks.csv" -ForegroundColor Green
    $unattached_managed_disk_object | Export-Csv "unattached_managed_disks.csv" -NoTypeInformation -Force



###########################################################
# Obtaining list of unattached UN-MANAGED disks
###########################################################



    Write-Host " `n`n*************** Obtaining list of unattached UN-MANAGED disks *************** " -ForegroundColor Cyan

    foreach ($storageIterator in $storage) {
        
        Write-Host "`n`n Iterating over a storage account...." -ForegroundColor Gray
        $storageAccountName = $storageIterator.StorageAccountName
        $storageAccountContext = $storageIterator.Context
        $storageAccountContainer = Get-AzureStorageContainer -Context $storageAccountContext

    
        foreach($storageAccountContainer_iterator in $storageAccountContainer){
            
            Write-Host "Iterating over the Container..." -ForegroundColor Gray
            $blob = Get-AzureStorageBlob -Container $storageAccountContainer_iterator.Name -Context $storageAccountContext

                foreach ($blobIterator in $blob) {
                
                    if($blobIterator.Name -match ".vhd" -and $blobIterator.ICloudBlob.Properties.LeaseStatus -eq "Unlocked"){
                        #Write-Host "`n" "Blob Name: " $blobIterator.Name " -- LeaseStatus: " $blobIterator.ICloudBlob.Properties.LeaseStatus " -- Container: " $storageAccountContainer_iterator.Name " -- Storage Name:" $storageIterator.StorageAccountName " -- RG Name:" $storageIterator.ResourceGroupName

                        Write-Host "Collecting data about an unattached un-managed disk..." -ForegroundColor Gray
                        $unattached_un_managed_disk_object_temp = new-object PSObject 
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $storageIterator.ResourceGroupName
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "StorageName" -Value $storageIterator.StorageAccountName
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "StorageContainerName" -Value $storageAccountContainer_iterator.Name
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "BlobName" -Value $blobIterator.Name
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "LeaseStatus" -Value $blobIterator.ICloudBlob.Properties.LeaseStatus
                    
                        # Adding the objects to the final list
                        $unattached_un_managed_disk_object += $unattached_un_managed_disk_object_temp
                    }
                

        #"`n" + "Blob Name: " + $blobIterator.Name + " -- LeaseStatus: " + $blobIterator.ICloudBlob.Properties.LeaseStatus | Out-File c:\AzureUnusedVHDs\VHDlist.txt -Append
                }

        }

    }

    Write-Host "Creating CSV file for Unattached Un-Managed Disks ==> unattached_un_managed_disks.csv" -ForegroundColor Green
    $unattached_un_managed_disk_object | Export-Csv "unattached_un_managed_disks.csv" -NoTypeInformation -Force


