# Exchange Logs Cleanup Script

A safe PowerShell script to automatically clean up old Exchange log files based on file age, with support for:

- ✅ Age-based deletion (e.g., 90 days)
- ✅ Excluding critical files
- ✅ Logging all actions
- ✅ Safe testing using -WhatIf
- ✅ Ready for Task Scheduler automation

## Use Case
Prevents disk full issues caused by growing Exchange log files while keeping important logs protected.

## How to Test (Safe Mode)

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "ExchangeLogs-Cleanup.ps1" `
-LogPath "D:\ExchangeLogs" -DaysToKeep 90 -WhatIf

How to Run (Production)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "ExchangeLogs-Cleanup.ps1" `
-LogPath "D:\ExchangeLogs" -DaysToKeep 90

Example Exclusions
-ExcludePatterns "*CURRENT*","*.txt","health.log"

Scheduling with Task Scheduler

Run monthly at 2:00 AM with PowerShell as the action
