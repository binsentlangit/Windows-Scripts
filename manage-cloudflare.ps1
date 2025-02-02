# Variables
$serviceName = "CloudflareWARP"
$appPath = "C:\Program Files\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe"

# Start the service if not running
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service.Status -ne 'Running') {
    Start-Service -Name $serviceName
    Write-Output "Service $serviceName started."
}

# Launch the application
Start-Process -FilePath $appPath
Write-Output "Application started: $appPath"

# Monitor the application and stop the service when it closes
do {
    Start-Sleep -Seconds 1
} while (Get-Process | Where-Object { $_.Path -eq $appPath } -ErrorAction SilentlyContinue)

# Ensure the service is running before stopping
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service.Status -eq 'Running') {
    try {
        Stop-Service -Name $serviceName -Force
        Write-Output "Service $serviceName stopped."
    } catch {
        Write-Error "Failed to stop the service: $_"
    }
} else {
    Write-Output "Service $serviceName is not running."
}
