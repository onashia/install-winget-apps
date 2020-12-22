Add-Type -AssemblyName PresentationCore, PresentationFramework

#region Design GUI

$Xaml = @"
            <Window
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
                xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
                Title="Install Apps" Height="450" Width="800">
            <Grid>
                <Label x:Name="Web_Browsers" Content="Web Browsers" HorizontalAlignment="Left" Margin="30,18,0,0" VerticalAlignment="Top" FontWeight="Bold" FontSize="16"/>
                <CheckBox x:Name="Chrome" Content="Chrome" HorizontalAlignment="Left" Margin="40,54,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Firefox" Content="Firefox" HorizontalAlignment="Left" Margin="40,74,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Edge" Content="Edge" HorizontalAlignment="Left" Margin="40,94,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Opera" Content="Opera" HorizontalAlignment="Left" Margin="40,114,0,0" VerticalAlignment="Top"/>

                <Label x:Name="Media" Content="Media" HorizontalAlignment="Left" Margin="30,153,0,0" VerticalAlignment="Top" FontWeight="Bold" FontSize="16"/>
                <CheckBox x:Name="VLC" Content="VLC" HorizontalAlignment="Left" Margin="40,189,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="iTunes" Content="iTunes" HorizontalAlignment="Left" Margin="40,209,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Spotify" Content="Spotify" HorizontalAlignment="Left" Margin="40,229,0,0" VerticalAlignment="Top"/>

                <Label x:Name="Messaging" Content="Messaging" HorizontalAlignment="Left" Margin="30,268,0,0" VerticalAlignment="Top" FontWeight="Bold" FontSize="16"/>
                <CheckBox x:Name="Zoom" Content="Zoom" HorizontalAlignment="Left" Margin="40,304,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Thunderbird" Content="Thunderbird" HorizontalAlignment="Left" Margin="40,324,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Discord" Content="Discord" HorizontalAlignment="Left" Margin="40,344,0,0" VerticalAlignment="Top"/>

                <Label x:Name="Utilities" Content="Utilities" HorizontalAlignment="Left" Margin="250,18,0,0" VerticalAlignment="Top" FontWeight="Bold" FontSize="16"/>
                <CheckBox x:Name="Adobe_Reader" Content="Adobe Reader" HorizontalAlignment="Left" Margin="260,54,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="_7_zip" Content="7-zip" HorizontalAlignment="Left" Margin="260,74,0,0" VerticalAlignment="Top"/>
                <CheckBox x:Name="Java_SE" Content="Java SE" HorizontalAlignment="Left" Margin="260,94,0,0" VerticalAlignment="Top"/>

                <Label x:Name="Security" Content="Security" HorizontalAlignment="Left" Margin="250,131,0,0" VerticalAlignment="Top" FontSize="16" FontWeight="Bold"/>
                <CheckBox x:Name="Malwarebytes" Content="Malwarebytes" HorizontalAlignment="Left" Margin="260,163,0,0" VerticalAlignment="Top"/>

                <Button x:Name="Install" Content="Install" HorizontalAlignment="Left" Margin="589,344,0,0" VerticalAlignment="Top" Width="170" Height="45"/>

            </Grid>
        </Window>
"@

#endregion

#region Functions

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

function Install-Apps {
    # Determine what options are checked
    if ($Chrome.IsChecked) {
        Start-Install "Google.Chrome"
    }
    if ($Firefox.IsChecked) {
        Start-Install "Mozilla.Firefox"
    }
    if ($Edge.IsChecked) {
        Start-Install "Microsoft.Edge"
    }
    if ($Opera.IsChecked) {
        Start-Install "Opera.Opera"
    }
    if ($VLC.IsChecked) {
        Start-Install "VideoLAN.VLC"
    }
    if ($iTunes.IsChecked) {
        Start-Install "Apple.iTunes"
    }
    if ($Spotify.IsChecked) {
        Start-Install "Spotify.Spotify"
    }
    if ($Zoom.IsChecked) {
        Start-Install "Zoom.Zoom"
    } 
    if ($Thunderbird.IsChecked) {
        Start-Install "Mozilla.Thunderbird"
    } 
    if ($Discord.IsChecked) {
        Start-Install "Discord.Discord"
    } 
    if ($Adobe_Reader.IsChecked) {
        Start-Install "Adobe.AdobeAcrobatReaderDC"
    }
    if ($_7_zip.IsChecked) {
        Start-Install "7zip.7zip"
    }
    if ($Java_SE.IsChecked) {
        Start-Install "Oracle.JavaRuntimeEnvironment"
    }
    if ($Malwarebytes.IsChecked) {
        Start-Install "Malwarebytes.Malwarebytes"
    }
}

#endregion


#region Load GUI

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)
[xml]$xml = $Xaml
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

#endregion

#region Live Code

# Web Browsers
$Chrome = $Window.FindName('Chrome')
$Firefox = $Window.FindName('Firefox')
$Edge = $Window.FindName('Edge')
$Opera = $Window.FindName('Opera')

# Media
$VLC = $Window.FindName('VLC')
$iTunes = $Window.FindName('iTunes')
$Spotify = $Window.FindName('Spotify')

# Messaging
$Zoom = $Window.FindName('Zoom')
$Thunderbird = $Window.FindName('Thunderbird')
$Discord = $Window.FindName('Discord')

# Utilities
$Adobe_Reader = $Window.FindName('Adobe_Reader')
$_7_zip = $Window.FindName('_7_zip')
$Java_SE = $Window.FindName('Java_SE')

# Security
$Malwarebytes = $Window.FindName('Malwarebytes')

# Start installing selected applications when button is pressed
$Button = $Window.FindName('Install')
$Button.Add_Click(
    {
        Install-Apps
    }
)

#endregion

#region Show GUI

$Window.ShowDialog() | Out-Null

#endregion