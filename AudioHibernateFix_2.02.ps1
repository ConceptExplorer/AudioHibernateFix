# AudioHibernateFix.ps1 (v2.0.2)
# ConceptExplorer © 2026
# Menu‑prompt diagnostic tool for Windows audio & USB hardware issues after hibernate/sleep.

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       === Audio Hibernate Fix ===" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Select an option:"
    Write-Host "1) Run Simple Check (Services & Power)"
    Write-Host "2) Run Detailed Check (Full Diagnostics)"
    Write-Host "3) Run Advanced Fix (Includes USB Audio Reset)"
    Write-Host "4) Exit"
    Write-Host ""
}

function Simple-Check {
    Clear-Host
    Write-Host "=== Simple Check ===" -ForegroundColor Yellow
    Write-Host "Checking audio service health..." -ForegroundColor White

    $audio = Get-Service -Name "audiosrv" -ErrorAction SilentlyContinue
    $endpoint = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

    if (($null -eq $audio -or $audio.Status -ne 'Running') -or ($null -eq $endpoint -or $endpoint.Status -ne 'Running')) {
        Write-Host "Audio service not healthy. Restarting audio stack..." -ForegroundColor Red
        Stop-Service -Name audiosrv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Service -Name AudioEndpointBuilder -ErrorAction SilentlyContinue
        Start-Service -Name audiosrv -ErrorAction SilentlyContinue
        Write-Host "Audio services restarted successfully." -ForegroundColor Green
    } else {
        Write-Host "Audio services appear healthy." -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Checking power device initialization policy..." -ForegroundColor White

    try {
        $query = powercfg -query SCHEME_CURRENT | Out-String
        if ($query -match "SUB_DEVICE") {
            Write-Host "Legacy power initialization policy detected. Applying fix..." -ForegroundColor Red
            powercfg -setacvalueindex SCHEME_CURRENT SUB_DEVICE POWERLEVEL 0 | Out-Null
            powercfg -setdcvalueindex SCHEME_CURRENT SUB_DEVICE POWERLEVEL 0 | Out-Null
            powercfg -SetActive SCHEME_CURRENT | Out-Null
            Write-Host "Power initialization policy corrected." -ForegroundColor Green
        } else {
            Write-Host "Power initialization policy not exposed on this build; skipping." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "Power configuration check skipped (not supported on this build)." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "Simple check complete." -ForegroundColor Cyan
    Pause
}

function Detailed-Check {
    Clear-Host
    Write-Host "=== Detailed Check ===" -ForegroundColor Yellow
    Write-Host "Performing full diagnostic..." -ForegroundColor White

    Write-Host "`n[Audio Service Definitions]" -ForegroundColor Cyan
    Write-Host "Audiosrv: Windows Audio service responsible for core audio engine."
    Write-Host "AudioEndpointBuilder: Manages audio endpoints and device binding."

    $audio = Get-Service -Name "audiosrv" -ErrorAction SilentlyContinue
    $endpoint = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

    Write-Host "`n[Audio Service States]" -ForegroundColor Cyan
    Write-Host "Audiosrv status: $(if ($audio) {$audio.Status } else { 'Not Found' })"
    Write-Host "AudioEndpointBuilder status: $(if ($endpoint) {$endpoint.Status } else { 'Not Found' })"

    if (($null -eq $audio -or $audio.Status -ne 'Running') -or ($null -eq $endpoint -or $endpoint.Status -ne 'Running')) {
        Write-Host "`nAudio service not healthy. Restarting audio stack..." -ForegroundColor Red
        Stop-Service -Name audiosrv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Service -Name AudioEndpointBuilder -ErrorAction SilentlyContinue
        Start-Service -Name audiosrv -ErrorAction SilentlyContinue
        Write-Host "Audio services restarted successfully." -ForegroundColor Green
    } else {
        Write-Host "`nAudio services appear healthy." -ForegroundColor Green
    }

    Write-Host "`n[External USB Audio Hardware Scan]" -ForegroundColor Cyan
    $usbAudioDevices = Get-PnpDevice -Class "AudioEndpoint" -Status "OK" -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Sound Blaster*" -or $_.FriendlyName -like "*USB*" }
    if ($usbAudioDevices) {
        foreach ($dev in $usbAudioDevices) {
            Write-Host "Detected active audio endpoint: $($dev.FriendlyName)" -ForegroundColor Green
        }
    } else {
        Write-Host "No active external USB audio endpoints detected or flagged." -ForegroundColor DarkGray
    }

    Write-Host "`nDetailed check complete." -ForegroundColor Cyan
    Pause
}

function Advanced-Fix {
    Clear-Host
    Write-Host "=== Advanced Fix (USB & Audio Stack Refresh) ===" -ForegroundColor Yellow
    
    # 1. Standard Audio Stack Reset
    Write-Host "Restarting core Windows audio services..." -ForegroundColor White
    Stop-Service -Name audiosrv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Service -Name AudioEndpointBuilder -ErrorAction SilentlyContinue
    Start-Service -Name audiosrv -ErrorAction SilentlyContinue
    Write-Host "Audio services restarted." -ForegroundColor Green

    # 2. Target External USB Audio Devices (Sound Blaster / Generic USB Audio)
    Write-Host "Searching for hung external USB audio devices..." -ForegroundColor White
    $targetDevices = Get-PnpDevice -Present:$true -ErrorAction SilentlyContinue | Where-Object { 
        $_.FriendlyName -like "*Sound Blaster*" -or $_.FriendlyName -like "*Creative*" 
    }

    if ($targetDevices) {
        foreach ($device in $targetDevices) {
            Write-Host "Toggling device: $($device.FriendlyName)..." -ForegroundColor Yellow
            Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "Successfully reinitialized: $($device.FriendlyName)" -ForegroundColor Green
        }
    } else {
        Write-Host "No specific Creative/Sound Blaster device found via PnP. Resetting generic USB audio controllers..." -ForegroundColor DarkGray
        
        $usbControllers = Get-PnpDevice -Class "USB" -Status "Error" -ErrorAction SilentlyContinue
        if ($usbControllers) {
            foreach ($controller in $usbControllers) {
                Write-Host "Restarting troubled USB controller: $($controller.FriendlyName)" -ForegroundColor Yellow
                Restart-PnpDevice -InstanceId $controller.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host "`nAdvanced fix routine complete." -ForegroundColor Cyan
    Pause
}

# Main Loop
$quit =$false

while (-not $quit) {
    Show-Menu
    $choice = Read-Host "Enter choice"

    switch ($choice) {
        "1" { Simple-Check }
        "2" { Detailed-Check }
        "3" { Advanced-Fix }
        "4" {
            Write-Host ""
            Write-Host "Thank you for using AudioHibernateFix. Goodbye!" -ForegroundColor Green
            Start-Sleep -Milliseconds 800
            $quit =$true
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
        }
    }
}