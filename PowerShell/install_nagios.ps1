<#
AUTHOR:
Manjunath Rao

DESCRIPTION: 
This script will install Nagios client in a remote computer

PARAMETERS:
Nagios_MSI_File_Path --> Absolute file path for NSCP-0.4.4.19-x64.msi
Nagios_INI_File_Path --> Absolute file path for nsclient.ini
PrivateIP --> Private IP address of the remote server. If private IP does not work, use HOSTNAME of the remote computer.

PRE-REQUISITES:
This script expects that the servers are to be domain joined with a stable network connection.

EXAMPLE:
.\install_nagios.ps1 -Nagios_MSI_File_Path "C:\IMI_Tools\IM_tls\IM_tls\Nagios for windows\NSCP-0.4.4.19-x64.msi" -Nagios_INI_File_Path "C:\IMI_Tools\IM_tls\IM_tls\Nagios for windows\nsclient.ini" -PrivateIP NG-SERVER-1

#>

param(
    [Parameter (Mandatory = $true)][String]$Nagios_MSI_File_Path,
    [Parameter (Mandatory = $true)][String]$Nagios_INI_File_Path,
    [Parameter (Mandatory = $true)][String]$PrivateIP
)

#$ErrorActionPreference = 'silentlycontinue'

# Setting up the log file
$Loc = Get-Location
$Date = Get-Date -format yyyyMMdd_hhmmsstt
$logfile = $Loc.path + “\log_”+"$PrivateIP" + "_" + $Date + “.txt”
Write-Host 'The log file path: ' $logfile -ForegroundColor Green

####### Function to write informationn to log file #######
function log($string, $color){

    if ($Color -eq $null) {$color = “white”}
    write-host $string -foregroundcolor $color
    $temp = “: ” + $string
    $string = Get-Date -format “yyyy.MM.dd hh:mm:ss tt”
    $string += $temp
    $string | out-file -Filepath $logfile -append
}


function install_nagios() {

    log "Checking if the input paths for NSCP-0.4.4.19-x64.msi and nsclient.ini exists" -color cyan

    if(!(Test-Path $Nagios_MSI_File_Path)) {
        log "Absolute path for NSCP-0.4.4.19-x64.msi is incorrect. Please provide the correct path and retry. Exiting the script" -color red
        exit
    }

    if(!(Test-Path $Nagios_INI_File_Path)) {
        log "Absolute path for nsclient.ini is incorrect. Please provide the correct path and retry. Exiting the script" -color red
        exit
    }

    log "We are installing Nagios client on mentioned server: " -color cyan

    $destination_path = "\\"+ $PrivateIP + "\c$\"

    # Enabling trust between this server and the remote server
    log "Enabling trust between this server and the remote server" -color cyan
    Set-Item WSMan:\localhost\Client\TrustedHosts –Value $PrivateIP -Force
    Get-Item WSMan:\localhost\Client\TrustedHosts |Format-List

    log "Copying NsClient MSI file from current server to remote server"
    copy-item -Path $Nagios_MSI_File_Path -Destination $destination_path

    log "Copying nsclient.ini from curent server to remote server"
    Copy-Item -Path $Nagios_INI_File_Path -Destination $destination_path

    <#
    log "Creating the destination Nagios MSI file Path"
    # Creating the destination Nagios MSI file Path
    $nagios_msi_file_name_array = $Nagios_MSI_File_Path.Split("\")
    $nagios_msi_file_name = $nagios_msi_file_name_array[-1]
    $destination_nagios_msi_file_path = $destination_path + $nagios_msi_file_name

    log "Creating the destinaton Nagios INI File"
    # Creating the destinaton Nagios INI File
    $nagios_ini_file_name_array = $Nagios_INI_File_Path.Split("\")
    $nagios_ini_file_name = $nagios_ini_file_name_array[-1]
    $destination_nagios_ini_file_path = $destination_path + $nagios_ini_file_name
    #>

    
    log "Executing Invoke-Command cmdlet to install nagios client" -color cyan
    $service_result = invoke-command -computername $PrivateIP -ScriptBlock { 
        # Silent installation of Nsclient MSI file
        powershell.exe msiexec /quiet /i "C:\NSCP-0.4.4.19-x64.msi"

        # Copying the nsclient.ini file to the installed directory
        copy-item -Path "c:\nsclient.ini" -Destination "C:\Program Files\NSClient++\"

        # Confirming if the nscp client is running
        get-service -name nscp | select status, name
        
    }

    log "Below is the status of nscp client:" -color cyan
    log "------------------------------------" -color cyan
    log $service_result

    

}

# Calling function
install_nagios