function Start-Install($App) {
    <#
    .NAME
        Start-Install
    .SYNOPSIS
        Install the requested application
    .DESCRIPTION
        Installs the requested application after first checking that WinGet is present on the system
    .PARAMATER App
        The application to be installed
    .EXAMPLE
        Start-Install -App 'Notepad++.Notepad++'
    .LINKS
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/windows/package-manager/winget/
        https://winstall.app/
    #>

    # Check if WinGet is already installed
    $Verify = (Get-Command winget -ErrorAction SilentlyContinue).Name

    # Once WinGet is installed begin installing the requested application
    if ($Verify -eq 'winget.exe') {
        winget install $App --silent
    } else {
        Get-Winget
        Start-Install $App
    }
}

function Get-Winget {
    <#
    .NAME
        Get-Winget
    .SYNOPSIS
        Download and install the WinGet appx bundle
    .DESCRIPTION
        Download the WinGet appx bundle to the temp direcoty at C:\Windows\Temp and then silently install it
    .EXAMPLE
        Get-Winget
    .LINKS
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/windows/package-manager/winget/
        https://winstall.app/
    #>

    # Store a redirect URL to the latest version of WinGet
    $WingetUrl = 'winget.onashia.com'
    
    # Store the path for downloading WinGet
    $Directory = ('{0}\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle' -f $env:windir)

    # Download WinGet to the Windows temp directory
    # Progress bars are temporary disabled as it slows download speed
    Write-Host 'Downloading WinGet...'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $WingetUrl -OutFile $Directory
    $ProgressPreference = 'Continue'

    # Install WinGet from the Windows temp directory
    Write-Host 'Installing WinGet...'
    Add-AppxPackage -Path $Directory
}