param (
  
    [string]$username,
    [string]$password
)

Invoke-Expression "C:\\AMT\\DeployCobol.ps1  -adminname $username -adminpassword $password"
     


