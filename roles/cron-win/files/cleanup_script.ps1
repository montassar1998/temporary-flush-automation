# This PowerShell script performs cleanup operations on temporary and prefetch files
Set-ExecutionPolicy RemoteSigned
# Store the paths that were deleted in the script
$deletedPaths = @(
    "C:\Windows\Temp",
    "C:\WINDOWS\Prefetch",
    "$env:TEMP",
    "C:\Windows\Tempor~1",
    "C:\Windows\ff*.tmp"
)

# Function to check if the item exists in the deleted paths
function IsItemDeleted([string]$itemPath) {
    foreach ($path in $deletedPaths) {
        if ($itemPath -like "$path\*" -or $itemPath -eq $path) {
            return $true
        }
    }
    return $false
}

# Delete all files in C:\Windows\Temp
Get-ChildItem -Path "C:\Windows\Temp\*" -File -Force | Remove-Item -Force

# Remove the C:\Windows\Temp directory
Remove-Item -Path "C:\Windows\Temp" -Recurse -Force

# Recreate the C:\Windows\Temp directory
New-Item -ItemType Directory -Path "C:\Windows\Temp" | Out-Null

# Delete all files in C:\WINDOWS\Prefetch
Get-ChildItem -Path "C:\WINDOWS\Prefetch\*" -File -Force | Remove-Item -Force

# Delete all files in the user-specific temporary folder
$envTemp = $env:TEMP
Get-ChildItem -Path "$envTemp\*" -File -Force | Remove-Item -Force

# Remove the user-specific temporary folder
Remove-Item -Path $envTemp -Recurse -Force

# Recreate the user-specific temporary folder
New-Item -ItemType Directory -Path $envTemp | Out-Null

# Delete C:\Windows\Tempor~1 (if it exists)
Remove-Item -Path "C:\Windows\Tempor~1" -Recurse -Force -ErrorAction SilentlyContinue

# Delete C:\Windows\Temp (if it exists)
Remove-Item -Path "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue

# Delete C:\Windows\tmp (if it exists)
Remove-Item -Path "C:\Windows\tmp" -Recurse -Force -ErrorAction SilentlyContinue

# Delete all directories starting with "ff" and ending with ".tmp" in C:\Windows
Get-ChildItem -Path "C:\Windows\ff*.tmp" -Directory -Force | Remove-Item -Recurse -Force

# Delete C:\Windows\Prefetch (if it exists)
Remove-Item -Path "C:\Windows\Prefetch" -Recurse -Force -ErrorAction SilentlyContinue

# Delete C:\Windows\Recent (if it exists)
Remove-Item -Path "C:\Windows\Recent" -Recurse -Force -ErrorAction SilentlyContinue

# Create a Shell COM object
$shell = New-Object -ComObject Shell.Application

# Get the Recycle Bin folder
$recycleBin = $shell.Namespace(0xa)

# Loop through each item in the Recycle Bin and check if it matches the deleted paths
$itemsToDelete = @()
foreach ($item in $recycleBin.Items()) {
    $itemPath = $recycleBin.GetDetailsOf($item, 0) # Get the original path of the item
    if (IsItemDeleted -itemPath $itemPath) {
        $itemsToDelete += $item
    }
}

# Delete the selected items from the Recycle Bin
foreach ($item in $itemsToDelete) {
    $recycleBin.InvokeVerb("Delete", $item)
    Write-Host "Deleted item from Recycle Bin: $itemPath"
}


# Read the frequency and time from freq.txt
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$freqFile = Join-Path $scriptDir "freq.txt"
if (Test-Path $freqFile) {
    $schedule = Get-Content -Path $freqFile -Raw
}
else {
    Write-Host "Warning: freq.txt not found. Using default schedule (Daily at 10:00 AM)."
    $schedule = "Daily 10:00"
}

# Map the schedule frequency to corresponding task frequency
$taskFrequency = @{
    "Daily"   = "DAILY"
    "Weekly"  = "WEEKLY"
    "Monthly" = "MONTHLY"
}

# Function to get the current user's name
function Get-CurrentUserName {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $currentUserName = $currentUser.Name
    if ($currentUserName.StartsWith("NT AUTHORITY\SYSTEM")) {
        # If running as SYSTEM, try to get the admin username (if available)
        $currentUserName = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
    }
    return $currentUserName
}

# Schedule the task using Windows Task Scheduler
if ($taskFrequency.ContainsKey($schedule)) {
    $taskName = "TemporaryFilesDeletion"
    $actionScript = Join-Path $scriptDir "cleanup_script.ps1"

    # Remove any existing task with the same name
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    # Define the action for the task
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$actionScript`""

    # Define the trigger based on the schedule frequency
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date
    switch ($taskFrequency[$schedule]) {
        "DAILY" {
            $trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date).TimeOfDay
        }
        "WEEKLY" {
            $dayOfWeek = (Get-Date).DayOfWeek
            $trigger = New-ScheduledTaskTrigger -Weekly -At (Get-Date).TimeOfDay -DaysOfWeek $dayOfWeek
        }
        "MONTHLY" {
            $dayOfMonth = (Get-Date).Day
            $trigger = New-ScheduledTaskTrigger -Monthly -At (Get-Date).TimeOfDay -DaysOfMonth $dayOfMonth
        }
    }

    # Register the scheduled task
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -RunLevel Highest -User (Get-CurrentUserName) -Force
    Write-Host "Task has been scheduled $schedule."
}
else {
    Write-Host "Error: Invalid schedule frequency specified in freq.txt. Task scheduling aborted."
    exit
}

# Clear the console screen
Clear-Host