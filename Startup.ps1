  
param (
  
    [string]$username,
    [string]$password,
    [string]$sqlserver,
    [string]$sqladmin,
    [string]$sqlpassword,
    $amtSettings

)

Start-Transcript -Path "C:\amt\transcript.txt" -NoClobber
Write-Host "->$amtSettings<-"


$s = $amtSettings


#Export of json with template goes wrong. All "" are gone.
#Doing some replacements to make it json again.
$s = $s -replace '{', '{"'
$s = $s -replace ':', '":"'
$s = $s -replace '}', '"}'
$s = $s -replace ',', ',"'
$s = $s.Replace(":`"[", ":[")
$s = $s.Replace("}`"}", "}}")
$s = $s.Replace("},`"{", "},{")
$s = $s.Replace(":`"{", ":{")
$s = $s.Replace("}]`"}", "}]}")
Write-Host "->$s<-"

$json = ConvertFrom-Json -InputObject $s -ErrorAction Stop
Write-Host $json

Invoke-Expression "C:\\AMT\\FixSettings.ps1 -sqlserver $sqlserver" -Verbose
Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -Verbose
Invoke-Expression "C:\\AMT\\AdjustEnvironmentFile.ps1 -jsonString $json" -Verbose

#Add AMT install script as a run once script during first login.
#New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Setup AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -WindowStyle Normal' -PropertyType "String" 

New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Install AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "c:\AMT\InstallAmt_AzureMarket.ps1" -WindowStyle Normal' -PropertyType "String" 
Stop-Transcript
