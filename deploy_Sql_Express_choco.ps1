param([string]$adminpassword)

mkdir C:\TEMP -ErrorAction SilentlyContinue
$env:TEMP = "C:\\TEMP"
$env:TMP = "C:\\TEMP"
$InstallDir="C:\\choco"
$env:ChocolateyInstall=$InstallDir
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install mssqlserver2016expressadv --ia "/QUIET /IACCEPTSQLSERVERLICENSETERMS /IACCEPTROPENLICENSETERMS /ACTION=install /ADDCURRENTUSERASSQLADMIN /SAPWD=$adminpassword  /INSTANCEID=SQLEXPRESS /INSTANCENAME=SQLEXPRESS /SECURITYMODE=SQL /SQLBACKUPDIR=`"C:\SqlBackup`" /SQLUSERDBDIR=`"C:\SqlData`" /INSTALLSQLDATADIR=`"C:\SqlData`" /SQLUSERDBLOGDIR=`"C:\SqlLogs`" /SQLCOLLATION=Latin1_General_BIN /UPDATEENABLED=FALSE /FEATURES=SQL" -o -y --no-progress

