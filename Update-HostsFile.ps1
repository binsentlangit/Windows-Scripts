# Define variables
$hostsFilePath = "C:\Windows\System32\drivers\etc\hosts"
$backupFilePath = "C:\Windows\System32\drivers\etc\hosts.bak"
#$goodbyeAdsURL = "https://scripttiger.github.io/alts/compressed/blacklist.txt"
$goodbyeAdsURL = "https://scripttiger.github.io/alts/mcompressed/blacklist.txt"
$tempFilePath = "$env:Temp\GoodbyeAds_hosts.txt"
$timestampFilePath = "$env:Temp\GoodbyeAds_timestamp.txt"
$logFilePath = "$env:Temp\Update-HostsFile.log"
$maxLogFileSizeMB = 5  # Maximum log file size in MB

# Function to check if running as Administrator
function Is-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure the script is run as Administrator
if (-not (Is-Administrator)) {
    Write-Host "This script must be run as an administrator." -ForegroundColor Red
    exit 1
}

# Manage the log file size
if (Test-Path $logFilePath) {
    $logFileSizeMB = (Get-Item $logFilePath).Length / 1MB
    if ($logFileSizeMB -gt $maxLogFileSizeMB) {
        Write-Host "Log file exceeds $maxLogFileSizeMB MB. Truncating the file..."
        Clear-Content $logFilePath
    }
}

# Start logging
Start-Transcript -Path $logFilePath -Append

# Check the last modified timestamp of the remote file
Write-Host "Checking for updates..."
try {
    $response = Invoke-WebRequest -Uri $goodbyeAdsURL -Method Head -ErrorAction Stop
    $remoteLastModified = $response.Headers["Last-Modified"]
    $remoteTimestamp = Get-Date $remoteLastModified -Format "yyyy-MM-ddTHH:mm:ss"
} catch {
    Write-Host "Failed to check the remote file's timestamp. Skipping update." -ForegroundColor Yellow
    Stop-Transcript
    exit 0
}

# Compare with the locally saved timestamp
if (Test-Path $timestampFilePath) {
    $localTimestamp = Get-Content $timestampFilePath
    if ($remoteTimestamp -eq $localTimestamp) {
        Write-Host "No updates available. Skipping the update process." -ForegroundColor Green
        Stop-Transcript
        exit 0
    }
}

# Check if the current hosts file exists
Write-Host "Checking for the existence of the current hosts file..."
if (-Not (Test-Path $hostsFilePath)) {
    Write-Host "No hosts file found at $hostsFilePath. A new file will be created." -ForegroundColor Yellow
}

# Create a backup of the current hosts file
if (Test-Path $hostsFilePath) {
    Write-Host "Creating a backup of the current hosts file..."
    Copy-Item -Path $hostsFilePath -Destination $backupFilePath -Force
    Write-Host "Backup created at $backupFilePath."
}

# Download the latest GoodbyeAds hosts file
Write-Host "Downloading the latest GoodbyeAds hosts file..."
try {
    Invoke-WebRequest -Uri $goodbyeAdsURL -OutFile $tempFilePath -ErrorAction Stop
    Write-Host "Download completed successfully."
} catch {
    Write-Host "Failed to download the GoodbyeAds hosts file. Please check your internet connection or the URL." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# Replace the current hosts file with the downloaded file
Write-Host "Updating the hosts file..."
try {
    Move-Item -Path $tempFilePath -Destination $hostsFilePath -Force
    Write-Host "Hosts file updated successfully."
} catch {
    Write-Host "Failed to update the hosts file. Ensure the file is not in use and you have sufficient permissions." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# Save the new timestamp
$remoteTimestamp | Out-File $timestampFilePath -Force
Write-Host "Timestamp updated locally."

# Flush the DNS cache
Write-Host "Flushing the DNS cache..."
try {
    ipconfig /flushdns | Out-Null
    Write-Host "DNS cache flushed successfully."
} catch {
    Write-Host "Failed to flush the DNS cache. Please try manually." -ForegroundColor Yellow
}

# Clean up
Write-Host "Temporary files removed. Update process complete!" -ForegroundColor Green
Stop-Transcript
