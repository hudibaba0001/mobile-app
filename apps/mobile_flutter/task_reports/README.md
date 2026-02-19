# Task Reports

This folder stores completed task logs using numeric filenames:

- `1.md`
- `2.md`
- `3.md`

## Rule

Always create the next file number by checking the highest existing numeric filename and adding `+1`.

## Create New Report

From `apps/mobile_flutter`:

```powershell
@'
Full detailed task notes...
'@ | dart run tool/add_task_report.dart --title "Task Title"
```

Or inline:

```powershell
dart run tool/add_task_report.dart --title "Task Title" --details "Detailed notes"
```
