
$connectionName = "AzureRunAsConnection"

try{
    #Getting the service principal connection "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -name $connectionName

    "Logging into Azure..."
    Add-AzureRmAccount -ServicePrincipal -TenantID $servicePrincipalConnection.TenantID -ApplicationID $servicePrincipalConnection.ApplicationID -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

}
catch{
    if(!$servicePrincipalConnection){
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

if($err) {
throw $err
}



function Send-Email() {

    Write-Output "Sending an email"
    $Username ="<ENTER YOUR SENDGRID USER NAME>" # Your user name - found in sendgrid portal
    $Password = ConvertTo-SecureString "<ENTER YOUR SENDGRID PASSWORD>" -AsPlainText -Force # SendGrid Password
    $credential = New-Object System.Management.Automation.PSCredential $Username, $Password
    $SMTPServer = "smtp.sendgrid.net"
    $EmailFrom = "<FROM EMAIL ADDRESS>" # Can be anything - aaa@xyz.com
    $EmailTo = "< TO EMAIL ADDRESS>" # Valid recepient email address
    $Subject = "Azure Audit Report"
    $Body = "Summary as of: " + (Get-Date -Format G) + " UTC"+ "`n`n" + $finalResult


    Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body -Attachments $file_path_for_nsg, $file_path_for_running_VM, $file_path_for_deallocated_VM, $file_path_for_stopped_VM, $file_path_for_vm_with_no_backup

}


## Fetching the Azure resource details
$nsg_list = Get-AzurermNetworkSecurityGroup
$resource_group_list = Get-AzureRmResourceGroup
$recovery_service_vault_list = get-AzureRmRecoveryServicesVault

# To store Powershell Objects
#https://social.technet.microsoft.com/Forums/windowsserver/en-US/0992ff13-3a97-4f4c-8d1f-6d75e6dd9eab/ps-object-to-csv-file?forum=winserverpowershell

## Creating variables to store powershell objects to store the data, then used to create CSV files
$nsg_object=$null
$nsg_object=@()

$VM_deallocated_object = $null
$VM_deallocated_object = @()

$VM_stopped_object = $null
$VM_stopped_object = @()

$VM_running_object = $null
$VM_running_object = @()

$complete_vm_list = $null
$complete_vm_list = @()

$backed_up_vms = $null
$backed_up_vms = @()

## Declaring variables to store the count 
$VM_deallocated_count = 0
$VM_running_count = 0
$port_opened_for_all_count = 0


## Creating file paths to store the CSV files temporarily
$file_path_for_nsg = $env:temp+"\Azure_nsg_rules_to_be_fixed.csv"
$file_path_for_running_VM = $env:temp+"\Azure_running_vm_list.csv"
$file_path_for_deallocated_VM = $env:temp+"\Azure_deallocated_vm_list.csv"
$file_path_for_stopped_VM = $env:temp+"\Azure_stopped_vm_list.csv"
$file_path_for_vm_with_no_backup = $env:temp+"\Azure_vm_with_no_backup.csv"

################################################
# OBTAINING NSG RULE THAT CAUSES vulnerability
################################################

"OBTAINING NSG RULE THAT CAUSES vulnerability" | write-output

foreach($nsg_list_iterator in $nsg_list){
    $security_rules_list = $nsg_list_iterator.SecurityRules

    foreach($security_rules_list_iterator in $security_rules_list) {
        if($security_rules_list_iterator.SourceAddressPrefix -eq '*' -and $security_rules_list_iterator.Access -eq 'Allow' -and $security_rules_list_iterator.Direction -eq 'Inbound'){
            Write-Output $security_rules_list_iterator.name
            $port_opened_for_all_count = $port_opened_for_all_count + 1

            # Create Powershell object
            $nsg_object_temp = new-object PSObject 
            $nsg_object_temp | add-member -membertype NoteProperty -name "NSG rule Name" -Value $security_rules_list_iterator.Name
            $nsg_object_temp | add-member -membertype NoteProperty -name "NSG ID" -Value $security_rules_list_iterator.Id
            # https://answers.microsoft.com/en-us/msoffice/forum/msoffice_o365admin/powershell-alternativeemailaddresses/d55b8718-c181-4199-80a6-b1230b48afc2
            $nsg_object_temp | add-member -membertype NoteProperty -name "Source Port" -Value ($security_rules_list_iterator | Select-Object @{Name=“SourcePortRange”;Expression={$_.SourcePortRange}})
            $nsg_object_temp | add-member -membertype NoteProperty -name "Destination Port" -Value ($security_rules_list_iterator | Select-Object @{Name=“DestinationPortRange”;Expression={$_.DestinationPortRange}})
            $nsg_object_temp | add-member -membertype NoteProperty -name "Source Address Prefix" -Value ($security_rules_list_iterator | Select-Object @{Name=“SourceAddress”;Expression={$_.SourceAddressPrefix}})
            $nsg_object_temp | add-member -membertype NoteProperty -name "Direction" -Value $security_rules_list_iterator.Direction
            $nsg_object_temp | add-member -membertype NoteProperty -name "Priority" -Value $security_rules_list_iterator.Priority

                    $nsg_object += $nsg_object_temp 

        }
    }
}


##############################################################
# OBTAINING COUNT OF RUNNING AND DE-ALLOCATED VIRTUAL MACHINES
##############################################################

"OBTAINING COUNT OF RUNNING AND DE-ALLOCATED VIRTUAL MACHINES" | write-output

foreach($resource_group_list_iterator in $resource_group_list){

    $vm_list = Get-AzureRmVM -ResourceGroupName $resource_group_list_iterator.ResourceGroupName

    foreach($vm_list_iterator in $vm_list){

        $vm_status = get-azurermvm -ResourceGroupName $resource_group_list_iterator.ResourceGroupName -Name $vm_list_iterator.name -Status

        if($vm_status.Statuses[1].DisplayStatus -eq "VM deallocated"){
            $VM_deallocated_count = $VM_deallocated_count + 1

            # Create one object for each entry
            $VM_deallocated_object_temp = new-object PSObject
            $VM_deallocated_object_temp | add-member -membertype NoteProperty -name "Resource Group Name" -Value $resource_group_list_iterator.ResourceGroupName
            $VM_deallocated_object_temp | add-member -membertype NoteProperty -name "Virtual machine Name" -Value $vm_list_iterator.name

            $VM_deallocated_object += $VM_deallocated_object_temp
        }

        if($vm_status.Statuses[1].DisplayStatus -eq "VM running") {
            $VM_running_count = $VM_running_count + 1

            # Create one object for each entry
            $VM_running_object_temp = new-object PSObject
            $VM_running_object_temp | add-member -membertype NoteProperty -name "Resource Group Name" -Value $resource_group_list_iterator.ResourceGroupName
            $VM_running_object_temp | add-member -membertype NoteProperty -name "Virtual machine Name" -Value $vm_list_iterator.name

            $VM_running_object += $VM_running_object_temp
        }

        if($vm_status.Statuses[1].DisplayStatus -eq "VM stopped") {
            $VM_stopped_count = $VM_stopped_count + 1

            # Create one object for each entry
            $VM_stopped_object_temp = new-object PSObject
            $VM_stopped_object_temp | add-member -membertype NoteProperty -name "Resource Group Name" -Value $resource_group_list_iterator.ResourceGroupName
            $VM_stopped_object_temp | add-member -membertype NoteProperty -name "Virtual machine Name" -Value $vm_list_iterator.name

            $VM_stopped_object += $VM_stopped_object_temp
        }

    }

}


########################################################################
# OBTAINING COUNT OF AZURE VMs NOT BACKED UP USING AZURE BACK UP SERVICE
########################################################################

"OBTAINING COUNT OF AZURE VMs NOT BACKED UP USING AZURE BACK UP SERVICE" | Write-Output

## Creating object that contains a list of Backed up VMs using "Azure Back up and recovery service"
foreach($recovery_service_vault_list_iterator in $recovery_service_vault_list){


    Set-AzureRmRecoveryServicesVaultContext -Vault $recovery_service_vault_list_iterator

    $container_list = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM 


    foreach($container_list_iterator in $container_list){
        $backup_item = Get-AzureRmRecoveryServicesBackupItem -Container $container_list_iterator -WorkloadType AzureVM

        $backup_item_array = ($backup_item.ContainerName).split(';')
        $backup_item_vm_name = $backup_item_array[2]
        #$backed_up_vms.Add($backup_item_vm_name.ToString())
        $backed_up_vms_temp = new-object PSObject 

        $backed_up_vms_temp | add-member -membertype NoteProperty -name "ServerName" -Value $backup_item_vm_name
        $backed_up_vms += $backed_up_vms_temp

    }

}

## Collecting the complete list of azure virtual machines


foreach($resource_group_list_iterator in $resource_group_list){
    $vm_list = get-azurermvm -ResourceGroupName $resource_group_list_iterator.ResourceGroupName
    
    foreach($vm_list_iterator in $vm_list){
            $complete_vm_list_temp = New-Object PSObject

    $complete_vm_list_temp | add-member -membertype NoteProperty -name "ServerName" -Value $vm_list_iterator.name.tostring()
    $complete_vm_list += $complete_vm_list_temp
    }
    
}

# creating a new array object to calculate the list of Azure VMs not backed up 
$not_backed_up_vms = $complete_vm_list

## Calculate difference
foreach ($complete_vm_list_iterator in $complete_vm_list){
    
    foreach($backed_up_vms_iterator in $backed_up_vms){
        if($complete_vm_list_iterator.ServerName -eq $backed_up_vms_iterator.ServerName){
            # Make a new array which excludes the server names that are already backed up
            $not_backed_up_vms = $not_backed_up_vms | ? {$_.ServerName -ne $backed_up_vms_iterator.ServerName}
        }
    }

}

#####################
# CREATING CSV FILES
#####################

"CREATING CSV FILES" | write-output

$nsg_object | export-csv $file_path_for_nsg -NoTypeInformation
$VM_running_object | export-csv $file_path_for_running_VM -NoTypeInformation
$VM_deallocated_object | export-csv $file_path_for_deallocated_VM -NoTypeInformation
$VM_stopped_object | Export-Csv $file_path_for_stopped_VM -NoTypeInformation
$not_backed_up_vms | Export-Csv $file_path_for_vm_with_no_backup -NoTypeInformation


"Creating HASH table to store data to be passed as a string into Email's body" | write-output

## Creating HASH table to store data to be passed as a string into Email's body
$hash_table = @{}
$hash_table.Add("Inbound port opened to all: ", $port_opened_for_all_count)
$hash_table.Add("De-allocated virtual Machines Count:", $VM_deallocated_count)
$hash_table.Add("Running virtual Machines Count :", $VM_running_count)
$hash_table.Add("Stopped (Shutdown) virtual Machines Count :", $VM_stopped_count)
$hash_table.Add("Azure VMs with no backup configured Count :", $not_backed_up_vms.Count)

$finalResult = $hash_table.GetEnumerator()  | % { "`n $($_.Name)$($_.Value)" }
#$hash_table.GetEnumerator()  | % { "$($_.Name)$($_.Value)" }

Send-Email
