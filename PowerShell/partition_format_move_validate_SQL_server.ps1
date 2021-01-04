<#
Author: Manjunath Rao
Website: https://manjunathrao.com/
Date: September 10, 2017
#>

<#
DESCRIPTION:

This script will do the following:
- Checks the SQL Server version. 'SQLPS' module requires SQL Server version 12 and above.
- The attached partition will be 'RAW' data
- Function 'log' --> This will create a unique log file each time this script is executed.
- Function 'fomatDrive' --> This will format the RAW partition to GPT. Create two partitions, assign the given Drive letters, format them to NTFS.
- Function 'moveTempAndLogDB' --> This will configure the SQL Server's  Temp and Data DB's path to the newly created drives.
- Function 'validateSQLInstanceHealth' --> This will vaildate if the sql server is running properly.
#>

$driveLetterForData = 'R'
$driveLetterForLog = 'S'

## creating the Temp folder to copy all the files
log "creating the Temp folder" -color green
New-Item -ItemType directory -Path C:\Temp -force


# Setting up the log file
$Loc = "C:\Temp"
$Date = Get-Date -format yyyyMMdd_hhmmsstt
$logfile = $Loc + “\Move-Temp_” + $Date + “.txt”
Write-Host 'The log file path: ' $logfile -ForegroundColor Green


function log($string, $color){

    if ($Color -eq $null) {$color = “white”}
    write-host $string -foregroundcolor $color
    $temp = “: ” + $string
    $string = Get-Date -format “yyyy.MM.dd hh:mm:ss tt”
    $string += $temp
    $string | out-file -Filepath $logfile -append
}

## creating the Temp folder to copy all the files
log "creating the Temp folder" -color green
New-Item -ItemType directory -Path C:\Temp -force


# Setting up the log file
$Loc = "C:\Temp"
$Date = Get-Date -format yyyyMMdd_hhmmsstt
$logfile = $Loc + “\Move-Temp_” + $Date + “.txt”
Write-Host 'The log file path: ' $logfile -ForegroundColor Green


#########################################################################################################
# Function to write informationn to log file
#########################################################################################################

## Validate if sqlps module exists. Get and Install if it does not exists

# Checking the installed SQL Server version
$inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
foreach ($i in $inst)
{
   $p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i
   $installedSQLEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Edition
   $installedSqlVersion = (((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Version).Split('.'))[0]
}

if($installedSqlVersion -lt 12) {

    log -string "This script needs SQLPS module. This is installed by default with SQL 2012 and higher versions. If you’re using an older SQL version, you need to download and install the following 3 components in order:

    Microsoft® System CLR Types for Microsoft® SQL Server® 2012 (SQLSysClrTypes.msi)
    Microsoft® SQL Server® 2012 Shared Management Objects (SharedManagementObjects.msi)
    Microsoft® Windows PowerShell Extensions for Microsoft® SQL Server® 2012 (PowerShellTools.msi)" -color yellow
}

#########################################################################################################
# Function to move the Data and Log Tem DB files to a different location
#########################################################################################################
function moveTempAndLogDB() {

    # Creating the directory
    $tempDBDATADirectory = $driveLetterForData + “:\DATA"
    $tempDBLOGDirectory = $driveLetterForLog+“:\LOG"
    New-Item $tempDBDATADirectory -ItemType Directory -Force
    New-Item $tempDBLOGDirectory -ItemType Directory -Force

    $NewTempDBLoc = $tempDBDATADirectory + '\tempdb.mdf'
    $NewTemplogLoc = $tempDBLOGDirectory + '\templog.ldf'

    log -string "New Log location:"
    log -string $tempDBDATADirectory
    log -string $tempDBLOGDirectory

    Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:ComputerName)
    $server.Properties["DefaultFile"].Value = $NewTempDBLoc
    $server.Properties["DefaultLog"].Value = $NewTemplogLoc
    $server.Alter()
    Restart-Service -Force MSSQLSERVER
}


#########################################################################################################
# Function to validate the sql instance helth
#########################################################################################################
function validateSQLInstanceHealth() {

    $server = $env:computername  
    $object = Get-WmiObject win32_service -ComputerName $server  | where {($_.name -like "MSSQL$*" -or $_.name -like "MSSQLSERVER" -or $_.name -like "SQL Server (*") -and $_.name -notlike "*helper*" -and $_.name -notlike "*Launcher*"}
    if ($object)
    {
        log "`nSQL Server instance status:"
        $instInfo= $object |select Name,StartMode,State, Status
        $instInfo
    }else{
        log -string "No instance found!" -color red
    }
}


#########################################################################################################
# Function to Format the Drive
#########################################################################################################
function fomatDrive() {


    $cmdError = $false

    ### Stops the Hardware Detection Service ###
    Stop-Service -Name ShellHWDetection

    ### Grabs all the new RAW disks into a variable ###
    $disk = get-disk | where partitionstyle -eq ‘RAW’

    log "Checking if RAW partition exists"
    ## Quit if no raw partition exists
    if($disk -ne $null) {
        log " RAW partition found." -Color green

        log "Grabbing the first RAW partition"
        $diskNumber = $disk[0].Number

        log "Initializing the disk to GPT"
        get-Disk $diskNumber | Initialize-Disk -PartitionStyle GPT
        log "Sleeping 5 seconds..." -ForegroundColor 
        sleep(5)
        
    } elseif ($disk -eq $null){
        # If RAW partition does not exists. Check if attached NETAPP partition is already initialized to GPT. 
        # If a GPT initialized GPT partition existds, use it.
        log "RAW partition does not exist. Can not proceed with formatting. Exiting the script."
        exit
    }


    log "Fetching the total partition size of the disk"
    $partitionSize = (get-Disk $diskNumber).size


    $partitionSizeForData = $partitionSize/2

    log " Creating the data partition" 
    $dataPartition = New-Partition -DiskNumber $diskNumber -Size $partitionSizeForData -DriveLetter $driveLetterForData

    $partitionSizeForLOG = $partitionSize - (get-disk $diskNumber).AllocatedSize
    log "Creating the LOG partition"
    $logPartition = New-Partition -DiskNumber $diskNumber -Size $partitionSizeForLOG -DriveLetter $driveLetterForLog

    log "Sleeping 5 seconds..." -color Cyan 
    sleep(5)

    log "Formatting the DATA partition as NTFS volume"
    $dataVolume = Format-Volume -driveletter $dataPartition.Driveletter -FileSystem NTFS -NewFileSystemLabel "SQL Data" -Confirm:$false

    log "Sleeping 5 seconds..." -color Cyan
    sleep(5)
    log "Formatting the LOG partition as NTFS volume" 
    $logVolume = Format-Volume -driveletter $logPartition.Driveletter -FileSystem NTFS -NewFileSystemLabel "SQL Log" -Confirm:$false
}

# Calling the functions

fomatDrive
moveTempAndLogDB
validateSQLInstanceHealth
