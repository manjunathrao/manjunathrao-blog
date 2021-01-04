## Create temporary Snapshot from a Managed Disk ##

$resourceGroupName = 'manju_copy_disk' # Source and Destination must be in same Resource Group
$location = 'east us 2' # Source and Destination has to be in same location
$source_vm_name = 'server1'# Name of source virtual machine
$destination_vm_name = 'server3' # Name of destination virtual machine
$storageType = 'StandardLRS' # Type of managed disk


$source_vm_object = get-azurermvm -ResourceGroupName $resourceGroupName -Name $source_vm_name

$data_disk_list = Get-AzureRmDisk | where {$_.ManagedBy -match $source_vm_name -and $_.OsType -eq $null}

$snapshot_list = New-Object System.Collections.ArrayList($null)
$snapshot_list_name = New-Object System.Collections.ArrayList($null)

foreach($data_disk_list_iterator in $data_disk_list){
    
    $snapshotName = $destination_vm_name + "_Snapshot_" + $data_disk_list_iterator.Name

    $snapshot_config = New-AzureRmSnapshotConfig -SourceUri $data_disk_list_iterator.id -Location $location -CreateOption copy

    $snapshot_object = New-AzureRmSnapshot -Snapshot $snapshot_config -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

    $snapshot_list.Add($snapshot_object.Id)

    $snapshot_list_name.Add($snapshot_object.Name)
}


## Create Managed disk from snap shot created above and attach it to the destination virtual machine ##

$count=0
$lun_count = 1 # LUN count 

# Get reference to destination virtual machine
$destination_vm_object = Get-AzureRmVM -Name $destination_vm_name -ResourceGroupName $resourceGroupName

foreach($snapshot_list_iterator in $snapshot_list){


    $disk_name = $destination_vm_name + "_datadisk_" + $count
    $count += 1

    $diskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot_list_iterator

    $datadisk_object = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $disk_name
    $destination_vm_object = Add-AzureRmVMDataDisk -VM $destination_vm_object -CreateOption Attach -ManagedDiskId $datadisk_object.Id -Lun $lun_count
    $lun_count += 1
    
}

## Update the virutal machine with the new managed disks ##
Update-AzureRmVM -VM $destination_vm_object -ResourceGroupName $resourceGroupName  ## --> LINE CODE NOT WORKING


## Delete the snapshots ##
foreach($snapshot_list_name_iterator in $snapshot_list_name){
    Remove-AzureRmSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshot_list_name_iterator -Force
}