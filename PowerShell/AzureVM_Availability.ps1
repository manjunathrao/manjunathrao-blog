
# Author: Manjunath
# Date: 22 Febuary 2017

# This script pulls out the current server status of VMs from your Azure subscription.
# It saves the result into Azure table. 
# The script has a polling mechanism. One script execution is one poll, so the second time you execute the script, it will initially fetch the current server status and compare the current sever status with the previous stored status. 
# If it finds any server's stats was changed from RUNNING to STOPPED, it will save the data in a hashtable, which will be then emailed to an email id as specified.




# Loging into Azure Account
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



# Function to Insert entities into the azure table
function Add-Entity() { 
   [CmdletBinding()] 
	
   param( 
      $table, 
      [String]$partitionKey, 
      [String]$rowKey, 
      [String]$servername, 
      [String]$serverstatus
   )  
   
   $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey 
		
   $entity.Properties.Add("ServerName", $servername) 
   $entity.Properties.Add("ServerStatus", $serverstatus) 
   
   $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity)) 
}

# Function to send email - uses SendGrid
# Replace the custom SMTP server if you do not want to choose SendGrid
function Send-Email() {

    Write-Output "Sending an email"
    $Username ="xxxxxxxx@azure.com" # Your user name - found in sendgrid portal
    $Password = ConvertTo-SecureString "<SendGrid_Password" -AsPlainText -Force # SendGrid Password
    $credential = New-Object System.Management.Automation.PSCredential $Username, $Password
    $SMTPServer = "smtp.sendgrid.net"
    $EmailFrom = "FromAddress@domain.com"
    $EmailTo = "ToAddress@domain.com"
    $Subject = "List of Stopped VMs"
    $Body = "Below are the list of Stopped VMs `n`n" + $finalResult


    Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $EmailTo -subject $Subject -Body $Body

}

# Table to store the current server status
$TempTableName = "ServerStatusTempTable"

# Table to store the server status for compararision
$ReferenceTableName = "ServerStatusReferenceTable"

# Storage account information
$StorageAccountName = "<Azure_Storage_Account_Name>" # FQDN not required
$StorageAccountKey = "xxxxxxxxxxxxxxxxxxxxxxxxxx" # Azure storage account access key
$Ctx = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey

# Check if the temp table exists. If it exists, delete it. We want a new one for each execution
if(Get-AzureStorageTable -Name $TempTableName -Context $Ctx -ErrorAction SilentlyContinue) {
    Remove-AzureStorageTable -Name $TempTableName -Context $Ctx -Force
    Start-Sleep -Seconds 45 #By default, we have to wait 40 seconds, before we create a table with the same name that was deleted.
    
}

# Temp table has to be created for each execution. If it exists, delete it and recreate it
New-AzureStorageTable –Name $TempTableName –Context $Ctx

$TempTable = Get-AzureStorageTable –Name $TempTableName -Context $Ctx -ErrorAction Ignore 


# Collecting the CURRENT server status and uploading it into the ServerStatusTempTable
$rowcounter = 1
$RGs = Get-AzureRMResourceGroup
                              foreach($RG in $RGs)
                              {
                                  $VMs = Get-AzureRmVM -ResourceGroupName $RG.ResourceGroupName
                                  foreach($VM in $VMs)
                                  {
                                      $VMDetail = Get-AzureRmVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status
                                      foreach ($VMStatus in $VMDetail.Statuses)
                                      { 
                                          
                                              $VMStatusDetail = $VMStatus.DisplayStatus
                                              
                                          
                                      }
                                      $name = $RG.ResourceGroupName + " - " + $VM.Name.ToString()
                                      Add-Entity -Table $TempTable -PartitionKey Partition1 -RowKey $rowcounter -servername $name -serverstatus $VMStatusDetail
                                      $rowcounter++
                                  }
                              }



# Compare the two tables

$StorageAccountName = "<Azure_Storage_Account_Name>" # FQDN not required
$StorageAccountKey = "xxxxxxxxxxxxxxxxxxxxxxxxxx" # Azure storage account access key
$Ctx = New-AzureStorageContext –StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#Get a reference to a table. 
$TempTable = Get-AzureStorageTable –Name $TempTableName -Context $Ctx  

#Create a table query. 
$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

#Define columns to select. 
$list = New-Object System.Collections.Generic.List[string] 
$list.Add("RowKey") 
$list.Add("ServerName") 
$list.Add("ServerStatus") 
  
#Set query details. 

$query.SelectColumns = $list 
$query.TakeCount = 100 # Change this value if the client has more than 100 Virtual Machines

#Get Temp table Context
$TempTable = Get-AzureStorageTable –Name $TempTableName -Context $Ctx -ErrorAction Ignore 

#Get Reverence Table context
$ReferenceTable = Get-AzureStorageTable –Name $ReferenceTableName -Context $Ctx -ErrorAction Ignore 


#Obtain Temp table details
$tempEntities = $TempTable.CloudTable.ExecuteQuery($query)

#Obtain Reference table details
$referenceEntities = $ReferenceTable.CloudTable.ExecuteQuery($query)

#Create hashtable to store vm details if the status has changed from Running to Stopped
$listStatusChangedServers = @{}

foreach($tempEntitiesIterator in $tempEntities){
    foreach($referenceEntitiesIterator in $referenceEntities) {
        if($tempEntitiesIterator.Properties["ServerName"].StringValue -eq $referenceEntitiesIterator.Properties["ServerName"].StringValue){
            if(($referenceEntitiesIterator.Properties["ServerStatus"].StringValue -eq "VM running") -and ($tempEntitiesIterator.Properties["ServerStatus"].StringValue -eq "VM stopped")) {
            Write-Output $tempEntitiesIterator.Properties["ServerName"].StringValue "  status is Stopped !"
                $listStatusChangedServers.Add($tempEntitiesIterator.Properties["ServerName"].StringValue,$tempEntitiesIterator.Properties["ServerStatus"].StringValue)
            }

            if(($referenceEntitiesIterator.Properties["ServerStatus"].StringValue -eq "VM stopped") -and ($tempEntitiesIterator.Properties["ServerStatus"].StringValue -eq "VM running")) {
            #Write-Output $tempEntitiesIterator.Properties["ServerName"].StringValue "  status is running"
                #$listStatusChangedServers.Add($tempEntitiesIterator.Properties["ServerName"].StringValue,$tempEntitiesIterator.Properties["ServerStatus"].StringValue)
            }
        }
    }
}



# Retrieve the data from the temp table

$rowcounter = 1

$StorageAccountName = "<Azure_Storage_Account_Name>" # FQDN not required
$StorageAccountKey = "xxxxxxxxxxxxxxxxxxxxxxxxxx" # Azure storage account access key
$Ctx = New-AzureStorageContext –StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#Get a reference to a table. 
$TempTable = Get-AzureStorageTable –Name $TempTableName -Context $Ctx  

#Create a table query. 
$query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

#Define columns to select. 
$list = New-Object System.Collections.Generic.List[string] 
$list.Add("RowKey") 
$list.Add("ServerName") 
$list.Add("ServerStatus") 
  
#Set query details. 

$query.SelectColumns = $list 
$query.TakeCount = 100
 
#Execute the query. 
$entities = $TempTable.CloudTable.ExecuteQuery($query)
#$entities
#$entities | select $_.Properties["ServerName"].StringValue
#$entities | select $_.Properties[“ServerStatus”].StringValue

# Check if the temp table exists. If it exists, delete it. We want a new one for each execution
if(Get-AzureStorageTable -Name $ReferenceTableName -Context $Ctx -ErrorAction SilentlyContinue) {
    Remove-AzureStorageTable -Name $ReferenceTableName -Context $Ctx -Force
    Start-Sleep -Seconds 45 #By default, we have to wait 40 seconds, before we create a table with the same name that was deleted.
    
}

# Create the Reference table if it does not exist
New-AzureStorageTable –Name $ReferenceTableName –Context $Ctx -ErrorAction SilentlyContinue


$ReferenceTable = Get-AzureStorageTable –Name $ReferenceTableName -Context $Ctx -ErrorAction Ignore 

 foreach($entity in $entities) {
     $entity.Properties["ServerName"].StringValue
     $entity.Properties["ServerStatus"].StringValue
     Write-Output "  "


     # Storing the temp Table as a permanent one

     Add-Entity -Table $ReferenceTable -PartitionKey Partition1 -RowKey $rowcounter -servername $entity.Properties["ServerName"].StringValue -serverstatus $entity.Properties["ServerStatus"].StringValue
     $rowcounter++
}

#-------------------------------------------------------------------------------

# Converting the hashtable to the string so we can email it
$finalResult = $listStatusChangedServers.GetEnumerator() | ForEach-Object {$_.key} | Out-String

# Send an email using Send Grid, only when we have atleast one VM that is stopped

if($finalResult.Length -gt 0) {
   Send-Email

}
