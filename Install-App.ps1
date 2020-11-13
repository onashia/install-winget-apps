function Start-Install($App) {
    <#
    .NAME
        Start-Install
    .SYNOPSIS
        Install the requested application
    .DESCRIPTION
        Installs the requested application after first checking that WinGet is present on the system
    .PARAMATER App
        The application requested to be installed
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
        Download and install WinGet
    .DESCRIPTION
        Download the WinGet appx bundle to the Windows temp directory and then install it
    .EXAMPLE
        Get-Winget
    .LINKS
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/windows/package-manager/winget/
        https://winstall.app/
    #>

    # Redirect URL points to the latest version of WinGet
    $WingetUrl = 'winget.onashia.com' 
    # Path to store WinGet
    $FilePath = ('{0}\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle' -f $env:windir)

    # Redirect URL points to the latest hash of WinGet
    $WingetHash = 'hash.onashia.com'
    # Path to store the WinGet hash
    $HashPath = ('{0}\temp\Microsoft.DesktopAppInstaller.SHA256.txt' -f $env:windir)
    
    try {
        # Disable progress bars during download as they significantly slow down speed
        $ProgressPreference = 'SilentlyContinue'

        # Download WinGet
        Write-Host 'Downloading WinGet...'
        Invoke-WebRequest $WingetUrl -OutFile $FilePath
        
        # Download WinGet hash value
        Write-Host 'Downloading WinGet hash...'
        Invoke-WebRequest $WingetHash -OutFile $HashPath
    } catch {
        Write-Host 'Unable to download files, please try again...'
        break
    }    

    # Verify hash of WinGet is correct
    Write-Host 'Verifying integrity of WinGet...'
    $VerifyHash = Check-Hash $HashPath $FilePath

    # Install WinGet from the Windows temp directory if the file hash has been verified
    if ($VerifyHash -eq 'true') {
        Write-Host 'Installing WinGet...'
        Add-AppxPackage -Path $FilePath

        # Re-enable progress bars within powershell
        $ProgressPreference = 'Continue'
    } else {
        break
    }
}

function Check-Hash($HashPath, $FilePath) {
    <#
    .NAME
        Check-Hash
    .SYNOPSIS
        Verify a published hash matches a file hash
    .DESCRIPTION
        Verify a published hash matches a file hash and return the result
    .PARAMATER HashPath
        The correct hash value stored in a text document
    .PARAMETER FilePath
        The file on which the has value will be compared to
    .EXAMPLE
        $result = Get-Hash C:\hash.txt C:\file.appxbundle
    .NOTES
        https://github.com/onashia/install-winget-apps
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash
    #>

    # Get the hash value stored within the $HashPath file
    $PublishedHash = Get-Content $HashPath -First 1
    
    # Compute the hash of the the file located at $FilePath
    $FileHash = Get-FileHash $FilePath -Algorithm SHA256
    
    # Return the result from comparing the published hash to the file hash
    if ($PublishedHash -eq $FileHash.Hash) {
        Write-Host 'Succesfully verified file hash'
        return 'true'
    } else {
        Write-Host 'The hash of the file does not match the published hash value. Please try downloading again...'
        return 'false'
    }
}