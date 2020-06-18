# Set some variables
$Logfile = "c:\temp\sysmondeploy.log"
$SystemSysmonConfig = 'C:\windows\sysmonconfig-export.xml'
$SysmonLocation = 'c:\windows\'
$SplunkSysmonConfig = 'C:\Program Files\SplunkUniversalForwarder\etc\apps\TA-Sysmon-deploy\bin\sysmonconfig-export.xml'

Start-Transcript -Path $Logfile
function CheckInstallStatus($software)
{
    # Function to check if software is installed on system
    $softwareinstalled = (Get-Service -DisplayName $software | Where-Object { $_.DisplayName -match $software })  -ne $null
    return $softwareinstalled 
}
function CheckSysmonVersion()
{
    $versioninfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\WINDOWS\Sysmon.exe").FileVersion
    return $versioninfo
}
$sysmoninstalled = CheckInstallStatus "Sysmon"
if(-not $sysmoninstalled)
{
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon needs to be installed, installing...'
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying new config file to c:\windows'
    Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
    ..\bin\Sysmon.exe -accepteula -i $SystemSysmonConfig
}
else {
    $sysmonversion = CheckSysmonVersion
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon is installed version:'$sysmonversion
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'checking if config needs updated'
    if ($(Get-FileHash $SystemSysmonConfig).Hash -ne $(Get-FileHash $SplunkSysmonConfig).Hash){
        Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'config needs updated, updating...'
        Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying new config file to c:\windows'
        Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
        ..\bin\Sysmon.exe -c $SplunkSysmonConfig
    } 
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'Config up to date and sysmon installed'
}
Stop-Transcript 