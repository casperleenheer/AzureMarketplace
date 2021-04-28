  
param (
  
    [string]$username,
    [string]$password,
    [string]$sqlserver,
    [string]$sqladmin,
    [string]$sqlpassword
    [string[]]$online,
    [string[]]$batch
)

Start-Transcript -Path "C:\amt\transcript.txt" -NoClobber
Invoke-Expression "C:\\AMT\\FixSettings.ps1 -sqlserver $sqlserver" -Verbose
Invoke-Expression "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -Verbose

#Add AMT install script as a run once script during first login.
#New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Setup AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "C:\\AMT\\SetupAmt.ps1 -adminname $username -adminpassword $password -sqladminname $sqladmin -sqladminpassword $sqlpassword" -WindowStyle Normal' -PropertyType "String" 

New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "Install AMT" -Value 'pwsh.exe  -WorkingDirectory C:\AMT -ExecutionPolicy Bypass -File "c:\AMT\InstallAmt_AzureMarket.ps1" -WindowStyle Normal' -PropertyType "String" 
Stop-Transcript
