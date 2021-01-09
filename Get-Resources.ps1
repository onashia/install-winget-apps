Add-Type -AssemblyName PresentationCore, PresentationFramework, System.Windows.Forms


#region GUI Design
$Xaml = @"

        <Window 
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
                xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
                xmlns:local="clr-namespace:Get-Resources"
                mc:Ignorable="d"
                Title="App Installer" Height="450" Width="400">
             
             <Grid HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-100,0,0">
        
                <Image x:Name="App_Loader_Image" Source="https://i.ibb.co/yX4ZrjS/download-cloud.png" HorizontalAlignment="Center" Height="100" VerticalAlignment="Center" Width="100"/>
               
                <Button x:Name="Loader_Button" Content="Download Latest Installer" HorizontalAlignment="Center" Margin="0,178,0,-80" VerticalAlignment="Top" Width="200" Height="54" FontSize="16" Visibility="Visible" />
                <ProgressBar x:Name="Loader_Progress" HorizontalAlignment="Center" Height="15" Margin="0,184,0,-94" VerticalAlignment="Top" Width="200" Minimum="0" Maximum="100" Visibility="Hidden" />
                <Label x:Name="Loader_Label" Content="Loading Dependencies" HorizontalAlignment="Center" HorizontalContentAlignment="Center" Margin="0,200,9,-94" VerticalAlignment="Center" FontSize="12" Width="200" Visibility="Hidden" />

            </Grid>
        </Window>

"@
#endregion

#region GUI Load
$Window = [Windows.Markup.XamlReader]::Parse($Xaml)
[xml]$xml = $Xaml
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }
#endregion

#region PowerShell Functions

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
    $WingetPath = 'C:\Users\User\Desktop\winget.appxbundle'

    # Redirect URL points to the latest hash of WinGet
    $HashUrl = 'hash.onashia.com'
    # Path to store the WinGet hash
    $HashPath = 'C:\Users\User\Desktop\winget.SHA256.txt'
    
    try {
        # Disable progress bars during download as they significantly slow down speed
        $ProgressPreference = 'SilentlyContinue'

        # Download WinGet
        Invoke-WebRequest $WingetUrl -OutFile $WingetPath
        #$Label.Content = 'Downloading Winget'
        
        # Download WinGet hash value
        Invoke-WebRequest $HashUrl -OutFile $HashPath
    } catch {
        return false
    }    

    # Get the hash value stored within the $HashPath file
    $CorrectHash = Get-Content $HashPath -First 1

    # Compute the hash of the the file located at $FilePath
    $FileHash = Get-FileHash $WingetPath -Algorithm SHA256

    # Install WinGet from the Windows temp directory if the file hash has been verified
    if ($CorrectHash -eq $FileHash.Hash) {
        # Install Winget
        Add-AppxPackage -Path $FilePath

        # Re-enable progress bars within powershell
        $ProgressPreference = 'Continue'
    } else {
        return false
    }
    return true
}

function Get-File($Url, $Path, $Log) {
    <#
    .NAME
        Get-File
    .SYNOPSIS
        Download a file from a given url to the desired path
    .DESCRIPTION
        Download a file from a given url to the desired path using Invoke-WebRequest
    .PARAMETER Url
        The direct url to the file to download
    .PARAMETER Path
        The path to save the downloaded file to, including the file name and extension
    .EXAMPLE
        Get-File 'www.link.com/file.pdf' 'C:\Temp'
    .LINKS
        https://github.com/onashia
    #>

    # Try to download the file from the given $Url to the desired $Path
    try {
        # Temporarily disable progress bars as it significantly slows the download speed
        $ProgressPreference = 'SilentlyContinue'

        # Begin downloading the file
        Invoke-WebRequest $Url -OutFile $Path

        # Enable progress bars that we previously disabled
        $ProgressPreference = 'Continue'
    } catch {
        Add-Content $Log -value 'Download failed'
        return false
    }
    Add-Content $Log -value 'Download successful'
    return true
}

function Check-Hash($Hash, $Path, $Log) {
    <#
    .NAME
        Check-Hash
    .SYNOPSIS
        Verify a published hash matches a file hash
    .DESCRIPTION
        Verify a published hash matches a file hash and return the result
    .PARAMATER Hash
        The correct hash value stored in a text document
    .PARAMETER Path
        The file on which the has value will be compared to
    .EXAMPLE
        $result = Get-Hash C:\hash.txt C:\file.appxbundle
    .NOTES
        https://github.com/onashia
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash
    #>

    # Get the hash value stored within the $Hash file
    $ValidHash = Get-Content $Hash -First 1
    
    # Compute the hash of the the file located at $FilePath
    $FileHash = Get-FileHash $Path -Algorithm SHA256
    
    # Return the result from comparing the published hash to the file hash
    if ($ValidHash -eq $FileHash.Hash) {
        Add-Content $Log -value 'Hash passed'
        return 'true'
    } 
    
    Add-Content $Log -value 'Hash failed'
    return 'false'
}

function Wait-Job ($Job) {
    <#
    .NAME
        Wait-Job
    .SYNOPSIS
        Wait for the provided job to be completed
    .DESCRIPTION
        Wait for the provided job to be completed without inturupting the GUI
    .PARAMATER Job
        A passed Job created with the Start-Job command
    .EXAMPLE
        $Job = Start-Job -ScriptBlock { Start-Sleep 100 }
        Wait-Job $Job
    .NOTES
        https://github.com/onashia
    #>
    Do {
        [System.Windows.Forms.Application]::DoEvents()
        } Until ($Job.State -eq 'Completed')
}

#endregion

#region PowerShell Code

# Set variables for gui elements
$Button = $Window.FindName('Loader_Button')
$Progress = $Window.FindName('Loader_Progress')
$Label = $Window.FindName('Loader_Label')

# Path to store the program log
$Log = 'C:\Users\User\Desktop\app-installer.log'

# Url to get winget
$WingetUrl = 'winget.onashia.com'
# Path to save winget
$WingetPath = 'C:\Users\User\Desktop\winget.appxbundle'

# Url to get winget hash
$HashUrl = 'hash.onashia.com'
# Path to save winget hash
$HashPath = 'C:\Users\User\Desktop\winget-hash.SHA256.txt'

# Url to get App Installer
$AppUrl = 'https://raw.githubusercontent.com/onashia/install-winget-apps/main/Install-App.ps1'
# Path to save App Installer
$AppPath = 'C:\Users\User\Desktop\App-Installer.ps1'

$Label.Content = 'loading dependencies'

# When button is clicked begin downloading App Installer dependencies
$Button.Add_Click({

    # Hide the button and show the current status of loading
    $Button.Visibility = "Hidden"
    $Progress.Visibility = "Visible"
    $Label.Visibility = "Visible"

    # Download winget
    $Label.Content = 'downloading winget'
    $Job = Start-Job -Name Download_Winget -ScriptBlock ${Function:Get-File} -ArgumentList $WingetUrl, $WingetPath, $Log
    Wait-Job $Job
    # Update progress bar
    $Progress.Value = '30'

    # Download winget hash
    $Label.Content = 'downloading winget hash'
    $Job = Start-Job -Name Download_Hash -ScriptBlock ${Function:Get-File} -ArgumentList $HashUrl, $HashPath, $Log
    Wait-Job $Job
    # Update progress bar
    $Progress.Value = '40'

    # Verify winget file
    $Label.Content = 'verifying winget'
    $Job = Start-Job -Name Verify_Winget -ScriptBlock ${Function:Check-Hash} -ArgumentList $HashPath, $WingetPath, $Log
    Wait-Job $Job
    # Update progress bar
    $Progress.Value = '50'

    # Download app installer
    $Label.Content = 'downloading app installer'
    $Job = Start-Job -Name Download_Installer -ScriptBlock ${Function:Get-File} -ArgumentList $AppUrl, $AppPath, $Log
    Wait-Job $Job
    # Update progress bar
    $Progress.Value = '80'

    ############# TODO ################
    # Create and upload a hash file for the App Installer #
    # Also download and check the hash of the App Installer when this loader is run #

    # Start app installer
    $Label.Content = 'starting app installer'
    $Job = Start-Job -Name Start_Insatller -ScriptBlock {Start-Sleep -s 5}    
    Wait-Job $Job 
    #Start-Process PowerShell -Verb RunAs -ArgumentList ("-file {0}" -f $AppPath)
    Start-Process C:\Users\User\Desktop\Items\Install-Apps.exe

    # Close the app loader
    $Window.Close()
})

#endregion

#region GUI Display
$Window.ShowDialog() | Out-Null
#endregion