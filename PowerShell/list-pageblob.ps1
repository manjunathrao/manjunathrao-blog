<#

AUTHOR:
Manjunath Rao

DESCRIPTION:
This script fetches the details of PAGE BLOB across the Azure subscription and saves it as a CSV file. 
The CSV file will be saved under the location from where the script was run.

#>

$azure_page_blob_object = $null
$azure_page_blob_object = @()


$resource_groups_list = Get-AzureRmResourceGroup

## Iterate through each resource group
foreach($resource_groups_list_iterator in $resource_groups_list){

    ## Fetch storage account list for each resource group 
    $storage_account_list = Get-AzureRmStorageAccount -ResourceGroupName $resource_groups_list_iterator.ResourceGroupName

    foreach($storage_account_list_iterator in $storage_account_list){

        $storage_account_name = $storage_account_list_iterator.StorageAccountName
        
        ## Fetching Storage account's primary key
        $storage_account_key_list = Get-AzureRmStorageAccountKey -ResourceGroupName $resource_groups_list_iterator.ResourceGroupName -Name $storage_account_name
        $storage_account_key = $storage_account_key_list[0].Value

        $context = New-AzureStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

        $container_list = get-azurestoragecontainer -Context $context

        ## Iterating over each container
        foreach($container_list_iterator in $container_list){
            $blob_list = get-azurestorageblob -Container $container_list_iterator.Name -Context $context

            foreach($blob_list_iterator in $blob_list){

                if($blob_list_iterator.BlobType -eq 'PageBlob'){
                    Write-host $storage_account_name + "..." + $container_list_iterator.Name + "..." + $blob_list_iterator.BlobType + "..." +  $blob_list_iterator.name

                    $azure_page_blob_object_temp = new-object PSObject
                    $azure_page_blob_object_temp | add-member -MemberType NoteProperty -Name "ResourceGroup" -Value $resource_groups_list_iterator.ResourceGroupName
                    $azure_page_blob_object_temp | add-member -MemberType NoteProperty -Name "StorageAccountName" -Value $storage_account_name
                    $azure_page_blob_object_temp | add-member -MemberType NoteProperty -Name "ContainerName" -Value $container_list_iterator.Name
                    $azure_page_blob_object_temp | add-member -MemberType NoteProperty -Name "PageBlobName" -Value $blob_list_iterator.name
                    $azure_page_blob_object_temp | add-member -MemberType NoteProperty -Name "PageBlobLastModified" -Value $blob_list_iterator.LastModified

                    $azure_page_blob_object += $azure_page_blob_object_temp

                }

            }
        }

    }

    
}

$azure_page_blob_object | Export-Csv "page_blob_details.csv" -NoTypeInformation -Force
write-host "Details are saved under: page_blob_details.csv" -ForegroundColor Green
