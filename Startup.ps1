param (
  
    [string]$username,
    [string]$password
)

Invoke-Expression "C:\\AMT\\deploy_Sql_Express_choco.ps1 -adminpassword $password"
Invoke-Expression "C:\\AMT\\DeployCobol.ps1  -adminname $username -adminpassword $password"
     


