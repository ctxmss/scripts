# If you make changes to this script, please ensure that you update the corresponding version in AVD Hosts A.
#
# Test this script in the "NT Authority\System" Context using PSEXEC: Psexec.exe -i -s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe -accepteula

# This script will install and remove software via Winget Package Manager
# Location: AVD Hosts B/scripts/winget-ps-wrapper.ps1
# Version: 1.1


# Confirm Winget is installed, if not install it
# Define log file path
$logFilePath = "C:\ProgramData\winget_install_log.txt"

# Function to log messages
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "$timestamp [$type] $message"
    Add-Content -Path $logFilePath -Value $formattedMessage
}

# Start logging
Write-Log "Script execution started."

# Confirm Winget is installed, if not install it
$AppInstaller = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq 'Microsoft.DesktopAppInstaller'

if (-not $AppInstaller -or $AppInstaller.Version -lt [Version]"2024.1025.2351.0") {
    Write-Log "Winget is not installed or outdated. Attempting to install the latest version from GitHub..." "WARN"

    try {
        Write-Log "Creating Winget Packages Folder if not present..."
        $wingetPackagesPath = "C:\ProgramData\WinGetPackages"

        if (!(Test-Path -Path $wingetPackagesPath)) {
            New-Item -Path $wingetPackagesPath -Force -ItemType Directory | Out-Null
        }

        Set-Location $wingetPackagesPath

        # Downloading Package Files
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0" -OutFile "$wingetPackagesPath\microsoft.ui.xaml.2.7.0.zip"
        Expand-Archive -Path "$wingetPackagesPath\microsoft.ui.xaml.2.7.0.zip" -Force

        Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "$wingetPackagesPath\Microsoft.VCLibs.x64.14.00.Desktop.appx"

        Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$wingetPackagesPath\Winget.msixbundle"

        # Installing dependencies and Winget
        Add-ProvisionedAppxPackage -Online -PackagePath "$wingetPackagesPath\Winget.msixbundle" `
            -DependencyPackagePath "$wingetPackagesPath\Microsoft.VCLibs.x64.14.00.Desktop.appx,$wingetPackagesPath\microsoft.ui.xaml.2.7.0\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.Appx" `
            -SkipLicense

        Write-Log "Winget installation complete. Waiting briefly to finalize installation."
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Log "Failed to install Winget: $($_.Exception.Message)" "ERROR"
        Exit 1
    }
}
else {
    Write-Log "Winget is already installed, proceeding..."
}

# Packages to install
$InstallPackages = @(
    "Adobe.Acrobat.Reader.64-bit",
    "Microsoft.AzureCLI",
    "Microsoft.Git",
    "Microsoft.FSLogix",
    "Microsoft.VisualStudioCode",
    "JGraph.Draw",
    "Notepad++",
    "Microsoft.Azure.StorageExplorer",
    "Microsoft.PowerShell",
    "7zip.7zip",
    "PuTTY.PuTTY",
    "Citrix.Workspace",
    "VMware.HorizonClient",
    "DominikReichl.KeePass",
    "WiresharkFoundation.Wireshark",
    "baremetalsoft.baretail"
)

# Resolve Winget executable path
$wingetPath = (Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe")[-1].Path

# Install packages
foreach ($packageName in $InstallPackages) {
    try {
        Write-Log "Installing $packageName via Winget..."
        Start-Process -FilePath "$wingetPath\winget.exe" -ArgumentList "install $packageName --silent --accept-source-agreements --accept-package-agreements --disable-interactivity --force --scope machine" -NoNewWindow -Wait
        Write-Log "$packageName installation completed."
    }
    catch {
        Write-Log "Failed to install package $packageName $($_.Exception.Message)" "ERROR"
    }
}

# Packages to remove
$RemovePackages = @(
    "Microsoft.BingWeather_8wekyb3d8bbwe",                  # MSN Weather
    "Microsoft.BingNews_8wekyb3d8bbwe",
    "Microsoft.GamingApp_8wekyb3d8bbwe",
    "Microsoft.BingSearch_8wekyb3d8bbwe",
    "Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe",# Solitaire & Casual Games
    "Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe",        # Microsoft Sticky Notes
    "Microsoft.WindowsCamera_8wekyb3d8bbwe",               # Microsoft Camera
    "Microsoft.ZuneMusic_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",          # Feedback Hub
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe",        # Windows Sound Recorder
    "Microsoft.Xbox.TCUI_8wekyb3d8bbwe",                   # Xbox TCUI
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",           # XboxGamingOverlay
    "Microsoft.XboxIdentityProvider_8wekyb3d8bbwe",        # XboxIdentityProvider
    "Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe",     # Game Speech Window
    "Microsoft.YourPhone_8wekyb3d8bbwe",                   # Phone Link
    "9MSSGKG348SP"                                         # Widgets (Windows Web Experience)
)

# Remove packages
foreach ($packageName in $RemovePackages) {
    try {
        Write-Log "Removing $packageName via Winget..."
        Start-Process -FilePath "$wingetPath\winget.exe" -ArgumentList "remove $packageName --silent --force --scope machine" -NoNewWindow -Wait
        Write-Log "$packageName removal completed."
    }
    catch {
        Write-Log "Failed to remove package $packageName $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Script execution completed."
Exit 0
