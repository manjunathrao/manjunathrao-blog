﻿
<#
This script delete files from IBM COS S3 [Softlayer] which are older than then days specified by $FileAge

EXAMPLE:
.\Delete_S3_files_older_X_days.ps1 -AccessKey xxxxxxxxxxxxxxxxxxxxxx -SecretKey xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -BucketName xxxxxxxxxxxx -IBMS3Endpoint https://syd01.ibmselect.xxxxxx.com -AWSDefaultRegion ap-southasia-2 -FileAge 30

#>

param(
    [String]$AccessKey,
    [String]$SecretKey,
    [String]$BucketName,
    [String]$AWSDefaultRegion,
    [String]$IBMS3Endpoint,
    [Int]$FileAge
)

$ErrorActionPreference = 'silentlycontinue'

# Setting up the log file
$Loc = Get-Location
$Date = Get-Date -format yyyyMMdd_hhmmsstt
$logfile = $Loc.path + “\sync_from_local_to_s3_” + $Date + “.txt”
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

# Flag to track if command failed
$cmdError = $false

try {

log "Verifying the ServerListFilePath"
if(!(Test-Path $InputPath)){
    Write-Host "Please specify a text file containing list of files to download."
}

<#
# Set AWS Powershell credentials if necessary
$cmdError = $false
log "Setting AWS Credentials for this session.."
$cmd = "Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -SessionToken 'ThisSessionOnly'"
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -SessionToken 'ThisSessionOnly'
$cmdError = $?

# Set the region 
$cmdError = $false
log "Setting AWS Region.."
$cmd = ""
Set-DefaultAWSRegion $AWSDefaultRegion
$cmdError = $?
 
# Set your profile. Powershell commands against AWS will work in your credentials
$cmdError = $false
log "Setting AWS Profile.."
$cmd = ""
#Set-AWSCredentials -ProfileName manju
$cmdError = $?

#>

# IBM COS S3 Endpoint
$cmdError = $false
$cmd = ""
$endpoint = $IBMS3Endpoint
$cmdError = $?

# Bucket Name
$cmd = ""
$bucket_name = "s3://" + $BucketName
$cmdError = $?

# Setting AWS Configure
log "Setting AWS Configure"
aws configure set default.region $AWSDefaultRegion --profile test
aws configure set aws_access_key_id $AccessKey --profile test
aws configure set aws_secret_access_key $SecretKey --profile test

# AWS CLI command to list the files under bucket
$cmdError = $false
log "Delete files from IBM COS S3 files: "
log "====================================================================================="

# Fetch all the files from the bucket -- the output is an Object[] array
$s3_files_list = aws --endpoint-url $endpoint s3 ls $bucket_name --recursive --human-readable --summarize --profile test

# Iterate through each file
foreach($s3_files_list_iterator in $s3_files_list) {
    # Split the file entry to extrach the "created date" and "file name"
    $s3_files_list_iterator_split_array = $s3_files_list_iterator.split(" ")
    $temp_date_holder = $s3_files_list_iterator_split_array[0]
    # Convert the created date from String format to DataTime format
    $s3_files_list_iterator_date = [datetime]::ParseExact($temp_date_holder, "yyyy-MM-dd", $null)
    $s3_files_list_iterator_file_name = $s3_files_list_iterator_split_array[-1]

    # Get the difference between each file's created date and current date.
    # Subtract the two dates. If the difference is greather than 30 delete the file
    if(($s3_files_list_iterator_date - (Get-date)).days -ge $FileAge){
        log $s3_files_list_iterator_file_name
        # Constructing the file name <S3URI> to delete 
        $file_to_delete = $bucketname + "/" + $s3_files_list_iterator_file_name
        aws --endpoint-url $endpoint s3 rm $file_to_delete --profile test

    }
}
$cmdError = $?

# Un-Setting AWS Configure
log "Un-Setting AWS Configure"
aws configure set default.region ' ' --profile test
aws configure set aws_access_key_id ' ' --profile test
aws configure set aws_secret_access_key ' ' --profile test

}catch{

    if($cmdError -eq $false){
        log "Command that failed was: "
        $cmd | out-file $logfile -Append
    }

}
