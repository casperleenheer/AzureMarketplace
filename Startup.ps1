  
param (
  
    [string]$username,
    [string]$password,
    [string]$sqlserver
)

Start-Transcript -Path "C:\amt\transcript.txt" -NoClobber
Invoke-Expression "C:\\AMT\\SetAccountAsService.ps1 -adminname $username" -Verbose
Invoke-Expression "C:\\AMT\\FixSettings.ps1" -sqlserver $sqlserver -Verbose
Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password" -Verbose
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Install AMT" -Value 'Powershell.exe -ExecutionPolicy Bypass -File "c:\AMT\InstallAmt_AzureMarket.ps1" -WindowStyle Normal' -PropertyType "String" 

#Invoke-Expression "C:\\AMT\\InstallAmt_AzureMarket.ps1" -Verbose
Stop-Transcript
