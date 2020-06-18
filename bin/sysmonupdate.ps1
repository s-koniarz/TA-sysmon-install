# Set some variables
$Logfile = "c:\temp\sysmondeploy.log"
$SystemSysmonConfig = 'C:\windows\sysmonconfig-export.xml'
$SysmonLocation = 'c:\windows\'
$SplunkSysmonConfig = 'C:\Program Files\SplunkUniversalForwarder\etc\apps\TA-sysmon-install\bin\sysmonconfig-export.xml'
$sysmoninstalllocation = 'C:\Windows\Sysmon.exe'
$Splunksysmonlocation = 'C:\Program Files\SplunkUniversalForwarder\etc\apps\TA-sysmon-install\bin\Sysmon.exe'

Start-Transcript -Path $Logfile
function CheckInstallStatus($software)
{
    # Function to check if software is installed on system
    $softwareinstalled = (Get-Service -DisplayName $software | Where-Object { $_.DisplayName -match $software })  -ne $null
    return $softwareinstalled 
}
function CheckSysmonVersion($path)
{
    $versioninfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path).FileVersion
    return $versioninfo
}

# Check if sysmon is insallted Variable setting
$sysmoninstalled = CheckInstallStatus "Sysmon"
$sysmonlocal = (CheckSysmonVersion($Splunksysmonlocation))
$sysmonsplunk = (CheckSysmonVersion($sysmoninstalllocation))
if(-not $sysmoninstalled)
{
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon needs to be installed, installing...'
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying new config file to c:\windows'
    Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
    ..\bin\Sysmon.exe -accepteula -i $SystemSysmonConfig
}elseif($sysmonlocal -ne $sysmonsplunk) {
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon out of date, updating and applying config'
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'uninstalling sysmon'
    ..\bin\Sysmon.exe -u 
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying newest config to c:\windows'
    Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'installing newest version of sysmon'
    ..\bin\Sysmon.exe -accepteula -i $SystemSysmonConfig
}else{
    $sysmoninstalledversion = CheckSysmonVersion($sysmoninstalllocation)
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon is installed version:'$sysmoninstalledversion
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'checking if config needs updated'
    if (Test-Path -LiteralPath "C:\Windows\sysmonconfig-export.xml"){
        if ($(Get-FileHash $SystemSysmonConfig).Hash -ne $(Get-FileHash $SplunkSysmonConfig).Hash){
            Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'config needs updated, updating...'
            Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying new config file to c:\windows'
            Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
            ..\bin\Sysmon.exe -c $SplunkSysmonConfig
        } 
    }else{
        Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'sysmon installed with no config present in c:\windows'
        Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'copying new config and applying'
        Copy-Item $SplunkSysmonConfig -Destination $SysmonLocation
        ..\bin\Sysmon.exe -c $SplunkSysmonConfig
    }
    Write-Host (Get-Date -Format "MM/dd/yyyy HH:mm K") 'Config up to date and sysmon installed at proper version'
}
Stop-Transcript 