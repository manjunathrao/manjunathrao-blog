<#
#          Script: Azure Inventory Script                                           
#            Date: January 04, 2021                                                                     
#          Author: Manjunath
#

DESCRIPTION:
This script will pull the infrastructure details of the Azure subscriptions. Details will be stored under the folder "c:\AzureInventory"
If you have multiple subscriptions, a separate folder will be created for individual subscription.
CSV files will be created for individual services (Virtual Machines, NSG rules, Storage Account, Virtual Networks, Azure Load Balancers) inside the subscription's directory

#>

function Invoke-GetAzureInventoryFunction{
    
    # Sign into Azure Portal
    #Login-AzAccount

    # Fetching subscription list
    $subscription_list = Get-AzSubscription

    # Fetch current working directory 
    $working_directory = "c:\AzureInventory"

    new-item $working_directory -ItemType Directory -Force

    
    # Fetching the IaaS inventory list for each subscription
    
    
    foreach($subscription_list_iterator in $subscription_list){
        $subscription_id = $subscription_list_iterator.id
        $subscription_name = $subscription_list_iterator.name

        if($subscription_list_iterator.State -eq "Enabled"){
            Get-AzureInventory($subscription_id)
        }
        
    }

    

    <#
    Get-AzureRmSubscription | 
    ForEach-Object{
        #Select-AzureRmSubscription -SubscriptionId $_.ID
        if($_.State -ne "Disabled"){
            write-output "Generating inventory for the subscription: " $_.TenantId
            Get-AzureInventory($_.TenantId, $_.Name)
        }
        
    }

    #>
}



function Get-AzureInventory{

Param(
[String]$subscription_id
)

Write-Output ("Fetching inventory for subscription ID: {0}" -f $subscription_id)
# Selecting the subscription
Select-AzSubscription -Subscription $subscription_id


# Create a new directory with the subscription name
$path_to_store_inventory_csv_files = "c:\AzureInventory\" + $subscription_id

# Create a new directory with the subscription name
new-item $path_to_store_inventory_csv_files -ItemType Directory -Force

# Change the directory location to store the CSV files
Set-Location -Path $path_to_store_inventory_csv_files

# Fetch the Virtual Machines from the subscription
$azureVMDetails = Get-AzVM

# Fetch the NIC details from the subscription
$azureNICDetails = Get-AzNetworkInterface

# Fetch the Storage Accounts from the subscription
$azureStorageAccountDetails = Get-AzStorageAccount

# Fetch the Virtual Networks from the subscription
$azureVirtualNetworkDetails = Get-AzVirtualNetwork

# Fetch the NSG rules from the subscription
$azureNSGDetails = Get-AzNetworkSecurityGroup

# Fetch the Azure load balancer details
$AzureLBList = Get-AzLoadBalancer




#####################################################################
#    Fetching Virtual Machine Details                               #
#####################################################################

    $virtual_machine_object = $null
    $virtual_machine_object = @()


    # Iterating over the Virtual Machines under the subscription
        
        foreach($azureVMDetails_Iterator in $azureVMDetails){
        
            # Fetching the satus
            $vm_status = Get-AzVM -ResourceGroupName $azureVMDetails_Iterator.resourcegroupname -name $azureVMDetails_Iterator.name -Status

            #Fetching the private IP
            foreach($azureNICDetails_iterator in $azureNICDetails){
                if($azureNICDetails_iterator.Id -eq $azureVMDetails_Iterator.NetworkProfile.NetworkInterfaces.id) {
                #write-Host $vm.NetworkInterfaceIDs
                $private_ip_address = $azureNICDetails_iterator.IpConfigurations.privateipaddress

                    # Check for Public IP address. Extract only ResourceID because the IP will not be available if the VM has a Dynamic Public IP and it is not running.
                    if($azureNICDetails_iterator.IpConfigurations.publicipaddress.Id -ne $null){
                    $public_ip_resource_id = $azureNICDetails_iterator.IpConfigurations.publicipaddress.Id
                    }
                }
            }

            #Fetching data disk names
            $data_disks = $azureVMDetails_Iterator.StorageProfile.DataDisks
            $data_disk_name_list = ''
            <#
            if($data_disks.Count -eq 0){
                $data_disk_name_list = "No Data Disk Attached"
                #write-host $data_disk_name_list
            }elseif($data_disks.Count -ge 1) {

            #>

            foreach ($data_disks_iterator in $data_disks) {
                $data_disk_name_list_temp = $data_disk_name_list + "; " +$data_disks_iterator.name 
                #Trimming the first three characters which contain --> " ; "
                $data_disk_name_list = $data_disk_name_list_temp.Substring(2)
                #write-host $data_disk_name_list
            }

        #}

            

            # Fetching OS Details (Managed / un-managed)

            if($azureVMDetails_Iterator.StorageProfile.OsDisk.manageddisk -eq $null){
                # This is un-managed disk. It has VHD property

                $os_disk_details_unmanaged = $azureVMDetails_Iterator.StorageProfile.OsDisk.Vhd.Uri
                $os_disk_details_managed = "This VM has un-managed OS Disk"

            }else{
                
                $os_disk_details_managed = $azureVMDetails_Iterator.StorageProfile.OsDisk.ManagedDisk.Id
                $os_disk_details_unmanaged = "This VM has Managed OS Disk"
            }

            # Availability set extension
            if($azureVMDetails_Iterator.AvailabilitySetReference.id -ne $null){
                $vm_availability_set_reference_id = $azureVMDetails_Iterator.AvailabilitySetReference.id
            }else{
                $vm_availability_set_reference_id = "VM not part of any Availability Set"
            }

            $virtual_machine_object_temp = new-object PSObject 
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $azureVMDetails_Iterator.ResourceGroupName
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMName" -Value $azureVMDetails_Iterator.Name
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMStatus" -Value $vm_status.Statuses[1].DisplayStatus
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "Location" -Value $azureVMDetails_Iterator.Location
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMSize" -Value $azureVMDetails_Iterator.HardwareProfile.VmSize
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSDisk" -Value $azureVMDetails_Iterator.StorageProfile.OsDisk.OsType
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSImageType" -Value $azureVMDetails_Iterator.StorageProfile.ImageReference.sku
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "AdminUserName" -Value $azureVMDetails_Iterator.OSProfile.AdminUsername
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "NICId" -Value $azureVMDetails_Iterator.NetworkProfile.NetworkInterfaces.id
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSVersion" -Value $azureVMDetails_Iterator.StorageProfile.ImageReference.Sku
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "PrivateIP" -Value $private_ip_address
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "PublicIpResourceID" -Value $public_ip_resource_id
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "AvailabilitySetReferenceID" -Value $vm_availability_set_reference_id
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "ManagedOSDiskURI" -Value $os_disk_details_managed
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "UnManagedOSDiskURI" -Value $os_disk_details_unmanaged
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "DataDiskNames" -Value $data_disk_name_list


            $virtual_machine_object += $virtual_machine_object_temp

            
        }
    
        $virtual_machine_object | Export-Csv "Virtual_Machine_details.csv" -NoTypeInformation -Force

    

############################################################################
#    Fetching custom Network Security Groups Details                       #
############################################################################

            $network_security_groups_object = $null
            $network_security_groups_object = @()

            foreach($azureNSGDetails_Iterator in $azureNSGDetails){
        
        

            $securityRulesPerNSG = $azureNSGDetails_Iterator.SecurityRules
            if($securityRulesPerNSG -eq $null){
                continue
            }

            foreach($securityRulesPerNSG_Iterator in $securityRulesPerNSG) {

                $network_security_groups_object_temp = new-object PSObject

                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "Name" -Value $securityRulesPerNSG_Iterator.Name
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "Priority" -Value $securityRulesPerNSG_Iterator.Priority
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "Protocol" -Value $securityRulesPerNSG_Iterator.Protocol
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "Direction" -Value $securityRulesPerNSG_Iterator.Direction
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "SourcePortRange" -Value ($securityRulesPerNSG_Iterator | Select-Object @{Name=“SourcePortRange”;Expression={$_.SourcePortRange}})
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "DestinationPortRange" -Value ($securityRulesPerNSG_Iterator | Select-Object @{Name=“DestinationPortRange”;Expression={$_.DestinationPortRange}})
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "SourceAddressPrefix" -Value ($securityRulesPerNSG_Iterator | Select-Object @{Name=“SourceAddressPrefix”;Expression={$_.SourceAddressPrefix}})
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "DestinationAddressPrefix" -Value ($securityRulesPerNSG_Iterator | Select-Object @{Name=“DestinationAddressPrefix”;Expression={$_.DestinationAddressPrefix}})
                $network_security_groups_object_temp | add-member -MemberType NoteProperty -Name "Access" -Value $securityRulesPerNSG_Iterator.Access
                
                $network_security_groups_object += $network_security_groups_object_temp
            }
        
            # Setting the pointer to the next row and first column
            
            
        }

        if($network_security_groups_object -ne $null){
                $network_security_groups_object | Export-Csv "nsg_custom_rules_details.csv" -NoTypeInformation -Force
        }
        



#####################################################################
#    Fetching Storage Account Details                               #
#####################################################################

        $storage_account_object = $null
        $storage_account_object = @()

        foreach($azureStorageAccountDetails_Iterator in $azureStorageAccountDetails){
    
            # Populating the cells

            $storage_account_object_temp = new-object PSObject

            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "ResourceGroupName" -Value $azureStorageAccountDetails_Iterator.ResourceGroupName
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "StorageAccountName" -Value $azureStorageAccountDetails_Iterator.StorageAccountName
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "Location" -Value $azureStorageAccountDetails_Iterator.Location
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "StorageTier" -Value $azureStorageAccountDetails_Iterator.Sku.Tier
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "ReplicationType" -Value $azureStorageAccountDetails_Iterator.Sku.Name

            
        
            # Setting the pointer to the next row and first column
            $storage_account_object += $storage_account_object_temp
    }

    $storage_account_object | Export-Csv "Storage_Account_Details.csv" -NoTypeInformation -Force



#####################################################################
#    Fetching Virtual Network Details                               #
#####################################################################

            $virtual_network_object = $null
            $virtual_network_object = @()

            foreach($azureVirtualNetworkDetails_Iterator in $azureVirtualNetworkDetails){
            
            $virtual_network_object_temp = New-Object PSObject

            # Populating the cells

            $virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name "ResourceGroupName" -Value $azureVirtualNetworkDetails_Iterator.ResourceGroupName
            $virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name "Location" -Value $azureVirtualNetworkDetails_Iterator.Location
            $virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name "VNETName" -Value $azureVirtualNetworkDetails_Iterator.Name
            #$virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name "AddressSpace" -Value $azureVirtualNetworkDetails_Iterator.AddressSpace.AddressPrefixes


            
            #$VirtualNetworkWorksheet.Cells.Item($row_counter,$column_counter++) = $azureVirtualNetworkDetails[$vnet_iterator].DhcpOptions.ToString()

            $subnetPerVNET = $azureVirtualNetworkDetails_Iterator.Subnets
            $subnet_count = 1
            foreach($subnetPerVNET_Iterator in $subnetPerVNET) {
                $subnet_name = "Subnet"+$subnet_count
                $subnet_address_space = "SubnetAddressSpace"+$subnet_count
                $virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name $subnet_name -Value $subnetPerVNET_Iterator.Name
                [String]$virtual_network_object_temp | Add-Member -MemberType NoteProperty -Name $subnet_address_space -Value $subnetPerVNET_Iterator.AddressPrefix
                $subnet_count += 1
                #$virtual_network_object += $virtual_network_object_temp
                
            }
         
            # Setting the pointer to the next row and first column
            $virtual_network_object += $virtual_network_object_temp
        }

        $virtual_network_object | Export-Csv "Virtual_networks_details.csv" -NoTypeInformation -Force



#####################################################################
#    Fetching External Load Balancer Details                        #
#####################################################################

# Iterating over the External Load Balancer List

        $azure_load_balancer_object = $null
        $azure_load_balancer_object = @()

        foreach($AzureLBList_Iterator in $AzureLBList){

        # Populating the cells

            $azure_load_balancer_object_temp = new-object PSObject

            $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name "ResourceGroupName" -Value $AzureLBList_Iterator.ResourceGroupName
            $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name "Name" -Value $AzureLBList_Iterator.Name
            $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name "Location" -Value $AzureLBList_Iterator.Location
            $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name "FrontendIpConfigurationsName" -Value $AzureLBList_Iterator.FrontendIpConfigurations.name
            $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name "BackendAddressPoolsName" -Value $AzureLBList_Iterator.BackendAddressPools.name


            # Back End VM List
            $AzureLBBackendPoolVMs = $AzureLBList_Iterator.BackendAddressPools.BackendIpConfigurations

            # Proceed only if $ExternalLBBackendPoolVMs array has data.
            if($AzureLBBackendPoolVMs.count -ne $NULL){

                $AzureLBBackendPoolVMsID_count = 1
                foreach($AzureLBBackendPoolVMs_Iterator in $AzureLBBackendPoolVMs) {
                    #$column_counter = 6

                    if ($null -eq $AzureLBBackendPoolVMs_Iterator) {
                        
                        continue

                    }
                    
                    $AzureLBBackendPoolVMsID_name = "AzureLBBackendPoolVMsID"+$AzureLBBackendPoolVMsID_count
                    $azure_load_balancer_object_temp | add-member -MemberType NoteProperty -Name $AzureLBBackendPoolVMsID_name -Value $AzureLBBackendPoolVMs_Iterator.id
                    $AzureLBBackendPoolVMsID_count += 1
                }

            }

            $azure_load_balancer_object += $azure_load_balancer_object_temp
          
        }

        $azure_load_balancer_object | Export-Csv "Azure_Load_Balancer_details.csv" -NoTypeInformation -Force

}

Invoke-GetAzureInventoryFunction
