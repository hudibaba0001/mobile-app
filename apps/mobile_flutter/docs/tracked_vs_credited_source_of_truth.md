# Tracked vs Credited Source of Truth

## Base Units
- All business calculations use integer minutes.
- UI shows `Hh Mm` formatting.
- Export may show decimals, but totals must map to the same minute totals.

## Canonical Definitions
- Tracked minutes: `workMinutes + travelMinutes`
- Work minutes: `sum(entry.workDuration.inMinutes)` for `EntryType.work`
- Travel minutes: `travelEnabled ? sum(entry.travelDuration.inMinutes) : 0` for `EntryType.travel`
- Leave credited minutes: sum of paid leave minutes only (`vacationPaid`, `sickPaid`, `vabPaid`)
- Accounted minutes: `trackedMinutes + leaveCreditedMinutes`
- Delta minutes: `accountedMinutes - targetMinutes`

## Leave Minute Normalization
- Leave source field: `AbsenceEntry.minutes`
- If `minutes == 0`, treat as full leave day (`480` minutes by default).
- `unpaid` leave is excluded from credited leave minutes.

## Label Rules
- Never label Accounted as worked.
- Use explicit labels: Tracked, Leave, Accounted, Target, Delta.
- Daily/weekly trends remain tracked-only.
