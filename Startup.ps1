  
param (
  
    [string]$username,
    [string]$password
)

Start-Transcript -Path "C:\amt\transcript.txt" -NoClobber
Invoke-Expression "C:\\AMT\\SetAccountAsService.ps1 -adminname $username" -Verbose
Invoke-Expression "C:\\AMT\\FixSettings.ps1" -Verbose
Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password" -Verbose
Invoke-Expression "C:\\AMT\\InstallAmt_AzureMarket.ps1" -Verbose
Stop-Transcript
