$azure_recovery_services_vault_list = Get-AzureRmRecoveryServicesVault 
 
$backup_details = $null 
$backup_details = @() 
 
foreach($azure_recovery_services_vault_list_iterator in $azure_recovery_services_vault_list){ 
 
    Set-AzureRmRecoveryServicesVaultContext -Vault $azure_recovery_services_vault_list_iterator 
 
    $container_list = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM 
 
    foreach($container_list_iterator in $container_list){ 
 
         
        $backup_item = Get-AzureRmRecoveryServicesBackupItem -Container $container_list_iterator -WorkloadType AzureVM 
        $backup_item_array = ($backup_item.ContainerName).split(';') 
        $backup_item_resource_name = $backup_item_array[1] 
        $backup_item_vm_name = $backup_item_array[2] 
        $backup_item_last_backup_status = $backup_item.LastBackupStatus 
        $backup_item_latest_recovery_point = $backup_item.LatestRecoveryPoint 
 
        $backup_details_temp = New-Object psobject 
 
        $backup_details_temp | Add-Member -MemberType NoteProperty -Name "ResourceGroupName" -Value $backup_item_resource_name 
        $backup_details_temp | Add-Member -MemberType NoteProperty -Name "VMName" -Value $backup_item_vm_name 
        $backup_details_temp | Add-Member -MemberType NoteProperty -Name "VaultName" -Value $azure_recovery_services_vault_list_iterator.Name 
        $backup_details_temp | Add-Member -MemberType NoteProperty -Name "BackupStatus" -Value $backup_item_last_backup_status 
        $backup_details_temp | Add-Member -MemberType NoteProperty -Name "LatestRecoveryPoint" -Value $backup_item_latest_recovery_point 
 
        $backup_details = $backup_details + $backup_details_temp 
 
    } 
 
} 
 
# Exporting the data to csv 
$backup_details | Export-Csv "vm_backup_status.csv" -NoTypeInformation -NoClobber
