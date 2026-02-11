<#  Exchange Logs Cleanup - Safe Version
    - Delete files older than X days
    - Exclude specific patterns/files
    - Logs actions to a file
    - Supports -WhatIf and -Confirm automatically
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "D:\ExchangeLogs",

    [Parameter(Mandatory=$false)]
    [int]$DaysToKeep = 90,

    [Parameter(Mandatory=$false)]
    [string[]]$ExcludePatterns = @(
        "*CURRENT*",
        "*Active*",
        "*.txt",
        "health.log"
    ),

    [Parameter(Mandatory=$false)]
    [string]$ActionLogPath = "C:\Scripts\Logs\ExchangeLogsCleanup.log"
)

# --- Safety checks ---
if (-not (Test-Path $LogPath)) {
    throw "LogPath not found: $LogPath"
}

# يمنع حذف شي لو المسار غلط/قصير بشكل خطير (مثل D:\ أو C:\)
$resolved = (Resolve-Path $LogPath).Path
if ($resolved.Length -lt 10 -or $resolved -match "^[A-Z]:\\$") {
    throw "Unsafe LogPath detected: $resolved"
}

# Ensure log folder exists
$logDir = Split-Path $ActionLogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$cutOffDate = (Get-Date).AddDays(-$DaysToKeep)

"==== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Start Cleanup | Path=$resolved | KeepDays=$DaysToKeep ====" | Out-File -FilePath $ActionLogPath -Append -Encoding utf8

$files = Get-ChildItem -Path $resolved -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutOffDate }

# Apply exclusions
$toProcess = $files | Where-Object {
    $file = $_
    $isExcluded = $false
    foreach ($pattern in $ExcludePatterns) {
        # تطابق على FullName + Name عشان تغطي جميع الحالات
        if ($file.FullName -like $pattern -or $file.Name -like $pattern) {
            $isExcluded = $true
            break
        }
    }
    return (-not $isExcluded)
}

"Found=$(($files | Measure-Object).Count) | AfterExclusions=$(($toProcess | Measure-Object).Count)" | Out-File -FilePath $ActionLogPath -Append -Encoding utf8

foreach ($f in $toProcess) {
    $msg = "DELETE CANDIDATE | $($f.FullName) | LastWrite=$($f.LastWriteTime)"
    $msg | Out-File -FilePath $ActionLogPath -Append -Encoding utf8

    if ($PSCmdlet.ShouldProcess($f.FullName, "Remove file")) {
        try {
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            "DELETED OK | $($f.FullName)" | Out-File -FilePath $ActionLogPath -Append -Encoding utf8
        } catch {
            "DELETE FAIL | $($f.FullName) | $($_.Exception.Message)" | Out-File -FilePath $ActionLogPath -Append -Encoding utf8
        }
    }
}

"==== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | End Cleanup ====" | Out-File -FilePath $ActionLogPath -Append -Encoding utf8
