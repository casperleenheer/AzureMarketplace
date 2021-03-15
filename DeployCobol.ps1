param([string] $adminname, [string]$adminpassword)

using namespace Asysco.Lion.Repository.Model
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-ExecutionPolicy Unrestricted
Get-Module -Name PowerShellGet -ListAvailable | Select-Object -Property Name, Version, Path

Install-Module PowerShellGet -Force

Install-Module Azure -AllowClobber  -Force -InformationAction:SilentlyContinue

Import-Module -Name 'WebAdministration' -Force -DisableNameChecking


Function Execute-AllowAccountToLoginAsAService {
    <#
 

  .PARAMETER accountToAdd
    [String] The AD account that is allowed to run as a service
  #>

    Param (
        [Parameter(Mandatory = $true)]
       
        [string]$accountToAdd

    )

    try {
     

       
	
        ## ---> End of Config
	
        $sidstr = $null
        try {
            $ntprincipal = New-Object System.Security.Principal.NTAccount "$accountToAdd"
            $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
            $sidstr = $sid.Value.ToString()
        }
        catch {
            $sidstr = $null
        }
	
	
        if ([string]::IsNullOrEmpty($sidstr)) {
            Write-Host "Account $($accountToAdd) not found!" -ForegroundColor Red
            exit 1
        }
	
	
        $tmp = [System.IO.Path]::GetTempFileName()
	
        SecEdit.exe /export /cfg "$($tmp)" | Out-Null
	
        $c = Get-Content -Path $tmp
	
        $currentSetting = ""
	
        foreach ($s in $c) {
            if ($s -like "SeServiceLogonRight*") {
                $x = $s.split("=", [System.StringSplitOptions]::RemoveEmptyEntries)
                $currentSetting = $x[1].Trim()
            }
        }
	
        if ($currentSetting -notlike "*$($sidstr)*") {
            Write-Host "Modify Setting ""Logon as a Service""" -ForegroundColor DarkCyan
		
            if ([string]::IsNullOrEmpty($currentSetting)) {
                $currentSetting = "*$($sidstr)"
            }
            else {
                $currentSetting = "*$($sidstr),$($currentSetting)"
            }
		
            Write-Host "$currentSetting"
		
            $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@
		
            $tmp2 = [System.IO.Path]::GetTempFileName()
		
		
            Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
            $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
		
            #notepad.exe $tmp2
            Push-Location (Split-Path $tmp2)
		
            try {
                SecEdit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS
                #write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
            }
            finally {
                Pop-Location
            }
        }
        else {
		
        }
    

    }
    catch {
        Write-Host $_
    }
    finally {
    
    }
} #  Execute-SetAcl

Function CreateLocalAdmin($localAdminName, $localAdminPwd) {



    $group = "Administrators"

    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $existing = $adsi.Children | where { $_.SchemaClassName -eq 'user' -and $_.Name -eq $localAdminName }

    if ($existing -eq $null) {

        Write-Host "Creating new local user $localAdminName."
        & NET USER $localAdminName $localAdminPwd /add /y /expires:never
		
        Write-Host "Adding local user $localAdminName to $group."
        & NET LOCALGROUP $group $localAdminName /add

    }
    else {
        Write-Host "Setting password for existing local user $localAdminName."
        $existing.SetPassword($localAdminPwd)
    }

    Write-Host "Ensuring password for $localAdminName never expires."
    & WMIC USERACCOUNT WHERE "Name='$localAdminName'" SET PasswordExpires=FALSE



}

cd C:\AMT

#Add user to Sql for integrated security
Invoke-Sqlcmd -Username sa -Password $adminpassword -ServerInstance $env:COMPUTERNAME\SQLEXPRESS -InputFile C:\AMT\AddAdmin.sql

.\FixSettings.ps1

#Restore all backups
$bakFiles = Get-ChildItem  -path C:\Amt\SqlBackup -Filter "*.bak"


foreach ($bak in $bakFiles) {
    $dbname = $bak.Name.Replace(".bak", "")
    Restore-SqlDatabase -ServerInstance $env:COMPUTERNAME\SQLEXPRESS -Database $dbname -BackupFile $bak.fullname -ReplaceDatabase -Verbose 
    Start-Sleep -Seconds 20
}


cd C:\amt\Setup


[String]$LionDevPath = "c:\amt\setup\Setup.exe "
if (-Not (Test-Path $LionDevPath)) {
    Throw "[$LionDevPath] does not exist"
}

# Add LionDev arguments
$Arguments = [String]::Empty

$Arguments += "/BATCHINSTALL /BATCHREOREPOS "


Write-Host "Running Setup.exe in Batch mode"
# Passthru parameter is necessary to retrieve the exit code
$Process = Start-Process -FilePath $LionDevPath -ArgumentList $Arguments -Wait -PassThru


try {
    $customDll = "c:\Amt\Lion\LionRepository.dll"
    Add-Type -path $customDll 
}
catch [System.Reflection.ReflectionTypeLoadException] {
    Write-Host "Message: $($_.Exception.Message)"
    Write-Host "StackTrace: $($_.Exception.StackTrace)"
    Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
}




Write-Host "Adding users to LionDev (SEC)"
$lionSources = Get-ChildItem -Path  C:\amt\Source -Filter "*.settings"
$Obj_Module = New-Object LionRepository
$Obj_Repos = $Obj_Module.OpenConnection([LionDatabaseType]::MsSql, "$($env:COMPUTERNAME)\SQLEXPRESS", "asy", "asy", "AMT_REPOS", "", $false, $Application, $true)


$security = $Obj_Repos.GetSecurity();
$groups = $security.ReturnAllGroups()
$users = $adminname
foreach ($user in $users) {

    $NewUser = $security.FindUserByName($user)
    if ($NewUser -eq $null) {
        $NewUser = $security.AddUser($user)
    }
    foreach ($group in $groups) {
        $NewUser.AddGroup($group)

    }
    $NewUser.SaveGroups($Obj_Repos)
}



cd c:\amt

Write-Host "Installing LionDev_Gen as a service"

#Work around for the FixGenerator issue. It now will run after reboot.
$UserName = $env:COMPUTERNAME + "\AMT_ADMIN"
$Password = $adminpassword

Execute-AllowAccountToLoginAsAService -accountToAdd $UserName

cd C:\AMT\Lion



$passwordSec = ConvertTo-SecureString $Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $passwordSec)
$params = @{
    Name           = "LionDevNet_Generator"
    BinaryPathName = "C:\AMT\Lion\LionDevGenNet.exe /SERVICE"
    DisplayName    = "LionDevNet_Generator"
    StartupType    = "Manual"
    Description    = "LionDevNet_Generator"
}
  
New-Service @params -Credential $credential



cd c:\AMT

#Fix Generator

#Import-AzurePublishSettingsFile -PublishSettingsFile  "c:\AMT\Setup\Windows Azure MSDN - 1_15_2018, 09_15_39 - credentials.publishsettings" -InformationAction:SilentlyContinue

Write-Host "Start the LionDev_Gen service"

Start-Service -Name LionDevNet_Generator

$GenSet = "Default from loading source"


cd C:\Amt\Lion
# First load the LionRepository Module dll
try {
    $customDll = "c:\Amt\Lion\LionRepository.dll"
    Add-Type -path $customDll 
}
catch [System.Reflection.ReflectionTypeLoadException] {
    Write-Host "Message: $($_.Exception.Message)"
    Write-Host "StackTrace: $($_.Exception.StackTrace)"
    Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
}

$lionSources = Get-ChildItem -Path  C:\amt\Source -Filter "*.settings" | Sort-Object -Property  Name -Descending 
$Obj_Module = New-Object LionRepository
$Obj_Repos = $Obj_Module.OpenConnection([LionDatabaseType]::MsSql, "$($env:COMPUTERNAME)\SQLEXPRESS", "asy", "asy", "AMT_REPOS", "", $false, $Application, $true)

[String]$LionDevPath = "c:\amt\lion\liondev.exe"
if (-Not (Test-Path $LionDevPath)) {
    Throw "[$LionDevPath] does not exist"
}

foreach ($lionSource in $lionSources) {

   
    #fix for LF bug. Adding CR to make liondev work again.
    $original_file =$lionSource.FullName
    $text = [IO.File]::ReadAllText($original_file) -replace "`n", "`r`n"
    [IO.File]::WriteAllText($original_file, $text)
   
   
   
    Write-Host "Importing source for $lionSource"
    $Arguments = "IMP /FN:$($lionSource.FullName) NOGUI "



    # Passthru parameter is necessary to retrieve the exit code
    $Process = Start-Process -FilePath $LionDevPath -ArgumentList $Arguments -Wait -PassThru
    if ($Process.ExitCode -ne 0) {
        Throw "LionDev failed"
    }
    else {
        Write-Host "LionDev was successful" 
    }

    $Application = (Select-String -Pattern 'APPNAME=' -SimpleMatch -Path $($lionSource.FullName) | Select-Object *).Line.split('=')[1]
    $WebConfigPath = "c:\AMT\Apps\$Application\development\Client\web.config"

    if (-not (Test-Path $WebConfigPath)) {
        New-Item -Path "c:\AMT" -Name "Apps\$Application\development\Client" -ItemType "directory"
        Copy-Item "c:\amt\web.config" "c:\AMT\Apps\$Application\development\Client\"
        Copy-Item "c:\amt\compilation.config" "c:\AMT\Apps\$Application\development\Client\"
    }

    # Then create a LionRepository Module object
    $Obj_App = $Obj_Repos.GetApplication($Application)

   
    $Obj_Genset = $Obj_App.GetGenSet($GenSet)
    if ($Obj_Genset -eq $null) {
        $Obj_Genset = $Obj_App.AddGenSet($GenSet)
    }
    Write-Host("Genset: " + $Obj_Genset.Name)

      
    $Obj_Genset.LocalSourceFolder = "c:\AMT\Apps\$Application"
    $Obj_Genset.DuplicateRecords = "NoMessage"
    $Obj_Genset.GenerateInEdit = $true
    $Obj_GenSet.Save()

    # Create an ILionApplication object of the application LION6_CODE_TESTING
    $Obj_App = $Obj_Repos.GetApplication($Application)

    # Create an ILionGenSet object of the generation set Development
    $Obj_Genset = $Obj_App.GetGenSet($GenSet)

    # Create an ILionGenerate object for the application using the ILionGenSet object
    $Obj_Generate = $Obj_App.GetGenerate($Obj_Genset)

    #Reset the already generating status of the generator
    Write-Host "Fix generator already updating issue"
    Invoke-Sqlcmd -Username sa -Password $adminpassword -ServerInstance $env:COMPUTERNAME\SQLEXPRESS  -Query "UPDATE [AMT_REPOS].[dbo].[REVDATA] SET DATALINE='@' WHERE APPID=1 AND OBJTYPE=47"


    # Generate the complete application
    Write-Host "full gen for $lionsource"
    $Obj_Generate.GenerateWholeSystem($true) 

  
}


cd C:\AMT; 

.\InstallAmt_Local_Cobol.ps1


Set-TimeZone -Name "W. Europe Standard Time"

#Set password for admin to never expire
$user = [adsi]"WinNT://$env:computername/$adminname"
$user.UserFlags.value = $user.UserFlags.value -bor 0x10000
$user.CommitChanges()




#Set Chrome as default
$regKey      = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
$regKeyFtp   = $regKey -f 'ftp'
$regKeyHttp  = $regKey -f 'http'
$regKeyHttps = $regKey -f 'https'
Set-ItemProperty $regKeyFtp   -name ProgId ChromeHTML
Set-ItemProperty $regKeyHttp  -name ProgId ChromeHTML
Set-ItemProperty $regKeyHttps -name ProgId ChromeHTML

#Move install files to c:\amtscripts
$myfiles = Get-ChildItem -Path C:\AMT\ -Exclude "sys.ini", "amtRuntime.lic" | where { ! $_.PSIsContainer }
$AmtScripts = "C:\AmtScripts"
New-Item -type directory  $AmtScripts 
Copy-Item $myfiles $AmtScripts 
Remove-Item $myfiles

