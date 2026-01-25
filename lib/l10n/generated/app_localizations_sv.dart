// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'KvikTime';

  @override
  String get common_save => 'Spara';

  @override
  String get common_cancel => 'Avbryt';

  @override
  String get common_delete => 'Ta bort';

  @override
  String get common_edit => 'Redigera';

  @override
  String get common_back => 'Tillbaka';

  @override
  String get common_saved => 'sparad';

  @override
  String get common_updated => 'uppdaterad';

  @override
  String get common_add => 'Lägg till';

  @override
  String get common_done => 'Klar';

  @override
  String get common_retry => 'Försök igen';

  @override
  String get common_reset => 'Återställ';

  @override
  String get common_share => 'Dela';

  @override
  String get common_export => 'Exportera';

  @override
  String get common_refresh => 'Uppdatera';

  @override
  String get common_close => 'Stäng';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nej';

  @override
  String get common_ok => 'OK';

  @override
  String get common_optional => '(valfritt)';

  @override
  String get common_loading => 'Laddar...';

  @override
  String get common_error => 'Fel';

  @override
  String get common_success => 'Klart';

  @override
  String get common_today => 'Idag';

  @override
  String get common_thisWeek => 'Denna vecka';

  @override
  String get common_thisMonth => 'Denna månad';

  @override
  String get common_thisYear => 'I år';

  @override
  String common_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# dagar',
      one: '# dag',
    );
    return '$_temp0';
  }

  @override
  String common_hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# timmar',
      one: '# timme',
    );
    return '$_temp0';
  }

  @override
  String get nav_home => 'Hem';

  @override
  String get nav_calendar => 'Kalender';

  @override
  String get nav_reports => 'Rapporter';

  @override
  String get nav_settings => 'Inställningar';

  @override
  String get settings_title => 'Inställningar';

  @override
  String get settings_account => 'Konto';

  @override
  String get settings_signOut => 'Logga ut';

  @override
  String get settings_signUp => 'Registrera';

  @override
  String get settings_manageSubscription => 'Hantera prenumeration';

  @override
  String get settings_contractSettings => 'Anställningsinställningar';

  @override
  String get settings_contractDescription =>
      'Ange din tjänstgöringsgrad och arbetstid';

  @override
  String get settings_publicHolidays => 'Allmänna helgdagar';

  @override
  String get settings_autoMarkHolidays => 'Markera helgdagar automatiskt';

  @override
  String get settings_holidayRegion => 'Sverige (Svenska helgdagar)';

  @override
  String settings_viewHolidays(int year) {
    return 'Visa helgdagar för $year';
  }

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_themeLight => 'Ljust';

  @override
  String get settings_themeDark => 'Mörkt';

  @override
  String get settings_themeSystem => 'System';

  @override
  String get settings_language => 'Språk';

  @override
  String get settings_languageSystem => 'Systemstandard';

  @override
  String get settings_data => 'Data';

  @override
  String get settings_clearDemoData => 'Rensa demodata';

  @override
  String get settings_clearAllData => 'Rensa all data';

  @override
  String get settings_clearDemoDataConfirm =>
      'Detta tar bort alla demoposter. Är du säker?';

  @override
  String get settings_clearAllDataConfirm =>
      'Detta raderar ALL din data permanent. Åtgärden kan inte ångras. Är du säker?';

  @override
  String get settings_about => 'Om appen';

  @override
  String settings_version(String version) {
    return 'Version $version';
  }

  @override
  String get settings_terms => 'Användarvillkor';

  @override
  String get settings_privacy => 'Integritetspolicy';

  @override
  String get contract_title => 'Anställningsinställningar';

  @override
  String get contract_headerTitle => 'Anställningsinställningar';

  @override
  String get contract_headerDescription =>
      'Konfigurera din tjänstgöringsgrad och heltidstimmar för korrekt beräkning av arbetstid och övertid.';

  @override
  String get contract_percentage => 'Tjänstgöringsgrad';

  @override
  String get contract_percentageHint => 'Ange procent (0–100)';

  @override
  String get contract_percentageError => 'Procent måste vara mellan 0 och 100';

  @override
  String get contract_fullTimeHours => 'Heltidstimmar per vecka';

  @override
  String get contract_fullTimeHoursHint => 'Ange timmar per vecka (t.ex. 40)';

  @override
  String get contract_fullTimeHoursError => 'Timmar måste vara större än 0';

  @override
  String get contract_startingBalance => 'Startsaldo';

  @override
  String get contract_startingBalanceDescription =>
      'Ange din startpunkt för saldoberäkning. Fråga din chef om ditt flexsaldo per detta datum.';

  @override
  String get contract_startTrackingFrom => 'Börja räkna från';

  @override
  String get contract_openingBalance => 'Ingående flexsaldo';

  @override
  String get contract_creditPlus => 'Kredit (+)';

  @override
  String get contract_deficitMinus => 'Skuld (−)';

  @override
  String get contract_creditExplanation =>
      'Kredit betyder att du har extra tid (före schema)';

  @override
  String get contract_deficitExplanation =>
      'Skuld betyder att du är skyldig tid (efter schema)';

  @override
  String get contract_livePreview => 'Förhandsgranskning';

  @override
  String get contract_contractType => 'Anställningstyp';

  @override
  String get contract_fullTime => 'Heltid';

  @override
  String get contract_partTime => 'Deltid';

  @override
  String get contract_allowedHours => 'Tillåtna timmar';

  @override
  String get contract_dailyHours => 'Daglig arbetstid';

  @override
  String get contract_resetToDefaults => 'Återställ till standard';

  @override
  String get contract_resetConfirm =>
      'Detta återställer dina anställningsinställningar till 100% heltid med 40 timmar per vecka och rensar ditt startsaldo. Är du säker?';

  @override
  String get contract_saveSettings => 'Spara inställningar';

  @override
  String get contract_savedSuccess => 'Anställningsinställningar sparade!';

  @override
  String get contract_resetSuccess =>
      'Anställningsinställningar återställda till standard';

  @override
  String get contract_employerMode => 'Employer Mode';

  @override
  String get contract_modeStandard => 'Standard';

  @override
  String get contract_modeStrict => 'Strict';

  @override
  String get contract_modeFlexible => 'Flexible';

  @override
  String get contract_modeStrictDesc => 'Strict validation of hours';

  @override
  String get contract_modeFlexibleDesc => 'No warnings for overages';

  @override
  String get contract_modeStandardDesc => 'Standard balance tracking';

  @override
  String get balance_title => 'Flexsaldo';

  @override
  String balance_myTimeBalance(int year) {
    return 'Mitt flexsaldo ($year)';
  }

  @override
  String balance_thisYear(int year) {
    return 'DETTA ÅRET: $year';
  }

  @override
  String balance_thisMonth(String month) {
    return 'DENNA MÅNADEN: $month';
  }

  @override
  String balance_hoursWorkedToDate(String worked, String target) {
    return 'Arbetade timmar (hittills): $worked / $target h';
  }

  @override
  String balance_creditedHours(String hours) {
    return 'Tillgodoräknade timmar: $hours h';
  }

  @override
  String get balance_statusOver => 'Över';

  @override
  String get balance_statusUnder => 'Under';

  @override
  String balance_status(String variance, String status) {
    return 'Status: $variance h ($status)';
  }

  @override
  String balance_percentOfTarget(String percent) {
    return '$percent% av mål';
  }

  @override
  String get balance_yearlyRunningBalance => 'ÅRLIGT LÖPENDE SALDO';

  @override
  String get balance_totalAccumulation => 'Total ackumulering:';

  @override
  String get balance_inCredit => 'Du har kredit';

  @override
  String get balance_inDebt => 'Du har flexskuld';

  @override
  String balance_includesOpening(String balance, String date) {
    return 'Inkluderar ingående saldo ($balance) per $date';
  }

  @override
  String get adjustment_title => 'Saldojusteringar';

  @override
  String get adjustment_description =>
      'Manuella korrigeringar av ditt saldo (t.ex. chefsjusteringar)';

  @override
  String get adjustment_add => 'Lägg till justering';

  @override
  String get adjustment_edit => 'Redigera justering';

  @override
  String get adjustment_recent => 'Senaste justeringar';

  @override
  String get adjustment_effectiveDate => 'Giltighetsdatum';

  @override
  String get adjustment_amount => 'Belopp';

  @override
  String get adjustment_noteOptional => 'Anteckning (valfri)';

  @override
  String get adjustment_noteHint => 't.ex. Chefskorrigering';

  @override
  String get adjustment_deleteConfirm =>
      'Är du säker på att du vill ta bort denna justering?';

  @override
  String adjustment_saveError(String error) {
    return 'Kunde inte spara: $error';
  }

  @override
  String get adjustment_enterAmount => 'Ange ett justeringsbelopp';

  @override
  String get adjustment_minutesError => 'Minuter måste vara mellan 0 och 59';

  @override
  String get redDay_auto => 'Auto';

  @override
  String get redDay_personal => 'Personlig';

  @override
  String get redDay_fullDay => 'Heldag';

  @override
  String get redDay_halfDay => 'Halvdag';

  @override
  String get redDay_am => 'FM';

  @override
  String get redDay_pm => 'EM';

  @override
  String get redDay_publicHoliday => 'Allmän helgdag i Sverige';

  @override
  String redDay_autoMarked(String holidayName) {
    return 'Automatiskt markerad: $holidayName';
  }

  @override
  String get redDay_holidayWorkNotice =>
      'Detta är en allmän helgdag (Auto). Timmar som anges här kan räknas som helgarbete.';

  @override
  String get redDay_personalNotice =>
      'Röd dag (Personlig). Timmar kan räknas som helgarbete.';

  @override
  String get redDay_addPersonal => 'Lägg till personlig röd dag';

  @override
  String get redDay_editPersonal => 'Redigera personlig röd dag';

  @override
  String get redDay_reason => 'Anledning (valfri)';

  @override
  String get redDay_halfDayReducesScheduled =>
      'Halvdag minskar schemalagd tid med 50%.';

  @override
  String get leave_title => 'Ledighet';

  @override
  String leave_summary(int year) {
    return 'Ledighetssammanfattning $year';
  }

  @override
  String get leave_paidVacation => 'Semester';

  @override
  String get leave_sickLeave => 'Sjukfrånvaro';

  @override
  String get leave_vab => 'VAB';

  @override
  String get leave_unpaid => 'Tjänstledighet';

  @override
  String get leave_totalDays => 'Totalt antal dagar';

  @override
  String get leave_recent => 'Senaste ledigheter';

  @override
  String get leave_noRecords => 'Ingen ledighet registrerad';

  @override
  String get leave_historyAppears => 'Din ledighetshistorik visas här';

  @override
  String leave_daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '1 dag',
      zero: '0 dagar',
    );
    return '$_temp0';
  }

  @override
  String get reports_title => 'Rapporter & Analys';

  @override
  String get reports_overview => 'Översikt';

  @override
  String get reports_trends => 'Trender';

  @override
  String get reports_timeBalance => 'Flexsaldo';

  @override
  String get reports_leaves => 'Ledighet';

  @override
  String get reports_exportData => 'Exportera data';

  @override
  String get reports_serverAnalytics => 'Serveranalys';

  @override
  String get export_title => 'Exportera data';

  @override
  String get export_format => 'Format';

  @override
  String get export_excel => 'Excel';

  @override
  String get export_csv => 'CSV';

  @override
  String get export_dateRange => 'Datumintervall';

  @override
  String get export_allTime => 'All tid';

  @override
  String get export_fileName => 'Filnamn';

  @override
  String export_generating(String format) {
    return 'Genererar $format-export...';
  }

  @override
  String get export_complete => 'Export klar';

  @override
  String export_savedSuccess(String format) {
    return '$format-fil har sparats.';
  }

  @override
  String get export_sharePrompt => 'Vill du dela via e-post eller annan app?';

  @override
  String export_downloadedSuccess(String format) {
    return '$format-fil har laddats ned!';
  }

  @override
  String export_failed(String error) {
    return 'Export misslyckades: $error';
  }

  @override
  String get export_noData => 'Ingen data att exportera';

  @override
  String get export_noEntries =>
      'Inga poster att exportera. Välj poster med data.';

  @override
  String get home_todaysTotals => 'Dagens totaler';

  @override
  String get home_weeklyStats => 'Veckans statistik';

  @override
  String get home_quickActions => 'Snabbåtgärder';

  @override
  String get home_recentEntries => 'Senaste poster';

  @override
  String get home_addWork => 'Lägg till arbete';

  @override
  String get home_addTravel => 'Lägg till resa';

  @override
  String get home_addLeave => 'Lägg till ledighet';

  @override
  String get home_viewAll => 'Visa alla';

  @override
  String get home_noEntries => 'Inga senaste poster';

  @override
  String get home_holidayWork => 'Helgarbete';

  @override
  String get entry_travel => 'Resa';

  @override
  String get entry_work => 'Arbete';

  @override
  String travel_legLabel(int number) {
    return 'Resa $number';
  }

  @override
  String get travel_addLeg => 'Lägg till reseben';

  @override
  String get travel_addAnotherLeg => 'Lägg till ytterligare resa';

  @override
  String get travel_sourceAuto => 'Auto';

  @override
  String get travel_sourceManual => 'Manuell';

  @override
  String get travel_total => 'Total resa';

  @override
  String get entry_from => 'Från';

  @override
  String get entry_to => 'Till';

  @override
  String get entry_duration => 'Varaktighet';

  @override
  String get entry_date => 'Datum';

  @override
  String get entry_notes => 'Anteckningar (Valfritt)';

  @override
  String get entry_shifts => 'Pass';

  @override
  String get entry_addShift => 'Lägg till pass';

  @override
  String get error_loadingData => 'Fel vid laddning av data';

  @override
  String get error_loadingBalance => 'Fel vid laddning av saldo';

  @override
  String get error_userNotAuth => 'Användaren är inte inloggad';

  @override
  String get error_generic => 'Något gick fel';

  @override
  String get error_networkError => 'Nätverksfel. Kontrollera din anslutning.';

  @override
  String get absence_title => 'Frånvaro';

  @override
  String get absence_addAbsence => 'Lägg till frånvaro';

  @override
  String get absence_editAbsence => 'Redigera frånvaro';

  @override
  String get absence_deleteAbsence => 'Ta bort frånvaro';

  @override
  String get absence_deleteConfirm =>
      'Är du säker på att du vill ta bort denna frånvaro?';

  @override
  String absence_noAbsences(int year) {
    return 'Ingen frånvaro för $year';
  }

  @override
  String get absence_addHint =>
      'Tryck + för att lägga till semester, sjukfrånvaro eller VAB';

  @override
  String get absence_errorLoading => 'Fel vid laddning av frånvaro';

  @override
  String get absence_type => 'Frånvarotyp';

  @override
  String get absence_date => 'Datum';

  @override
  String get absence_halfDay => 'Halvdag';

  @override
  String get absence_fullDay => 'Heldag';

  @override
  String get absence_notes => 'Anteckningar';

  @override
  String get absence_savedSuccess => 'Frånvaro sparad';

  @override
  String get absence_deletedSuccess => 'Frånvaro borttagen';

  @override
  String get absence_saveFailed => 'Kunde inte spara frånvaro';

  @override
  String get absence_deleteFailed => 'Kunde inte ta bort frånvaro';

  @override
  String get settings_manageLocations => 'Hantera platser';

  @override
  String get settings_manageLocationsDesc =>
      'Lägg till och redigera vanliga platser';

  @override
  String get settings_absences => 'Frånvaro';

  @override
  String get settings_absencesDesc => 'Hantera semester, sjukfrånvaro och VAB';

  @override
  String get settings_subscriptionDesc =>
      'Uppdatera betalningsmetod och prenumerationsplan';

  @override
  String get settings_welcomeScreen => 'Visa välkomstskärm';

  @override
  String get settings_welcomeScreenDesc => 'Visa introduktion vid nästa start';

  @override
  String get settings_region => 'Region';

  @override
  String get common_unknown => 'Okänd';

  @override
  String get common_noRemarks => 'Inga anteckningar';

  @override
  String get common_workSession => 'Arbetspass';

  @override
  String get common_confirmDelete => 'Bekräfta borttagning';

  @override
  String common_durationFormat(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get common_profile => 'Profil';

  @override
  String common_required(String field) {
    return '$field krävs';
  }

  @override
  String get common_invalidNumber => 'Ange ett giltigt nummer';

  @override
  String get common_noDataToExport => 'No data to export';

  @override
  String get common_exportSuccess => 'Export successful';

  @override
  String get common_exportFailed => 'Export failed';

  @override
  String get home_title => 'Tidrapportering';

  @override
  String get home_subtitle => 'Spåra din produktivitet';

  @override
  String get home_logTravel => 'Logga resa';

  @override
  String get home_logWork => 'Logga arbete';

  @override
  String get home_quickEntry => 'Snabbinmatning';

  @override
  String get home_quickTravelEntry => 'Snabb reseinmatning';

  @override
  String get home_quickWorkEntry => 'Snabb arbetsinmatning';

  @override
  String get home_noEntriesYet => 'Inga poster ännu';

  @override
  String get home_viewAllArrow => 'Visa alla →';

  @override
  String home_travelRoute(String from, String to) {
    return 'Resa: $from → $to';
  }

  @override
  String get home_fullDay => 'Heldag';

  @override
  String get entry_deleteEntry => 'Ta bort post';

  @override
  String entry_deleteConfirm(String type) {
    return 'Är du säker på att du vill ta bort denna $type-post?';
  }

  @override
  String entry_deletedSuccess(String type) {
    return '$type-post borttagen';
  }

  @override
  String error_deleteFailed(String error) {
    return 'Kunde inte ta bort post: $error';
  }

  @override
  String error_loadingEntries(String error) {
    return 'Fel vid laddning av poster: $error';
  }

  @override
  String get contract_maxHoursError =>
      'Timmar kan inte överstiga 168 per vecka';

  @override
  String get contract_invalidHours => 'Ogiltiga timmar';

  @override
  String get contract_minutesError => 'Minuter måste vara 0–59';

  @override
  String contract_hoursPerDayValue(String hours) {
    return '$hours timmar/dag';
  }

  @override
  String get contract_hrsWeek => 'tim/vecka';

  @override
  String export_shareSubject(String fileName) {
    return 'Tidrapport-export - $fileName';
  }

  @override
  String get export_shareText => 'Bifogat finner du tidrapporten.';

  @override
  String error_shareFile(String error) {
    return 'Kunde inte dela fil: $error';
  }

  @override
  String get entry_saveEntry => 'Spara post';

  @override
  String get entry_editEntry => 'Redigera post';

  @override
  String get entry_deleteTitle => 'Ta bort post';

  @override
  String get error_selectBothLocations => 'Välj både avgångs- och ankomstplats';

  @override
  String get error_selectWorkLocation => 'Välj en arbetsplats';

  @override
  String get error_selectEndTime => 'Välj en sluttid';

  @override
  String get error_signInRequired => 'Logga in för att spara poster';

  @override
  String error_savingEntry(String error) {
    return 'Fel vid sparande av post: $error';
  }

  @override
  String error_calculatingTravelTime(String error) {
    return 'Kunde inte beräkna restid: $error';
  }

  @override
  String get error_invalidHours => 'Timmar måste vara ett icke-negativt tal';

  @override
  String get error_invalidMinutes => 'Minuter måste vara mellan 0 och 59';

  @override
  String get error_durationRequired => 'Ange en giltig längd (större än 0)';

  @override
  String get error_endTimeBeforeStart => 'Sluttid måste vara efter starttid';

  @override
  String error_invalidShiftTime(int number) {
    return 'Skift $number har ogiltiga tider (sluttid måste vara efter starttid)';
  }

  @override
  String get form_departure => 'Avgång';

  @override
  String get form_arrival => 'Ankomst';

  @override
  String get form_location => 'Plats';

  @override
  String get form_date => 'Datum';

  @override
  String get form_startTime => 'Starttid';

  @override
  String get form_endTime => 'Sluttid';

  @override
  String get form_duration => 'Längd';

  @override
  String get form_notesOptional => 'Anteckningar (valfritt)';

  @override
  String get form_selectLocation => 'Välj en plats';

  @override
  String get form_calculateFromLocations => 'Beräkna från platser';

  @override
  String get form_manualDuration => 'Manuell längd';

  @override
  String get form_hours => 'Timmar';

  @override
  String get form_minutes => 'Minuter';

  @override
  String get form_unpaidBreakMinutes => 'Obetald rast (min)';

  @override
  String form_shiftLabel(int number) {
    return 'Skift $number';
  }

  @override
  String get form_span => 'Spann';

  @override
  String get form_break => 'Rast';

  @override
  String get form_worked => 'Arbetat';

  @override
  String get form_useLocationForAllShifts =>
      'Använd denna plats för alla skift';

  @override
  String get form_shiftLocation => 'Skiftplats';

  @override
  String get form_shiftNotes => 'Skiftanteckningar';

  @override
  String get form_shiftNotesHint =>
      'Lägg till anteckningar för detta skift (t.ex. specifika uppgifter, problem)';

  @override
  String get form_sameAsDefault => 'Samma som standard';

  @override
  String get form_dayNotes => 'Daganteckningar';

  @override
  String get export_includeAllData => 'Inkludera all data';

  @override
  String get export_includeAllDataDesc => 'Exportera alla poster oavsett datum';

  @override
  String get export_startDate => 'Startdatum';

  @override
  String get export_endDate => 'Slutdatum';

  @override
  String get export_selectStartDate => 'Välj startdatum';

  @override
  String get export_selectEndDate => 'Välj slutdatum';

  @override
  String get export_entryType => 'Posttyp';

  @override
  String get export_travelOnly => 'Endast reseposter';

  @override
  String get export_travelOnlyDesc => 'Exportera endast restidsposter';

  @override
  String get export_workOnly => 'Endast arbetsposter';

  @override
  String get export_workOnlyDesc => 'Exportera endast arbetsskiftsposter';

  @override
  String get export_both => 'Båda';

  @override
  String get export_bothDesc => 'Exportera alla poster (resa + arbete)';

  @override
  String get export_formatTitle => 'Exportformat';

  @override
  String get export_excelFormat => 'Excel (.xlsx)';

  @override
  String get export_excelDesc => 'Professionellt format med formatering';

  @override
  String get export_csvFormat => 'CSV (.csv)';

  @override
  String get export_csvDesc => 'Enkelt textformat';

  @override
  String get export_options => 'Exportalternativ';

  @override
  String get export_filename => 'Filnamn';

  @override
  String get export_filenameHint => 'Ange anpassat filnamn';

  @override
  String get export_summary => 'Exportsammanfattning';

  @override
  String export_totalEntries(int count) {
    return 'Totalt antal poster: $count';
  }

  @override
  String export_travelEntries(int count) {
    return 'Reseposter: $count';
  }

  @override
  String export_workEntries(int count) {
    return 'Arbetsposter: $count';
  }

  @override
  String export_totalHours(String hours) {
    return 'Totalt timmar: $hours';
  }

  @override
  String get export_button => 'Exportera';

  @override
  String get export_enterFilename => 'Ange ett filnamn';

  @override
  String get export_noEntriesInRange =>
      'Inga poster hittades för valt datumintervall';

  @override
  String export_errorPreparing(String error) {
    return 'Fel vid förberedelse av export: $error';
  }

  @override
  String get redDay_editRedDay => 'Redigera röd dag';

  @override
  String get redDay_markAsRedDay => 'Markera som röd dag';

  @override
  String get redDay_duration => 'Längd';

  @override
  String get redDay_morningAM => 'Förmiddag (FM)';

  @override
  String get redDay_afternoonPM => 'Eftermiddag (EM)';

  @override
  String get redDay_reasonHint => 't.ex. Ledig dag, Läkarbesök...';

  @override
  String get redDay_remove => 'Ta bort';

  @override
  String get redDay_removeTitle => 'Ta bort röd dag?';

  @override
  String get redDay_removeMessage =>
      'Detta tar bort markeringen för personlig röd dag från detta datum.';

  @override
  String get redDay_updated => 'Röd dag uppdaterad';

  @override
  String get redDay_added => 'Röd dag tillagd';

  @override
  String get redDay_removed => 'Röd dag borttagen';

  @override
  String redDay_errorSaving(String error) {
    return 'Fel vid sparande av röd dag: $error';
  }

  @override
  String redDay_errorRemoving(String error) {
    return 'Fel vid borttagning av röd dag: $error';
  }

  @override
  String get adjustment_editAdjustment => 'Redigera justering';

  @override
  String get adjustment_addAdjustment => 'Lägg till justering';

  @override
  String get adjustment_deleteTitle => 'Ta bort justering';

  @override
  String get adjustment_deleteMessage =>
      'Är du säker på att du vill ta bort denna justering?';

  @override
  String get adjustment_update => 'Uppdatera';

  @override
  String adjustment_failedToSave(String error) {
    return 'Kunde inte spara: $error';
  }

  @override
  String adjustment_failedToDelete(String error) {
    return 'Kunde inte ta bort: $error';
  }

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_notSignedIn => 'Inte inloggad';

  @override
  String get profile_editName => 'Redigera namn';

  @override
  String get profile_nameUpdated => 'Namn uppdaterat';

  @override
  String profile_nameUpdateFailed(String error) {
    return 'Kunde inte uppdatera namn: $error';
  }

  @override
  String get location_addLocation => 'Lägg till plats';

  @override
  String get location_addFirstLocation => 'Lägg till första platsen';

  @override
  String get location_deleteLocation => 'Ta bort plats';

  @override
  String location_deleteConfirm(String name) {
    return 'Är du säker på att du vill ta bort \"$name\"?';
  }

  @override
  String get location_manageLocations => 'Hantera platser';

  @override
  String auth_signupFailed(String error) {
    return 'Kunde inte öppna registreringssidan: $error';
  }

  @override
  String auth_subscriptionFailed(String error) {
    return 'Kunde inte öppna prenumerationssidan: $error';
  }

  @override
  String get auth_completeRegistration => 'Slutför registrering';

  @override
  String get auth_openSignupPage => 'Öppna registreringssidan';

  @override
  String get auth_signOut => 'Logga ut';

  @override
  String get password_resetTitle => 'Återställ lösenord';

  @override
  String get password_forgotTitle => 'Glömt ditt lösenord?';

  @override
  String get password_forgotDescription =>
      'Ange din e-postadress så skickar vi en länk för att återställa ditt lösenord.';

  @override
  String get password_emailLabel => 'E-post';

  @override
  String get password_emailHint => 'Ange din e-postadress';

  @override
  String get password_emailRequired => 'E-post krävs';

  @override
  String get password_emailInvalid => 'Ange en giltig e-postadress';

  @override
  String get password_sendResetLink => 'Skicka återställningslänk';

  @override
  String get password_backToSignIn => 'Tillbaka till inloggning';

  @override
  String get password_resetLinkSent =>
      'Återställningslänk skickad till din e-post';

  @override
  String get welcome_title => 'Välkommen till KvikTime';

  @override
  String get welcome_subtitle => 'Spåra din restid enkelt';

  @override
  String get welcome_signIn => 'Logga in';

  @override
  String get welcome_getStarted => 'Kom igång';

  @override
  String get welcome_footer =>
      'Ny på KvikTime? Skapa ett konto för att komma igång.';

  @override
  String get welcome_urlError =>
      'Kunde inte öppna registreringssidan. Försök igen.';

  @override
  String get edit_title => 'Redigera post';

  @override
  String get edit_travel => 'Resa';

  @override
  String get edit_work => 'Arbete';

  @override
  String get edit_addTravelEntry => 'Lägg till resepost';

  @override
  String get edit_addShift => 'Lägg till skift';

  @override
  String get edit_notes => 'Anteckningar';

  @override
  String get edit_notesHint => 'Lägg till ytterligare anteckningar...';

  @override
  String get edit_travelNotesHint =>
      'Lägg till ytterligare anteckningar för alla reseposter...';

  @override
  String edit_trip(int number) {
    return 'Resa $number';
  }

  @override
  String edit_shift(int number) {
    return 'Skift $number';
  }

  @override
  String get edit_from => 'Från';

  @override
  String get edit_to => 'Till';

  @override
  String get edit_departureHint => 'Avgångsplats';

  @override
  String get edit_destinationHint => 'Destinationsplats';

  @override
  String get edit_hours => 'Timmar';

  @override
  String get edit_minutes => 'Minuter';

  @override
  String get edit_total => 'Totalt';

  @override
  String get edit_startTime => 'Starttid';

  @override
  String get edit_endTime => 'Sluttid';

  @override
  String get edit_selectTime => 'Välj tid';

  @override
  String get edit_toLabel => 'till';

  @override
  String get edit_save => 'Spara';

  @override
  String get edit_cancel => 'Avbryt';

  @override
  String edit_errorSaving(String error) {
    return 'Fel vid sparande av post: $error';
  }

  @override
  String get editMode_singleEntryInfo_work =>
      'Redigerar en post. För att lägga till ytterligare ett skift för detta datum, skapa en ny post.';

  @override
  String get editMode_singleEntryInfo_travel =>
      'Redigerar en post. För att lägga till ytterligare en resa för detta datum, skapa en ny post.';

  @override
  String get editMode_addNewEntryForDate => 'Lägg till ny post för detta datum';

  @override
  String get dateRange_title => 'Välj datumintervall';

  @override
  String get dateRange_description => 'Välj en tidsperiod att analysera';

  @override
  String get dateRange_quickSelections => 'Snabbval';

  @override
  String get dateRange_customRange => 'Anpassat intervall';

  @override
  String get dateRange_startDate => 'Startdatum';

  @override
  String get dateRange_endDate => 'Slutdatum';

  @override
  String get dateRange_apply => 'Tillämpa';

  @override
  String get dateRange_last7Days => 'Senaste 7 dagarna';

  @override
  String get dateRange_last30Days => 'Senaste 30 dagarna';

  @override
  String get dateRange_thisMonth => 'Denna månad';

  @override
  String get dateRange_lastMonth => 'Förra månaden';

  @override
  String get dateRange_thisYear => 'Detta år';

  @override
  String get quickEntry_signInRequired => 'Logga in för att lägga till poster.';

  @override
  String quickEntry_error(String error) {
    return 'Fel: $error';
  }

  @override
  String get quickEntry_multiSegment => 'Flera segment';

  @override
  String get quickEntry_clear => 'Rensa';

  @override
  String location_saved(String name) {
    return 'Plats \"$name\" sparad!';
  }

  @override
  String get location_saveTitle => 'Spara plats';

  @override
  String location_address(String address) {
    return 'Adress: $address';
  }

  @override
  String get dev_addSampleData => 'Lägg till exempeldata';

  @override
  String get dev_addSampleDataDesc => 'Skapa testposter från senaste veckan';

  @override
  String get dev_sampleDataAdded => 'Exempeldata tillagd';

  @override
  String dev_sampleDataFailed(String error) {
    return 'Kunde inte lägga till exempeldata: $error';
  }

  @override
  String get dev_signInRequired => 'Logga in för att lägga till exempeldata.';

  @override
  String get dev_syncing => 'Synkar till Supabase...';

  @override
  String get dev_syncSuccess => '✅ Synkning slutförd!';

  @override
  String dev_syncFailed(String error) {
    return '❌ Synkning misslyckades: $error';
  }

  @override
  String get dev_syncToSupabase => 'Synka till Supabase';

  @override
  String get dev_syncToSupabaseDesc =>
      'Synka lokala poster manuellt till Supabase-molnet';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get settings_languageSwedish => 'Svenska';

  @override
  String get simpleEntry_validDuration => 'Ange en giltig längd';

  @override
  String simpleEntry_entrySaved(String type, String action) {
    return '$type post $action! 🎉';
  }

  @override
  String get account_createTitle => 'Skapa konto';

  @override
  String get account_createOnWeb => 'Skapa ditt konto på webben';

  @override
  String get account_createDescription =>
      'För att skapa ett konto, besök vår registreringssida i din webbläsare.';

  @override
  String get account_openSignupPage => 'Öppna registreringssidan';

  @override
  String get account_alreadyHaveAccount => 'Jag har redan ett konto → Logga in';

  @override
  String get history_currentlySelected => 'För närvarande vald';

  @override
  String history_tapToFilter(String label) {
    return 'Tryck för att filtrera efter $label poster';
  }

  @override
  String history_holidayWork(String name) {
    return 'Högtidsarbete: $name';
  }

  @override
  String get history_redDay => 'Röd dag';

  @override
  String get history_noDescription => 'Ingen beskrivning';

  @override
  String get history_title => 'Historik';

  @override
  String get history_travel => 'Resa';

  @override
  String get history_worked => 'Arbetat';

  @override
  String get history_totalWorked => 'Totalt arbetat';

  @override
  String get history_work => 'Arbete';

  @override
  String get history_all => 'Alla';

  @override
  String get history_yesterday => 'Igår';

  @override
  String get history_last7Days => 'Senaste 7 dagarna';

  @override
  String get history_custom => 'Anpassad';

  @override
  String get history_searchHint => 'Sök efter plats, anteckningar...';

  @override
  String get history_loadingEntries => 'Laddar poster...';

  @override
  String get history_noEntriesFound => 'Inga poster hittades';

  @override
  String get history_tryAdjustingFilters =>
      'Försök justera dina filter eller söktermer';

  @override
  String get history_holidayWorkBadge => 'Högtidsarbete';

  @override
  String get history_autoBadge => 'Auto';

  @override
  String history_autoMarked(String name) {
    return 'Auto-markerad: $name';
  }

  @override
  String get overview_totalHours => 'Totalt antal timmar';

  @override
  String get overview_allActivities => 'Alla aktiviteter';

  @override
  String get overview_totalEntries => 'Totalt antal poster';

  @override
  String get overview_thisPeriod => 'Denna period';

  @override
  String get overview_travelTime => 'Resetid';

  @override
  String get overview_totalCommute => 'Total pendling';

  @override
  String get overview_workTime => 'Arbetstid';

  @override
  String get overview_totalWork => 'Totalt arbete';

  @override
  String get overview_quickInsights => 'Snabbinsikter';

  @override
  String get overview_activityDistribution => 'Aktivitetsfördelning';

  @override
  String get overview_recentActivity => 'Senaste aktivitet';

  @override
  String get overview_viewAll => 'Visa alla';

  @override
  String get overview_noDataAvailable => 'Ingen data tillgänglig';

  @override
  String get overview_errorLoadingData => 'Fel vid laddning av data';

  @override
  String get overview_travel => 'Resa';

  @override
  String get overview_work => 'Arbete';

  @override
  String get location_fullAddress => 'Fullständig adress';

  @override
  String get auth_legalRequired => 'Juridisk godkännande krävs';

  @override
  String get auth_legalDescription =>
      'Du måste godkänna våra användarvillkor och integritetspolicy för att fortsätta använda appen.';

  @override
  String get auth_legalVisitSignup =>
      'Besök vår registreringssida för att slutföra detta steg.';

  @override
  String get entry_logTravelEntry => 'Logga resepost';

  @override
  String get entry_logWorkEntry => 'Logga arbete';

  @override
  String get trends_monthlyComparison => 'Månadsjämförelse';

  @override
  String get trends_currentMonth => 'Nuvarande månad';

  @override
  String get trends_previousMonth => 'Föregående månad';

  @override
  String get trends_workHours => 'Arbetstimmar';

  @override
  String get trends_weeklyHours => 'Veckotimmar';

  @override
  String get trends_dailyTrends => 'Dagliga trender (Senaste 7 dagarna)';

  @override
  String get trends_total => 'totalt';

  @override
  String get trends_work => 'arbete';

  @override
  String get trends_travel => 'resa';

  @override
  String get leave_recentLeaves => 'Senaste ledigheter';

  @override
  String get leave_fullDay => 'Heldag';

  @override
  String get leave_totalLeaveDays => 'Totalt antal ledighetsdagar';

  @override
  String get leave_noLeavesRecorded => 'Inga ledigheter registrerade';

  @override
  String get leave_noLeavesDescription => 'Din ledighetshistorik visas här';

  @override
  String get insight_peakPerformance => 'Topprestanda';

  @override
  String insight_peakPerformanceDesc(String day, String hours) {
    return 'Din mest produktiva dag var $day med $hours timmar';
  }

  @override
  String get insight_locationInsights => 'Platsinsikter';

  @override
  String insight_locationInsightsDesc(String location) {
    return '$location är din mest frekventa plats';
  }

  @override
  String get insight_timeManagement => 'Tidsplanering';

  @override
  String insight_timeManagementDesc(String hours) {
    return 'Du arbetade $hours timmar under denna period';
  }

  @override
  String get profile_signOut => 'Logga ut';

  @override
  String get form_dateTime => 'Datum & Tid';

  @override
  String get form_travelRoute => 'Resväg';

  @override
  String get form_workLocation => 'Arbetsplats';

  @override
  String get form_workDetails => 'Arbetsdetaljer';

  @override
  String get nav_history => 'Historik';

  @override
  String balance_thisWeek(String range) {
    return 'DENNA VECKAN: $range';
  }

  @override
  String balance_hoursWorked(String worked, String target) {
    return 'Arbetade timmar (hittills): $worked / $target h';
  }

  @override
  String get balance_over => 'Över';

  @override
  String get balance_under => 'Under';

  @override
  String get balance_timeDebt => 'Du har en tidskuld';

  @override
  String balance_includesOpeningBalance(String balance, String date) {
    return 'Inkluderar startsaldo ($balance) per $date';
  }

  @override
  String balance_includesOpeningBalanceShort(String balance) {
    return 'Inkluderar startsaldo ($balance)';
  }

  @override
  String get locations_errorLoading => 'Fel vid laddning av data';

  @override
  String get locations_distribution => 'Platsfördelning';

  @override
  String get locations_details => 'Platsdetaljer';

  @override
  String get locations_noData => 'Ingen platsdata';

  @override
  String get locations_noDataDescription =>
      'Inga poster hittades för den valda perioden';

  @override
  String get locations_noDataAvailable => 'Ingen platsdata tillgänglig';

  @override
  String get locations_totalHours => 'Totalt antal timmar';

  @override
  String get locations_entries => 'Poster';

  @override
  String get locations_workTime => 'Arbetstid';

  @override
  String get locations_travelTime => 'Restid';

  @override
  String get chart_timeDistribution => 'Tidsfördelning';

  @override
  String get chart_workTime => 'Arbetstid';

  @override
  String get chart_travelTime => 'Restid';

  @override
  String get chart_totalTime => 'Total tid';

  @override
  String get chart_noDataAvailable => 'Ingen data tillgänglig';

  @override
  String get chart_startTracking => 'Börja spåra din tid för att se statistik';

  @override
  String get chart_allTime => 'Hela tiden';

  @override
  String get chart_today => 'Idag';

  @override
  String get balance_todaysBalance => 'Dagens saldo';

  @override
  String get balance_workVsTravel => 'Arbete vs resa';

  @override
  String get balance_balanced => 'Balanserad';

  @override
  String get balance_unbalanced => 'Ob balanserad';

  @override
  String get balance_work => 'Arbete';

  @override
  String get balance_travel => 'Resa';

  @override
  String get balance_entries => 'Poster';

  @override
  String get settings_darkMode => 'Mörkt läge';

  @override
  String get settings_darkModeActive => 'Mörkt tema är aktivt';

  @override
  String get settings_switchToDark => 'Växla till mörkt tema';

  @override
  String get settings_darkModeEnabled => 'Mörkt läge aktiverat';

  @override
  String get settings_lightModeEnabled => 'Ljust läge aktiverat';

  @override
  String get entry_endTime => 'Sluttid';

  @override
  String get entry_fromHint => 'Ange avgångsplats';

  @override
  String get entry_toHint => 'Ange ankomstplats';

  @override
  String get entry_location => 'Plats';

  @override
  String get entry_locationHint => 'Ange arbetsplats';

  @override
  String get entry_hours => 'Timmar';

  @override
  String get entry_minutes => 'Minuter';

  @override
  String get entry_shift => 'Skift';

  @override
  String get entry_notesHint => 'Lägg till ytterligare detaljer...';

  @override
  String get entry_calculating => 'Beräknar...';

  @override
  String get entry_calculateTravelTime => 'Beräkna restid';

  @override
  String entry_travelTimeCalculated(String duration, String distance) {
    return 'Restid beräknad: $duration ($distance)';
  }

  @override
  String entry_total(String duration) {
    return 'Totalt: $duration';
  }

  @override
  String get entry_publicHoliday => 'Allmän helgdag';

  @override
  String get entry_publicHolidaySweden => 'Allmän helgdag i Sverige';

  @override
  String get entry_redDayWarning =>
      'Röd dag. Timmar som anges här kan räknas som helgdagsarbete.';

  @override
  String get entry_personalRedDay => 'Personlig röd dag';

  @override
  String get error_addAtLeastOneShift => 'Vänligen lägg till minst ett skift.';

  @override
  String get shift_morning => 'Morgonskift';

  @override
  String get shift_afternoon => 'Eftermiddagsskift';

  @override
  String get shift_evening => 'Kvällsskift';

  @override
  String get shift_night => 'Nattskift';

  @override
  String get shift_unknown => 'Okänt skift';

  @override
  String get simpleEntry_fromLocation => 'Från plats';

  @override
  String get simpleEntry_toLocation => 'Till plats';

  @override
  String get simpleEntry_pleaseEnterDeparture => 'Vänligen ange avgångsplats';

  @override
  String get simpleEntry_pleaseEnterArrival => 'Vänligen ange ankomstplats';

  @override
  String get quickEntry_editEntry => 'Redigera post';

  @override
  String get quickEntry_quickEntry => 'Snabbpost';

  @override
  String get quickEntry_travelTimeMinutes => 'Restid (minuter)';

  @override
  String get quickEntry_travelTimeHint => 't.ex. 45';

  @override
  String get quickEntry_additionalInfo => 'Ytterligare information (Valfritt)';

  @override
  String get quickEntry_additionalInfoHint => 'Anteckningar, förseningar, etc.';

  @override
  String get quickEntry_updateEntry => 'Uppdatera post';

  @override
  String get quickEntry_addEntry => 'Lägg till post';

  @override
  String get quickEntry_saving => 'Sparar...';

  @override
  String get multiSegment_editJourney => 'Redigera flersegmentsresa';

  @override
  String get multiSegment_journey => 'Flersegmentsresa';

  @override
  String get multiSegment_journeySegments => 'Resesegment';

  @override
  String get multiSegment_firstSegment => 'Första segmentet';

  @override
  String get multiSegment_addNextSegment => 'Lägg till nästa segment';

  @override
  String get multiSegment_travelTimeMinutes => 'Restid (minuter)';

  @override
  String get multiSegment_travelTimeHint => 't.ex. 20';

  @override
  String get multiSegment_addFirstSegment => 'Lägg till första segmentet';

  @override
  String get multiSegment_saveJourney => 'Spara resa';

  @override
  String get multiSegment_saving => 'Sparar...';

  @override
  String get multiSegment_pleaseEnterDeparture => 'Vänligen ange avgångsplats';

  @override
  String get multiSegment_pleaseEnterArrival => 'Vänligen ange ankomstplats';

  @override
  String get multiSegment_pleaseEnterTravelTime => 'Vänligen ange restid';

  @override
  String get entryDetail_workSession => 'Arbetspass';

  @override
  String get dateRange_quickSelect => 'Snabbval';

  @override
  String get dateRange_yesterday => 'Igår';

  @override
  String get dateRange_thisWeek => 'Denna vecka';

  @override
  String get dateRange_lastWeek => 'Förra veckan';

  @override
  String get home_workSession => 'Arbetspass';

  @override
  String get home_paidLeave => 'Betald ledighet';

  @override
  String get home_sickLeave => 'Sjukledighet';

  @override
  String get home_vab => 'VAB (Vård av barn)';

  @override
  String get home_unpaidLeave => 'Obetald ledighet';

  @override
  String get home_logTravelEntry => 'Logga resepost';

  @override
  String get home_tripDetails => 'Resdetaljer';

  @override
  String get home_addAnotherTrip => 'Lägg till ytterligare resa';

  @override
  String get home_totalDuration => 'Total varaktighet';

  @override
  String get home_logWorkEntry => 'Logga arbete';

  @override
  String get home_workShifts => 'Arbetsskift';

  @override
  String get home_addAnotherShift => 'Lägg till ytterligare skift';

  @override
  String get home_startTime => 'Starttid';

  @override
  String get home_endTime => 'Sluttid';

  @override
  String get home_logEntry => 'Logga post';

  @override
  String get home_selectTime => 'Välj tid';

  @override
  String get home_timeExample => 't.ex. 9:00';

  @override
  String get home_noRemarks => 'Inga anmärkningar';

  @override
  String get common_swapLocations => 'Byt platser';

  @override
  String get form_departureLocation => 'Avgångsplats';

  @override
  String get form_arrivalLocation => 'Ankomstplats';

  @override
  String get form_additionalInformation => 'Ytterligare information';

  @override
  String get form_pleaseSelectDate => 'Vänligen välj ett datum';

  @override
  String get dateRange_last90Days => 'Senaste 90 dagarna';

  @override
  String get form_shiftLocationHint => 'Ange skiftplats';

  @override
  String error_negativeBreakMinutes(Object number) {
    return 'Skift $number: Rastminuter kan inte vara negativa';
  }

  @override
  String error_breakExceedsSpan(
    Object number,
    Object breakMinutes,
    Object spanMinutes,
  ) {
    return 'Skift $number: Rastminuter ($breakMinutes) kan inte överstiga tidsintervallet (${spanMinutes}m)';
  }

  @override
  String get home_trackWorkShifts => 'Spåra dina arbetspass';

  @override
  String get travel_removeLeg => 'Ta bort reseben';

  @override
  String get error_addAtLeastOneTravelLeg =>
      'Vänligen lägg till minst ett reseben';

  @override
  String error_selectTravelLocations(Object number) {
    return 'Resa $number: Vänligen välj både från- och till-platser';
  }

  @override
  String error_invalidTravelDuration(Object number) {
    return 'Resa $number: Ange en giltig varaktighet (större än 0)';
  }

  @override
  String get travel_notesHint => 'Lägg till detaljer om din resa...';
}
