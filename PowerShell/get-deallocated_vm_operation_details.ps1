<#
AUTHOR:
Manjunath (manjunathrao25@gmail.com)

DESCRIPTION:
Fetch information of certain Azure operation against Azure resources and create a CSV file.

Specifically, this script will create a CSV file that contains list of Azure operations that de-allocates an azure virtual machine.

#>


$log = $null
$log= @()



$log_list_detailed = Get-AzureRmLog -StartTime (Get-Date).AddDays(-2) -EndTime (Get-Date)

foreach($log_list_detailed_iterator in $log_list_detailed){

    if($log_list_detailed_iterator.Authorization.action -eq 'Microsoft.Compute/virtualMachines/deallocate/action' -and $log_list_detailed_iterator.Level -eq 'Informational'){

        
        $resource_id = $log_list_detailed_iterator.id.Split("/")
        $vm_name = $resource_id[8]
        $log_temp = new-object PSObject 
        $log_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $log_list_detailed_iterator.ResourceGroupName
        $log_temp | add-member -membertype NoteProperty -name "VM_name" -Value $vm_name
        $log_temp | add-member -membertype NoteProperty -name "TimeStamp" -Value $log_list_detailed_iterator.EventTimestamp
        $log_temp | add-member -membertype NoteProperty -name "caller" -Value $log_list_detailed_iterator.caller
        $log_temp | add-member -membertype NoteProperty -name "Operation" -Value $log_list_detailed_iterator.Authorization.action
        

        $log += $log_temp

    }
    
}


$log | export-csv "Azure_activity_logs.csv" -NoTypeInformation