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
    .PARAMETER Check
        Checks to make sure that the download is succesful
    .EXAMPLE
        Get-Winget
    .LINKS
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/windows/package-manager/winget/
        https://winstall.app/
    #>

    # Redirect URL to the latest version of WinGet
    $WingetUrl = 'winget.onashia.com' 
    # Path for downloading WinGet
    $Directory = ('{0}\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle' -f $env:windir)

    # Redirect URL to the latest hash of WinGet
    $WingetHash = 'hash.onashia.com'
    # Path for downloading the WinGet hash
    $HashDirectory = ('{0}\temp\Microsoft.DesktopAppInstaller.SHA256.txt' -f $env:windir)

    # If WinGet is unable to be downloaded stop running the function
    Write-Host 'Downloading WinGet...'
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest $WingetUrl -OutFile $Directory
        $ProgressPreference = 'Continue'
    } catch {
        Write-Host 'Unable to download WinGet. Please try again...'
        break
    }    

    # Download the latest WinGet hash value
    Write-Host 'Downloading WinGet hash...'
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest $WingetHash -OutFile $HashDirectory
        $ProgressPreference = 'Continue'
    } catch {
        Write-Host 'Unable to download WinGet hash. Please try again...'
        break
    }

    # Verify hash of WinGet is correct
    Write-Host 'Verifying integrity of WinGet...'
    $VerifyHash = Check-Hash $HashDirectory $Directory

    # Install WinGet from the Windows temp directory
    if ($VerifyHash -eq 'true') {
        Write-Host 'Installing WinGet...'
        Add-AppxPackage -Path $Directory
    }
}

function Check-Hash($Value, $File) {
    <#
    .NAME
        Check-Hash
    .SYNOPSIS
        Verify original hash matches the hash value of the new file
    .DESCRIPTION
        Verify the original hash value matches the hash value of the new file and return the result
    .PARAMATER Value
        The correct hash value stored in a text document
    .PARAMETER File
        The file on which the has value will be compared to
    .EXAMPLE
        $result = Get-Hash C:\hash.txt C:\file.appxbundle
    .NOTES
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash
    #>

    # Get the hash value stored within $Value
    $PublishedHash = Get-Content $Value -First 1
    
    # Compute the hash of the $File
    $FileHash = Get-FileHash $File -Algorithm SHA256
    
    # If the hash values do not match stop running the function
    if ($PublishedHash -eq $FileHash.Hash) {
        Write-Host 'Succesfully verified file hash'
        return 'true'
    } else {
        Write-Host 'The hash of the filedoes not match the published hash value. Please try downloading again...'
        break
    }
}