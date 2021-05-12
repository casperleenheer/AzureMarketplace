  
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

#Set the sql server name
C:\AMT\FixSettings.ps1 -sqlserver $sqlserver

#There are two flavours: allinone, which has AMT and SQL on one box and flex which has multiple AMT boxes and a seperate SQL server
if (-not $allinone)
{
  $amtSettings | Out-File "C:\AMT\AmtSettings.json"
  $envSettings | Out-File "C:\AMT\EnvSettings.json"
  $value = 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "C:\AMT\AdjustEnvironmentFile.ps1" -jsonstring ' + $amtSettings + ' -WindowStyle Normal -NoExit'
  New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Adjust AMT xml" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "C:\AMT\AdjustEnvironmentFile.ps1" -WindowStyle Normal' -PropertyType "String" 

  C:\AMT\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword

}
else 
{
  Invoke-Expression "C:\\AMT\\SetupAllInOne.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -Verbose
}



#Add AMT install script as a run once script during first login.
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Install AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "c:\AMT\InstallAmt_AzureMarket.ps1" -WindowStyle Normal' -PropertyType "String" 

Stop-Transcript
