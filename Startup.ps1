  
param (
  
    [string]$username,
    [string]$password
)


Invoke-Expression "C:\\AMT\\deploy_Sql_Express_choco.ps1 -adminpassword `"$password`"" -Verbose
Invoke-Expression "C:\\AMT\\FixGenerator.ps1" -Verbose
Invoke-Expression "C:\\AMT\\DeployCobol.ps1  -adminname $username -adminpassword `"$password`""


