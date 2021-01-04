<#

Author: 
Manjunath

Date: 
December 11, 2017

Pre-Requisites:
This script needs 'MSOnline' and 'AzureRM' PowerShell modules


Import-Module MSOnline --> Run this cmdlet to install the 'MSOnline' cmdlet

#>


try{
# Create an Excel COM Object
$excel = New-Object -ComObject excel.application
}catch{
    Write-Host "Something went wrong in creating excel. Make sure you have MSOffice installed to access MSExcel. Please try running the script again. `n" -ForegroundColor Yellow
}

# Create a Workbook
$workbook = $excel.Workbooks.Add()

# Creating a directory, overrides if any directory exists with the same name
Write-Host "Creating a directory: C:\AzureADUserList. This operation will override if you have a directory with the same name. `n" -ForegroundColor Yellow
New-Item C:\AzureADUserList -Type Directory -Force

## Connect to Msol Service (To access Azure Active Directory)

Connect-MsolService
$users = Get-MsolUser -All

#####################################################################
#    Function to create Azure AD User List Worksheet                #
#####################################################################

function Create-AzureUserListWorksheet {



        Write-Host "Creating the Azure Active Directory User List worksheet..." -ForegroundColor Green
        
        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the "Virtual Machine" worksheet and naming it
        $AzureADUserListWorksheet = $workbook.Worksheets.Item(1)
        $AzureADUserListWorksheet.Name = 'Azure AD User List'


        # Headers for the worksheet
        $AzureADUserListWorksheet.Cells.Item(1,1) = 'User Display Name'
        $AzureADUserListWorksheet.Cells.Item(1,2) = 'User Object ID'
        $AzureADUserListWorksheet.Cells.Item(1,3) = 'User Type'
        $AzureADUserListWorksheet.Cells.Item(1,4) = 'User Principle Name'
        $AzureADUserListWorksheet.Cells.Item(1,5) = 'User Role Name'
        $AzureADUserListWorksheet.Cells.Item(1,6) = 'User Role Description'

        

        # Cell Counter
        $row_counter = 3
        $column_counter = 1

        # Iterating over the Virtual Machines under the subscription
        
        foreach ($users_iterator in $users){

             
            $user_displayname = $users_iterator.displayname
            $user_object_id = $users_iterator.objectid
            $user_type = $users_iterator.UserType
            $user_principal_name = $users_iterator.userprincipalname

            if($user_object_id -ne $null){
                $user_role_name = (Get-MsolUserRole -ObjectId $user_object_id).name
                $user_role_description = (Get-MsolUserRole -ObjectId $user_object_id).Description
            }else{
                $user_role_name = "NULL"
                $user_role_description = "NULL"
            }

            Write-host "Extracting information for user: " $user_displayname

            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_displayname
            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_object_id.tostring()
            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_type
            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_principal_name
            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_role_name
            $AzureADUserListWorksheet.Cells.Item($row_counter,$column_counter++) = $user_role_description

            $row_counter = $row_counter + 1
            $column_counter = 1

        }

    
}

## Calling function
Create-AzureUserListWorksheet


# Checking if the Inventory.xlsx already exists
if(Test-Path C:\AzureADUserList\AzureADUserList.xlsx){
    Write-Host "C:\AzureADUserList\AzureADUserList.xlsx already exitst. Deleting the current file and creating a new one. `n" -ForegroundColor Yellow
    Remove-Item C:\AzureADUserList\AzureADUserList.xlsx
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AzureADUserList\AzureADUserList.xlsx")
}else {
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AzureADUserList\AzureADUserList.xlsx")
}



Write-Host "File is saved as - C:\AzureADUserList\AzureADUserList.xlsx `n" -ForegroundColor Green

# Prompting the user if he/she wants to open the Inventory sheet.
$openExcelFlag = Read-Host "Type YES to open the Inventory sheet. Type NO to quit."
if($openExcelFlag -eq 'YES' -or $openExcelFlag -eq 'yes' -or $openExcelFlag -eq 'y') {
    Invoke-Item C:\AzureADUserList\AzureADUserList.xlsx
        # Removing the lock on the file
        $excel.Quit()
}else {
    # Removing the lock on the file
    $excel.Quit()
}

