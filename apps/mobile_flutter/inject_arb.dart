import 'dart:convert';
import 'dart:io';

const enKeys = {
  "exportHeader_type": "Type",
  "exportHeader_date": "Date",
  "exportHeader_from": "From",
  "exportHeader_to": "To",
  "exportHeader_travelMinutes": "Travel Minutes",
  "exportHeader_travelDistance": "Travel Distance (km)",
  "exportHeader_shiftNumber": "Shift Number",
  "exportHeader_shiftStart": "Shift Start",
  "exportHeader_shiftEnd": "Shift End",
  "exportHeader_spanMinutes": "Span Minutes",
  "exportHeader_unpaidBreakMinutes": "Unpaid Break Minutes",
  "exportHeader_workedMinutes": "Worked Minutes",
  "exportHeader_workedHours": "Worked Hours",
  "exportHeader_shiftLocation": "Shift Location",
  "exportHeader_shiftNotes": "Shift Notes",
  "exportHeader_entryNotes": "Entry Notes",
  "exportHeader_createdAt": "Created At",
  "exportHeader_updatedAt": "Updated At",
  "exportHeader_holidayWork": "Holiday Work",
  "exportHeader_holidayName": "Holiday Name",
  "exportHeader_minutes": "Minutes",
  "exportHeader_notes": "Notes",
  "exportHeader_paidUnpaid": "Paid/Unpaid",
  "exportSummary_generatedAt": "Generated at",
  "exportSummary_trackedWork": "Tracked work",
  "exportSummary_trackedTravel": "Tracked travel",
  "exportSummary_balanceOffsets": "Balance offsets",
  "exportSummary_manualAdjustments": "Manual adjustments",
  "exportSummary_contractSettings": "Contract settings",
  "exportSummary_carryOver": "Carry-over from earlier",
  "exportSummary_manualCorrections": "Manual corrections in this period",
  "exportSummary_balanceAtStart": "Balance at start of selected period",
  "exportSummary_balanceAfterThis": "Balance after this period",
  "exportSummary_totalTrackedOnly": "TOTAL (tracked only)",
  "exportSummary_paidLeaveCredit": "Paid leave credit",
  "exportSummary_paidLeaveCreditNote":
      "Paid leave credit: {hours}h (not worked)",
  "exportSummary_totalTrackedExcludes":
      "TOTAL (tracked only) excludes Leave and Balance events. See {sheetName}.",
  "export_leaveSick": "Leave (Sick)",
  "export_leaveVab": "VAB",
  "export_leavePaidVacation": "Leave (Paid Vacation)",
  "export_leaveUnpaid": "Unpaid Leave",
  "export_leaveUnknown": "Leave (Unknown)",
  "export_paid": "Paid",
  "export_unpaid": "Unpaid",
  "export_yes": "Yes",
  "export_no": "No",
  "export_total": "TOTAL",
  "export_errorEmptyData": "Generated export data is empty",
  "export_errorUnsupportedFormat": "Unsupported export format",
  "export_errorMissingConfig": "Missing configuration",
  "export_summarySheetName": "Summary (Easy)",
  "export_balanceEventsSheetName": "Balance Events"
};

const svKeys = {
  "exportHeader_type": "Typ",
  "exportHeader_date": "Datum",
  "exportHeader_from": "Från",
  "exportHeader_to": "Till",
  "exportHeader_travelMinutes": "Restid (min)",
  "exportHeader_travelDistance": "Ressträcka (km)",
  "exportHeader_shiftNumber": "Arbetspass nr",
  "exportHeader_shiftStart": "Starttid pass",
  "exportHeader_shiftEnd": "Sluttid pass",
  "exportHeader_spanMinutes": "Längd inkl rast (min)",
  "exportHeader_unpaidBreakMinutes": "Obetald rast (min)",
  "exportHeader_workedMinutes": "Arbetade minuter",
  "exportHeader_workedHours": "Arbetade timmar",
  "exportHeader_shiftLocation": "Arbetsplats",
  "exportHeader_shiftNotes": "Anteckningar pass",
  "exportHeader_entryNotes": "Anteckningar post",
  "exportHeader_createdAt": "Skapad datum",
  "exportHeader_updatedAt": "Uppdaterad tid",
  "exportHeader_holidayWork": "Helgarbete",
  "exportHeader_holidayName": "Helgdagens namn",
  "exportHeader_minutes": "Minuter",
  "exportHeader_notes": "Anteckningar",
  "exportHeader_paidUnpaid": "Betald/Obetald",
  "exportSummary_generatedAt": "Genererad den",
  "exportSummary_trackedWork": "Spårat arbete",
  "exportSummary_trackedTravel": "Spårad restid",
  "exportSummary_balanceOffsets": "Saldohändelser",
  "exportSummary_manualAdjustments": "Manuella justeringar",
  "exportSummary_contractSettings": "Kontraktsinställningar",
  "exportSummary_carryOver": "Fört över från tidigare",
  "exportSummary_manualCorrections": "Manuella korrigeringar denna period",
  "exportSummary_balanceAtStart": "Saldo vid periodens början",
  "exportSummary_balanceAfterThis": "Saldo efter denna period",
  "exportSummary_totalTrackedOnly": "TOTALT (endast spårat)",
  "exportSummary_paidLeaveCredit": "Ersatt frånvaro",
  "exportSummary_paidLeaveCreditNote":
      "Tillgodoräknad frånvaro: {hours}h (ej arbetat)",
  "exportSummary_totalTrackedExcludes":
      "TOTALT (endast spårat) exkluderar frånvaro och saldohändelser. Se {sheetName}.",
  "export_leaveSick": "Sjukfrånvaro",
  "export_leaveVab": "VAB",
  "export_leavePaidVacation": "Semester",
  "export_leaveUnpaid": "Obetald frånvaro",
  "export_leaveUnknown": "Okänd ledighet",
  "export_paid": "Betald",
  "export_unpaid": "Obetald",
  "export_yes": "Ja",
  "export_no": "Nej",
  "export_total": "TOTALT",
  "export_errorEmptyData": "Genererad exportdata är tom",
  "export_errorUnsupportedFormat": "Exportformatet stöds inte",
  "export_errorMissingConfig": "Konfiguration saknas",
  "export_summarySheetName": "Sammanfattning (enkel)",
  "export_balanceEventsSheetName": "Saldohändelser"
};

void updateArb(String path, Map<String, String> keysToAdd) {
  final file = File(path);
  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;

  keysToAdd.forEach((k, v) {
    data[k] = v;
    // Add placeholders if needed
    if (k == 'exportSummary_paidLeaveCreditNote') {
      data['@$k'] = {
        "placeholders": {
          "hours": {"type": "String"}
        }
      };
    } else if (k == 'exportSummary_totalTrackedExcludes') {
      data['@$k'] = {
        "placeholders": {
          "sheetName": {"type": "String"}
        }
      };
    }
  });

  file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data) + '\n');
}

void main() {
  updateArb('lib/l10n/app_en.arb', enKeys);
  updateArb('lib/l10n/app_sv.arb', svKeys);
  print('Injected mapping for export labels in arb files.');
}
