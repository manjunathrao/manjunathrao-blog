
#          Script: Azure Inventory Script                                           
#            Date: December 04, 2017                                                                      
#          Author: Manjunath
#                                
#                                                                                                               
#                                                                                   
#  Note: This script expects you are using Powershell 4.0 and higher. Also, you have MSOffice
#        application installed.                                                    
#
#
#####################################################################################

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

try{
# Create an Excel COM Object
$excel = New-Object -ComObject excel.application
}catch{
    Write-Host "Something went wrong in creating excel. Make sure you have MSOffice installed to access MSExcel. Please try running the script again. `n" -ForegroundColor Yellow
}


# Create a Workbook
$workbook = $excel.Workbooks.Add()

# Creating a directory, overrides if any directory exists with the same name
Write-Host "Creating a directory: C:\AzureInventory_Paas. This operation will override if you have a directory with the same name. `n" -ForegroundColor Yellow
New-Item C:\AzureInventory_Paas -Type Directory -Force

# Fetch the list of Azure CDN profiles
$azure_cdn_profile_list = Get-AzureRmCdnProfile

# Fetch the list of Azure webapps
$azure_web_apps_list = Get-AzureRmWebApp

#####################################################################
#    Function to create CDN Endpoint Worksheet                      #
#####################################################################

function Create-AzureCDNEndpointWorksheet {

  

        Write-Host "Creating the Azure CDN Endpoint Worksheet..." -ForegroundColor Green

        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the "Virtual Machine" worksheet and naming it
        $Azure_CDN_Endpoint_worksheet = $workbook.Worksheets.Item(1)
        $Azure_CDN_Endpoint_worksheet.Name = 'CDN Endpoint'


                # Headers for the worksheet
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,1) = 'Resource Group Name'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,2) = 'Name'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,3) = 'Location'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,4) = 'ProfileName'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,5) = 'HostName'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,6) = 'Origin Host Header'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,7) = 'Resource State'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,8) = 'Provisioning State'
        $Azure_CDN_Endpoint_worksheet.Cells.Item(1,9) = 'Tags'

        

        # Cell Counter
        $row_counter = 3
        $column_counter = 1

        foreach($azure_cdn_profile_list_iterator in $azure_cdn_profile_list){
            $cdn_endpoint = Get-AzureRmCdnEndpoint -ProfileName $azure_cdn_profile_list_iterator.Name -ResourceGroupName $azure_cdn_profile_list_iterator.ResourceGroupName

            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.ResourceGroupName
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.Name
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.Location
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.ProfileName
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.HostName
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.OriginHostHeader
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.ResourceState
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.ProvisioningState
            $Azure_CDN_Endpoint_worksheet.Cells.Item($row_counter,$column_counter++) = $cdn_endpoint.Tags

            $row_counter = $row_counter + 1
            $column_counter = 1
    }
    
}


#####################################################################
#    Function to create Azure Web Apps Worksheet                    #
#####################################################################

function Create-AzureWebAppsWorksheet {

   

        Write-Host "Creating the Azure Web Apps Worksheet..." -ForegroundColor Green

        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the "Virtual Machine" worksheet and naming it
        $Azure_Web_Apps_worksheet = $workbook.Worksheets.Item(1)
        $Azure_Web_Apps_worksheet.Name = 'Web Apps'


                # Headers for the worksheet
        $Azure_Web_Apps_worksheet.Cells.Item(1,1) = 'Resource Group Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,2) = 'Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,3) = 'Location'
        $Azure_Web_Apps_worksheet.Cells.Item(1,4) = 'Type'
        $Azure_Web_Apps_worksheet.Cells.Item(1,5) = 'Site Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,6) = 'State'
        $Azure_Web_Apps_worksheet.Cells.Item(1,7) = 'Host Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,8) = 'Repository Site Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,9) = 'Usage State'
        $Azure_Web_Apps_worksheet.Cells.Item(1,10) = 'Enabled Host Names'
        $Azure_Web_Apps_worksheet.Cells.Item(1,11) = 'Outbound IP Address'
        $Azure_Web_Apps_worksheet.Cells.Item(1,12) = 'Default Host Name'
        $Azure_Web_Apps_worksheet.Cells.Item(1,13) = 'Tags'

        

        # Cell Counter
        $row_counter = 3
        $column_counter = 1

       foreach($azure_web_apps_list_iterator in $azure_web_apps_list){

       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.ResourceGroup
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.Name
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.Location
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.Type
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.sitename
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.state
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.hostnames
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.RepositorySiteName
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.UsageState
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.EnabledHostNames
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.OutboundIpAddresses
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.DefaultHostName
       $Azure_Web_Apps_worksheet.Cells.Item($row_counter,$column_counter++) = $azure_web_apps_list_iterator.Tags
       

       $row_counter = $row_counter + 1
       $column_counter = 1
    }
    
}

# Calling Functions
Create-AzureCDNEndpointWorksheet
Create-AzureWebAppsWorksheet


# Checking if the Inventory_Paas.xlsx already exists
if(Test-Path C:\AzureInventory_Paas\Inventory_Paas.xlsx){
    Write-Host "C:\AzureInventory_Paas\Inventory_Paas.xlsx already exitst. Deleting the current file and creating a new one. `n" -ForegroundColor Yellow
    Remove-Item C:\AzureInventory_Paas\Inventory_Paas.xlsx
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AzureInventory_Paas\Inventory_Paas.xlsx")
}else {
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AzureInventory_Paas\Inventory_Paas.xlsx")
}


Write-Host "File is saved as - C:\AzureInventory\Inventory_Paas.xlsx `n" -ForegroundColor Green

# Prompting the user if he/she wants to open the Inventory sheet.
$openExcelFlag = Read-Host "Type YES to open the Inventory sheet. Type NO to quit."
if($openExcelFlag -eq 'YES' -or $openExcelFlag -eq 'yes' -or $openExcelFlag -eq 'y') {
    Invoke-Item C:\AzureInventory_Paas\Inventory_Paas.xlsx
        # Removing the lock on the file
        $excel.Quit()
}else {
    # Removing the lock on the file
    $excel.Quit()
}
