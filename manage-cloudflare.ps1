<#
.SYNOPSIS
    Starts the CloudflareWARP service, launches the Cloudflare WARP app, and stops the service when the app closes.
.DESCRIPTION
    This single PowerShell script:
     - Automatically relaunches itself as Administrator if not already elevated.
     - Hides its own console window.
     - Starts the specified service (if not already running).
     - Launches the Cloudflare WARP application.
     - Monitors the application process; once the app is closed, it stops the service.
     - Logs actions via transcript (log file path can be changed).
.PARAMETER ServiceName
    The name of the service to control (default: "CloudflareWARP").
.PARAMETER AppPath
    The full path to the Cloudflare WARP application (default: "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe").
.PARAMETER LogFile
    The path for the log transcript (default: "$env:USERPROFILE\Documents\CloudflareWARP_log.txt").
#>

param(
    [string]$ServiceName = "CloudflareWARP",
    [string]$AppPath = "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe",
    [string]$LogFile = "$env:USERPROFILE\Documents\CloudflareWARP_log.txt"
)

# --- Auto-Elevation: Relaunch as Administrator if not elevated ---
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Not running as Administrator. Relaunching elevated..."
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# --- Hide the Console Window ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$consoleHandle = [Win32]::GetConsoleWindow()
if ($consoleHandle -ne [IntPtr]::Zero) {
    # 0 = SW_HIDE hides the window
    [Win32]::ShowWindow($consoleHandle, 0)
}

# --- Start Logging ---
try {
    Start-Transcript -Path $LogFile -Append
} catch {
    Write-Output "Warning: Unable to start logging. Continuing without transcript..."
}

# --- Check that the Service Exists ---
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Output "Error: Service '$ServiceName' not found. Exiting."
    Stop-Transcript
    exit 1
}

# --- Start the Service if Not Running ---
if ($service.Status -ne 'Running') {
    Write-Output "Starting service '$ServiceName'..."
    try {
        Start-Service -Name $ServiceName -ErrorAction Stop
        Start-Sleep -Seconds 2  # Allow the service time to start
        Write-Output "Service '$ServiceName' started."
    } catch {
        Write-Output "Error: Failed to start service '$ServiceName'. $_"
        Stop-Transcript
        exit 1
    }
} else {
    Write-Output "Service '$ServiceName' is already running."
}

# --- Launch the Application ---
Write-Output "Launching application '$AppPath'..."
try {
    # -PassThru returns a process object so we can monitor it.
    $appProcess = Start-Process -FilePath $AppPath -PassThru -ErrorAction Stop
} catch {
    Write-Output "Error: Unable to launch application '$AppPath'. $_"
    Stop-Transcript
    exit 1
}

Write-Output "Application launched. Waiting for it to exit..."
$appProcess.WaitForExit()

# --- Stop the Service After the Application Exits ---
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service.Status -eq 'Running') {
    Write-Output "Stopping service '$ServiceName'..."
    try {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Output "Service '$ServiceName' stopped."
    } catch {
        Write-Output "Error: Failed to stop service '$ServiceName'. $_"
    }
} else {
    Write-Output "Service '$ServiceName' is not running."
}

Write-Output "Operation complete."
Stop-Transcript
