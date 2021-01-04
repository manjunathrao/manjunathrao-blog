<#

This script creates AWS Inventory

Author: 
Manjunath Rao

Date: 
6 April 2017

Email: 
manjunathrao25@live.com

Microsft Script Center Profile: 
https://social.technet.microsoft.com/profile/manjunath%20rao%20g/

Blogsite: 
https://manjunathrao.com/

#>

Write-Host "----- Pre Requisites -----`n" -ForegroundColor Yellow
Write-Host "1. Make sure you have AWS tools for Powershell installed. You can download the same at: https://aws.amazon.com/powershell/ `n" -ForegroundColor Yellow
Write-Host "2. Set up AWSpowershell modules. Getting started link: http://docs.aws.amazon.com/powershell/latest/userguide/ `n" -ForegroundColor Yellow
Write-Host "3. Enable execution policy accordingly. Set it to either RemoteSigned OR Unrestricted `n`n" -ForegroundColor Yellow

# Declaring variables
$AWS_AccessKey = <Enter_Your_AWS_AccessKey>
$AWS_SecretKey = <Enter_Your_AWS_SecretKey>

# Create a Workbook
$workbook = $excel.Workbooks.Add()

# creating a variable to contain the AWS Regions
$Global:AWS_Locations = @("ap-northeast-1","ap-northeast-2","ap-south-1", "ap-southeast-1", "ap-southeast-2", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "sa-east-1", "us-east-1", "us-east-2", "us-west-1", "us-west-2")

# Creating a directory, overrides if any directory exists with the same name
Write-Host "Creating a directory: C:\AWSInventory. This operation will override if you have a directory with the same name. `n" -ForegroundColor Yellow
New-Item C:\AWSInventory -Type Directory -Force

# We will encounter exceptions while running methods on a null-valued expression. This is expected. So it is safe to ignore them.
$ErrorActionPreference = "SilentlyContinue"


# Setting the AWS credentials
Set-AWSCredentials -AccessKey $AWS_AccessKey -SecretKey $AWS_SecretKey -StoreAs myawsprofile

# Setting the profile, so we can execute the cmdlets
Set-AWSCredentials -ProfileName myawsprofile 

# Creating EXCEL object
$excel = New-Object -ComObject excel.application



# Function to creat the EC2 Instance worksheet
function Create-EC2InstanceWorksheet {

        Write-Host "Creating EC2 Instances Worksheet..`n`n" -ForegroundColor Green

        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the worksheet for Virtual Machine
        $VirtualMachineWorksheet = $workbook.Worksheets.Item(1)
        $VirtualMachineWorksheet.Name = 'VirtualMachine'

        # Headers for the worksheet
        $VirtualMachineWorksheet.Cells.Item(1,1) = 'Region'
        $VirtualMachineWorksheet.Cells.Item(1,2) = 'VM Name'
        $VirtualMachineWorksheet.Cells.Item(1,3) = 'VM Image ID'
        $VirtualMachineWorksheet.Cells.Item(1,4) = 'VM Instance ID'
        $VirtualMachineWorksheet.Cells.Item(1,5) = 'VM Instance Type'
        $VirtualMachineWorksheet.Cells.Item(1,6) = 'VM Private IP'
        $VirtualMachineWorksheet.Cells.Item(1,7) = 'VM Public IP'
        $VirtualMachineWorksheet.Cells.Item(1,8) = 'VM VPC ID'
        $VirtualMachineWorksheet.Cells.Item(1,9) = 'VM Subnet ID'
        $VirtualMachineWorksheet.Cells.Item(1,10) = 'VM State'
        $VirtualMachineWorksheet.Cells.Item(1,11) = 'VM Security Group Id'
        
        # Excel Cell Counter
        $row_counter = 3
        $column_counter = 1


    # Get the Ec2 instances for each region
    foreach($AWS_Locations_Iterator in $AWS_Locations){
        $EC2Instances = Get-EC2Instance -Region $AWS_Locations_Iterator

        # Iterating over each instance
        foreach($EC2Instances_Iterator in $EC2Instances){
            
            # Ignore if a region does not have any instances
            if($EC2Instances_Iterator.count -eq $null) {
            continue
            }
            # Populating the cells
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $AWS_Locations_Iterator
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.keyname.tostring()
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.imageid
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.Instanceid
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.Instancetype.Value
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.PrivateIpAddress
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.PublicIpAddress
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.vpcid
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.SubnetId
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.state.name.value
            $VirtualMachineWorksheet.Cells.Item($row_counter,$column_counter++) = $EC2Instances_Iterator.Instances.securitygroups.GroupId

            # Seting the row and column counter for next EC2 instance entry
            $row_counter = $row_counter + 1
            $column_counter = 1
        }

        # Iterating to the next region
        $row_counter = $row_counter + 3
    }

}


# Function to create EC2 VPC Worksheet
function Create-EC2VPCWorksheet {

        Write-Host "Creating EC2 VPC Worksheet..`n`n" -ForegroundColor Green

        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the worksheet for VPC
        $Ec2_VPC_Worksheet = $workbook.Worksheets.Item(1) 
        $Ec2_VPC_Worksheet.Name = 'VPC'

        # Headers for the worksheet
        $Ec2_VPC_Worksheet.Cells.Item(1,1) = 'Region'
        $Ec2_VPC_Worksheet.Cells.Item(1,2) = 'VPC ID'
        $Ec2_VPC_Worksheet.Cells.Item(1,3) = 'VPC CIDR'
        $Ec2_VPC_Worksheet.Cells.Item(1,4) = 'VPC State'

        # Excel Cell Counter
        $row_counter = 3
        $column_counter = 1

        # Get the AWS VPC for each region
        foreach($AWS_Locations_Iterator in $AWS_Locations){
        $EC2_VPCs = Get-EC2Vpc -Region $AWS_Locations_Iterator


        # Iterate over each VPC in a region
        foreach($EC2_VPCs_Iterator in $EC2_VPCs){
        # Populating the cells
            $Ec2_VPC_Worksheet.Cells.Item($row_counter,$column_counter++) = $AWS_Locations_Iterator
            $Ec2_VPC_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_VPCs_Iterator.VpcId.toString()
            $Ec2_VPC_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_VPCs_Iterator.CidrBlock.toString()
            $Ec2_VPC_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_VPCs_Iterator.State.Value.toString()

            # Seting the row and column counter for next EC2 VPC entry
            $row_counter = $row_counter + 1
            $column_counter = 1
        }

        # Iterating to the next region
        $row_counter = $row_counter + 3
    }

}



function Create-EC2SubnetWorksheet {

        Write-Host "Creating EC2 Subnet Worksheet..`n`n" -ForegroundColor Green
    
        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the worksheet for Subnet
        $Ec2_Subnet_Worksheet = $workbook.Worksheets.Item(1)
        $Ec2_Subnet_Worksheet.Name = 'Subnet'

        # Headers for the worksheet
        $Ec2_Subnet_Worksheet.Cells.Item(1,1) = 'Region'
        $Ec2_Subnet_Worksheet.Cells.Item(1,2) = 'Subnet ID'
        $Ec2_Subnet_Worksheet.Cells.Item(1,3) = 'VPC ID'
        $Ec2_Subnet_Worksheet.Cells.Item(1,4) = 'Subnet CIDR'
        $Ec2_Subnet_Worksheet.Cells.Item(1,5) = 'Available IP Address Count'
        $Ec2_Subnet_Worksheet.Cells.Item(1,6) = 'State'
        $Ec2_Subnet_Worksheet.Cells.Item(1,7) = 'Availability Zone'


        # Cell Counter
        $row_counter = 3
        $column_counter = 1

        # Get the AWS VPC for each region

        foreach($AWS_Locations_Iterator in $AWS_Locations){
        $EC2_Subnets = Get-EC2Subnet -Region $AWS_Locations_Iterator



        foreach($EC2_Subnets_Iterator in $EC2_Subnets){
        # Populating the cells
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $AWS_Locations_Iterator
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.SubnetId.toString()
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.VpcId.toString()
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.CidrBlock.toString()
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.AvailableIpAddressCount.toString()
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.SubnetState.Value.toString()
            $Ec2_Subnet_Worksheet.Cells.Item($row_counter,$column_counter++) = $EC2_Subnets_Iterator.AvailabilityZone.toString()
            
            # Seting the row and column counter for next EC2 subnet entry
            $row_counter = $row_counter + 1
            $column_counter = 1
        }

        # Iterating to the next region
        $row_counter = $row_counter + 3
    }
}


function Create-S3BucketWorksheet {

        Write-Host "Creating S3 Bucket Worksheet..`n`n" -ForegroundColor Green

        # Adding worksheet
        $workbook.Worksheets.Add()

        # Creating the "Virtual Machine" worksheet and naming it
        $S3_Bucket_Worksheet = $workbook.Worksheets.Item(1)
        $S3_Bucket_Worksheet.Name = 'S3 Bucket'

        # Headers for the worksheet
        $S3_Bucket_Worksheet.Cells.Item(1,1) = 'Region'
        $S3_Bucket_Worksheet.Cells.Item(1,2) = 'Creation Date'
        $S3_Bucket_Worksheet.Cells.Item(1,3) = 'Bucket name'

        # Cell Counter
        $row_counter = 3
        $column_counter = 1

        # Get the AWS VPC for each region
        foreach($AWS_Locations_Iterator in $AWS_Locations){
        $S3_BucketList = Get-S3Bucket -Region $AWS_Locations_Iterator

        foreach($S3_BucketList_Iterator in $S3_BucketList){
        # Populating the cells
            $S3_Bucket_Worksheet.Cells.Item($row_counter,$column_counter++) = $AWS_Locations_Iterator
            $S3_Bucket_Worksheet.Cells.Item($row_counter,$column_counter++) = get-date ($S3_BucketList_Iterator.CreationDate) -Format g  # Formating the dateTime object to a more readable format
            $S3_Bucket_Worksheet.Cells.Item($row_counter,$column_counter++) = $S3_BucketList_Iterator.BucketName
   
            
            # Seting the row and column counter for next S3 bucket entry
            $row_counter = $row_counter + 1
            $column_counter = 1
        }

        # Iterating to the next region
        $row_counter = $row_counter + 3
    }
}


# Calling functions
Create-S3BucketWorksheet
Create-EC2SubnetWorksheet
Create-EC2VPCWorksheet
Create-EC2InstanceWorksheet


# Checking if the AWSInventory.xlsx already exists
if(Test-Path C:\AWSInventory\Inventory.xlsx){
    Write-Host "C:\AWSInventory\AWSInventory.xlsx already exitst. Deleting the current file and creating a new one. `n" -ForegroundColor Yellow
    Remove-Item C:\AWSInventory\AWSInventory.xlsx
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AWSInventory\AWSInventory.xlsx")
}else {
    # Saving the workbook/excel file
    $workbook.SaveAs("C:\AWSInventory\AWSInventory.xlsx")
}

Write-Host "File is saved as - C:\AWSInventory\AWSInventory.xlsx `n" -ForegroundColor Green

# Prompting the user if he/she wants to open the Inventory sheet.
$openExcelFlag = Read-Host "Type YES to open the Inventory sheet. Type NO to quit."
if($openExcelFlag -eq 'YES' -or $openExcelFlag -eq 'yes' -or $openExcelFlag -eq 'y') {
    Invoke-Item C:\AWSInventory\AWSInventory.xlsx
        # Removing the lock on the file
        $excel.Quit()
}else {
    # Removing the lock on the file
    $excel.Quit()
}