<#
AUTHOR:
Manjunath Rao

DESCRIPTION:
This script deletes Azure blobs that are older than X days.
Provide the Azure Storage Account name, access key and container name as input.
A log file is created tracking the details of blobs that are deleted. Including the count of deleted blobs.

#>

## Declaring the variables
$number_of_days_threshold = 20
$current_date = get-date
$date_before_blobs_to_be_deleted = $current_date.AddDays(-$number_of_days_threshold)

# Number of blobs deleted
$blob_count_deleted = 0

# Storage account details
$storage_account_name = "<INSERT_AZURE_STORAGE_ACCOUNT_NAME>" 
$storage_account_key = "<INSERT_AZURE_STORAGE_ACCOUNT_KEY>"
$container = "<INSERT_AZURE_STORAGE_CONTAINER_NAME>"

## Creating Storage context for Source, destination and log storage accounts
$context = New-AzureStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key
$blob_list = Get-AzureStorageBlob -Context $context -Container $container

## Creating log file
$log_file = "log-"+(get-date).ToString().Replace('/','-').Replace(' ','-').Replace(':','-') + ".txt"
$local_log_file_path = $env:temp + "\" + "log-"+(get-date).ToString().Replace('/','-').Replace(' ','-').Replace(':','-') + ".txt"

write-host "Log file saved as: " $local_log_file_path -ForegroundColor Green

## Iterate through each blob
foreach($blob_iterator in $blob_list){

    $blob_date = [datetime]$blob_iterator.LastModified.UtcDateTime
    
    # Check if the blob's last modified date is less than the threshold date for deletion
    if($blob_date -le $date_before_blobs_to_be_deleted) {

        Write-Output "-----------------------------------" | Out-File $local_log_file_path -Append
        write-output "Purging blob from Storage: " $blob_iterator.name | Out-File $local_log_file_path -Append
        write-output " " | Out-File $local_log_file_path -Append
        write-output "Last Modified Date of the Blob: " $blob_date | Out-File $local_log_file_path -Append
        Write-Output "-----------------------------------" | Out-File $local_log_file_path -Append

        # Cmdle to delete the blob
        Remove-AzureStorageBlob -Container $container -Blob $blob_iterator.Name -Context $context

        $blob_count_deleted += 1
    }

}

write-output "Blobs deleted: " $blob_count_deleted | Out-File $local_log_file_path -Append