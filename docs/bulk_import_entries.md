# Bulk import work/travel entries (admin)

This script inserts test data directly into Supabase tables used by the app:
- `entries`
- `work_shifts`
- `travel_segments`

It is intended for super-admin/test data usage.

## 1) Prepare CSV

Use this template:
- `apps/mobile_flutter/tool/templates/bulk_entries_template.csv`

Columns:
- `type` = `work` or `travel`
- `date` = `YYYY-MM-DD`
- Work rows require: `start_time`, `end_time` (`HH:mm` or ISO datetime)
- Travel rows require: `from_location`, `to_location`, `travel_minutes`
- Optional: `unpaid_break_minutes`, `location`, `notes`

## 2) Run a dry run first

From `apps/mobile_flutter`:

```bash
dart run tool/bulk_import_entries.dart \
  --csv=tool/templates/bulk_entries_template.csv \
  --user-id=<target-user-uuid> \
  --supabase-url=https://<project-ref>.supabase.co \
  --service-role-key=<service-role-key> \
  --dry-run
```

## 3) Run the real import

```bash
dart run tool/bulk_import_entries.dart \
  --csv=tool/templates/bulk_entries_template.csv \
  --user-id=<target-user-uuid> \
  --supabase-url=https://<project-ref>.supabase.co \
  --service-role-key=<service-role-key>
```

## Notes

- The script uses the service role key because normal user RLS policies only allow inserting own data.
- For work rows, times are converted to UTC before insert (same behavior as app service).
- Keep service role key out of git and shell history when possible.
