  
param (
  
    [string]$username,
    [string]$password,
    [string]$sqlserver,
    [string]$sqladmin,
    [string]$sqlpassword,
    [string]$amtSettings,
    [switch]$allinone

)

Start-Transcript -Path "C:\amt\transcript.txt" -NoClobber


Invoke-Expression "C:\\AMT\\FixSettings.ps1 -sqlserver $sqlserver" -Verbose


if (-not $allinone)
{
  #Export of json with template goes wrong. All "" are gone.
  #Doing some replacements to make it json again.
  
  Write-Host "->$amtSettings<-"
  
  $jsonstring = $amtSettings
  $jsonstring = $jsonstring -replace '{', '{"'
  $jsonstring = $jsonstring -replace ':', '":"'
  $jsonstring = $jsonstring -replace '}', '"}'
  $jsonstring = $jsonstring -replace ',', ',"'
  $jsonstring = $jsonstring.Replace(":`"[", ":[")
  $jsonstring = $jsonstring.Replace("}`"}", "}}")
  $jsonstring = $jsonstring.Replace("},`"{", "},{")
  $jsonstring = $jsonstring.Replace(":`"{", ":{")
  $jsonstring = $jsonstring.Replace("}]`"}", "}]}")
  Write-Host "->$jsonstring<-"

  Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -Verbose
  Invoke-Expression "C:\\AMT\\AdjustEnvironmentFile.ps1 -jsonstring $jsonstring" -Verbose
}
else 
{
  Invoke-Expression "C:\\AMT\\SetupAllInOne.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -Verbose
}

#Add AMT install script as a run once script during first login.
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Install AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "c:\AMT\InstallAmt_AzureMarket.ps1" -WindowStyle Normal' -PropertyType "String" 

Stop-Transcript
