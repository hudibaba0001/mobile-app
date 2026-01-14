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
  String get balance_title => 'Flexsaldo';

  @override
  String balance_myTimeBalance(int year) {
    return 'Mitt flexsaldo ($year)';
  }

  @override
  String balance_thisYear(int year) {
    return 'I ÅR: $year';
  }

  @override
  String balance_thisMonth(String month) {
    return 'DENNA MÅNAD: $month';
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
  String get balance_yearlyRunningBalance => 'LÖPANDE ÅRSBALANS';

  @override
  String get balance_totalAccumulation => 'Total ackumulering:';

  @override
  String get balance_inCredit => 'Du har flexkredit';

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
  String get adjustment_effectiveDate => 'Gäller från';

  @override
  String get adjustment_amount => 'Belopp';

  @override
  String get adjustment_noteOptional => 'Anteckning (valfri)';

  @override
  String get adjustment_noteHint => 't.ex. Chefsjustering';

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
  String get entry_from => 'Från';

  @override
  String get entry_to => 'Till';

  @override
  String get entry_duration => 'Längd';

  @override
  String get entry_date => 'Datum';

  @override
  String get entry_notes => 'Anteckningar';

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
}
