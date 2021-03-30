  
param (
  
    [string]$username,
    [string]$password
)

Invoke-Expression "C:\\AMT\\SetAccountAsService.ps1 -adminpassword $password" -Verbose
Invoke-Expression "C:\\AMT\\deploy_Sql_Express_installer.ps1 -adminname $username -adminpassword $password" -Verbose
Invoke-Expression "C:\\AMT\\FixSettings.ps1" -Verbose
Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password" -Verbose
Invoke-Expression "C:\\AMT\\InstallAmt_AzureMarket.ps1" -Verbose
