// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KvikTime';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_add => 'Add';

  @override
  String get common_done => 'Done';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_share => 'Share';

  @override
  String get common_export => 'Export';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get common_close => 'Close';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_ok => 'OK';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_today => 'Today';

  @override
  String get common_thisWeek => 'This week';

  @override
  String get common_thisMonth => 'This month';

  @override
  String get common_thisYear => 'This year';

  @override
  String common_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days',
      one: '# day',
    );
    return '$_temp0';
  }

  @override
  String common_hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours',
      one: '# hour',
    );
    return '$_temp0';
  }

  @override
  String get nav_home => 'Home';

  @override
  String get nav_calendar => 'Calendar';

  @override
  String get nav_reports => 'Reports';

  @override
  String get nav_settings => 'Settings';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_signOut => 'Sign Out';

  @override
  String get settings_signUp => 'Sign Up';

  @override
  String get settings_manageSubscription => 'Manage Subscription';

  @override
  String get settings_contractSettings => 'Contract Settings';

  @override
  String get settings_contractDescription =>
      'Set your contract percentage and work hours';

  @override
  String get settings_publicHolidays => 'Public Holidays';

  @override
  String get settings_autoMarkHolidays => 'Auto-mark public holidays';

  @override
  String get settings_holidayRegion => 'Sweden (Svenska helgdagar)';

  @override
  String settings_viewHolidays(int year) {
    return 'View holidays for $year';
  }

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_themeLight => 'Light';

  @override
  String get settings_themeDark => 'Dark';

  @override
  String get settings_themeSystem => 'System';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_languageSystem => 'System default';

  @override
  String get settings_data => 'Data';

  @override
  String get settings_clearDemoData => 'Clear Demo Data';

  @override
  String get settings_clearAllData => 'Clear All Data';

  @override
  String get settings_clearDemoDataConfirm =>
      'This will remove all demo entries. Are you sure?';

  @override
  String get settings_clearAllDataConfirm =>
      'This will permanently delete ALL your data. This action cannot be undone. Are you sure?';

  @override
  String get settings_about => 'About';

  @override
  String settings_version(String version) {
    return 'Version $version';
  }

  @override
  String get settings_terms => 'Terms of Service';

  @override
  String get settings_privacy => 'Privacy Policy';

  @override
  String get contract_title => 'Contract Settings';

  @override
  String get contract_headerTitle => 'Contract Settings';

  @override
  String get contract_headerDescription =>
      'Configure your contract percentage and full-time hours for accurate work time tracking and overtime calculations.';

  @override
  String get contract_percentage => 'Contract Percentage';

  @override
  String get contract_percentageHint => 'Enter percentage (0-100)';

  @override
  String get contract_percentageError => 'Percentage must be between 0 and 100';

  @override
  String get contract_fullTimeHours => 'Full-time Hours per Week';

  @override
  String get contract_fullTimeHoursHint => 'Enter hours per week (e.g., 40)';

  @override
  String get contract_fullTimeHoursError => 'Hours must be greater than 0';

  @override
  String get contract_startingBalance => 'Starting Balance';

  @override
  String get contract_startingBalanceDescription =>
      'Set your starting point for balance calculations. Ask your manager for your flex saldo as of this date.';

  @override
  String get contract_startTrackingFrom => 'Start tracking from';

  @override
  String get contract_openingBalance => 'Opening time balance';

  @override
  String get contract_creditPlus => 'Credit (+)';

  @override
  String get contract_deficitMinus => 'Deficit (−)';

  @override
  String get contract_creditExplanation =>
      'Credit means you have extra time (ahead of schedule)';

  @override
  String get contract_deficitExplanation =>
      'Deficit means you owe time (behind schedule)';

  @override
  String get contract_livePreview => 'Live Preview';

  @override
  String get contract_contractType => 'Contract Type';

  @override
  String get contract_fullTime => 'Full-time';

  @override
  String get contract_partTime => 'Part-time';

  @override
  String get contract_allowedHours => 'Allowed Hours';

  @override
  String get contract_dailyHours => 'Daily Hours';

  @override
  String get contract_resetToDefaults => 'Reset to Defaults';

  @override
  String get contract_resetConfirm =>
      'This will reset your contract settings to 100% full-time with 40 hours per week, and clear your starting balance. Are you sure?';

  @override
  String get contract_saveSettings => 'Save Settings';

  @override
  String get contract_savedSuccess => 'Contract settings saved successfully!';

  @override
  String get contract_resetSuccess => 'Contract settings reset to defaults';

  @override
  String get balance_title => 'Time Balance';

  @override
  String balance_myTimeBalance(int year) {
    return 'My Time Balance ($year)';
  }

  @override
  String balance_thisYear(int year) {
    return 'THIS YEAR: $year';
  }

  @override
  String balance_thisMonth(String month) {
    return 'THIS MONTH: $month';
  }

  @override
  String balance_hoursWorkedToDate(String worked, String target) {
    return 'Hours Worked (to date): $worked / $target h';
  }

  @override
  String balance_creditedHours(String hours) {
    return 'Credited Hours: $hours h';
  }

  @override
  String get balance_statusOver => 'Over';

  @override
  String get balance_statusUnder => 'Under';

  @override
  String balance_status(String variance, String status) {
    return 'Status: $variance h ($status)';
  }

  @override
  String balance_percentOfTarget(String percent) {
    return '$percent% of target';
  }

  @override
  String get balance_yearlyRunningBalance => 'YEARLY RUNNING BALANCE';

  @override
  String get balance_totalAccumulation => 'Total Accumulation:';

  @override
  String get balance_inCredit => 'You are in credit';

  @override
  String get balance_inDebt => 'You maintain a time debt';

  @override
  String balance_includesOpening(String balance, String date) {
    return 'Includes opening balance ($balance) as of $date';
  }

  @override
  String get adjustment_title => 'Balance Adjustments';

  @override
  String get adjustment_description =>
      'Manual corrections to your balance (e.g., manager adjustments)';

  @override
  String get adjustment_add => 'Add Adjustment';

  @override
  String get adjustment_edit => 'Edit Adjustment';

  @override
  String get adjustment_recent => 'Recent Adjustments';

  @override
  String get adjustment_effectiveDate => 'Effective Date';

  @override
  String get adjustment_amount => 'Amount';

  @override
  String get adjustment_noteOptional => 'Note (optional)';

  @override
  String get adjustment_noteHint => 'e.g., Manager correction';

  @override
  String get adjustment_deleteConfirm =>
      'Are you sure you want to delete this adjustment?';

  @override
  String adjustment_saveError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get adjustment_enterAmount => 'Please enter an adjustment amount';

  @override
  String get adjustment_minutesError => 'Minutes must be between 0 and 59';

  @override
  String get redDay_auto => 'Auto';

  @override
  String get redDay_personal => 'Personal';

  @override
  String get redDay_fullDay => 'Full Day';

  @override
  String get redDay_halfDay => 'Half Day';

  @override
  String get redDay_am => 'AM';

  @override
  String get redDay_pm => 'PM';

  @override
  String get redDay_publicHoliday => 'Public holiday in Sweden';

  @override
  String redDay_autoMarked(String holidayName) {
    return 'Auto-marked: $holidayName';
  }

  @override
  String get redDay_holidayWorkNotice =>
      'This is a public holiday (Auto). Hours entered here may count as holiday work.';

  @override
  String get redDay_personalNotice =>
      'Red day (Personal). Hours entered may count as holiday work.';

  @override
  String get redDay_addPersonal => 'Add Personal Red Day';

  @override
  String get redDay_editPersonal => 'Edit Personal Red Day';

  @override
  String get redDay_reason => 'Reason (optional)';

  @override
  String get redDay_halfDayReducesScheduled =>
      'Half-day red day reduces scheduled hours by 50%.';

  @override
  String get leave_title => 'Leaves';

  @override
  String leave_summary(int year) {
    return 'Leave Summary $year';
  }

  @override
  String get leave_paidVacation => 'Paid Vacation';

  @override
  String get leave_sickLeave => 'Sick Leave';

  @override
  String get leave_vab => 'VAB (Child Care)';

  @override
  String get leave_unpaid => 'Unpaid Leave';

  @override
  String get leave_totalDays => 'Total Leave Days';

  @override
  String get leave_recent => 'Recent Leaves';

  @override
  String get leave_noRecords => 'No leaves recorded';

  @override
  String get leave_historyAppears => 'Your leave history will appear here';

  @override
  String leave_daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get reports_title => 'Reports & Analytics';

  @override
  String get reports_overview => 'Overview';

  @override
  String get reports_trends => 'Trends';

  @override
  String get reports_timeBalance => 'Time Balance';

  @override
  String get reports_leaves => 'Leaves';

  @override
  String get reports_exportData => 'Export Data';

  @override
  String get reports_serverAnalytics => 'Server analytics';

  @override
  String get export_title => 'Export Data';

  @override
  String get export_format => 'Format';

  @override
  String get export_excel => 'Excel';

  @override
  String get export_csv => 'CSV';

  @override
  String get export_dateRange => 'Date Range';

  @override
  String get export_allTime => 'All time';

  @override
  String get export_fileName => 'File Name';

  @override
  String export_generating(String format) {
    return 'Generating $format export...';
  }

  @override
  String get export_complete => 'Export Complete';

  @override
  String export_savedSuccess(String format) {
    return '$format file has been saved successfully.';
  }

  @override
  String get export_sharePrompt =>
      'Would you like to share it via email or another app?';

  @override
  String export_downloadedSuccess(String format) {
    return '$format file downloaded successfully!';
  }

  @override
  String export_failed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get export_noData => 'No data available for export';

  @override
  String get export_noEntries =>
      'No entries to export. Please select entries with data.';

  @override
  String get home_todaysTotals => 'Today\'s Totals';

  @override
  String get home_weeklyStats => 'Weekly Stats';

  @override
  String get home_quickActions => 'Quick Actions';

  @override
  String get home_recentEntries => 'Recent Entries';

  @override
  String get home_addWork => 'Add Work';

  @override
  String get home_addTravel => 'Add Travel';

  @override
  String get home_addLeave => 'Add Leave';

  @override
  String get home_viewAll => 'View All';

  @override
  String get home_noEntries => 'No recent entries';

  @override
  String get home_holidayWork => 'Holiday Work';

  @override
  String get entry_travel => 'Travel';

  @override
  String get entry_work => 'Work';

  @override
  String get entry_from => 'From';

  @override
  String get entry_to => 'To';

  @override
  String get entry_duration => 'Duration';

  @override
  String get entry_date => 'Date';

  @override
  String get entry_notes => 'Notes';

  @override
  String get entry_shifts => 'Shifts';

  @override
  String get entry_addShift => 'Add Shift';

  @override
  String get error_loadingData => 'Error loading data';

  @override
  String get error_loadingBalance => 'Error loading balance';

  @override
  String get error_userNotAuth => 'User not authenticated';

  @override
  String get error_generic => 'Something went wrong';

  @override
  String get error_networkError =>
      'Network error. Please check your connection.';

  @override
  String get absence_title => 'Absences';

  @override
  String get absence_addAbsence => 'Add Absence';

  @override
  String get absence_editAbsence => 'Edit Absence';

  @override
  String get absence_deleteAbsence => 'Delete Absence';

  @override
  String get absence_deleteConfirm =>
      'Are you sure you want to delete this absence?';

  @override
  String absence_noAbsences(int year) {
    return 'No absences for $year';
  }

  @override
  String get absence_addHint => 'Tap + to add vacation, sick leave, or VAB';

  @override
  String get absence_errorLoading => 'Error loading absences';

  @override
  String get absence_type => 'Absence Type';

  @override
  String get absence_date => 'Date';

  @override
  String get absence_halfDay => 'Half Day';

  @override
  String get absence_fullDay => 'Full Day';

  @override
  String get absence_notes => 'Notes';

  @override
  String get absence_savedSuccess => 'Absence saved successfully';

  @override
  String get absence_deletedSuccess => 'Absence deleted';

  @override
  String get absence_saveFailed => 'Failed to save absence';

  @override
  String get absence_deleteFailed => 'Failed to delete absence';

  @override
  String get settings_manageLocations => 'Manage Locations';

  @override
  String get settings_manageLocationsDesc =>
      'Add and edit your frequent locations';

  @override
  String get settings_absences => 'Absences';

  @override
  String get settings_absencesDesc => 'Manage vacation, sick leave, and VAB';

  @override
  String get settings_subscriptionDesc =>
      'Update payment method and subscription plan';

  @override
  String get settings_welcomeScreen => 'Show Welcome Screen';

  @override
  String get settings_welcomeScreenDesc => 'Show introduction on next launch';

  @override
  String get settings_region => 'Region';

  @override
  String get common_unknown => 'Unknown';

  @override
  String get common_noRemarks => 'No remarks';

  @override
  String get common_workSession => 'Work Session';

  @override
  String get common_confirmDelete => 'Confirm Delete';

  @override
  String common_durationFormat(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get common_profile => 'Profile';

  @override
  String common_required(String field) {
    return '$field is required';
  }

  @override
  String get common_invalidNumber => 'Please enter a valid number';

  @override
  String get home_title => 'Time Tracker';

  @override
  String get home_subtitle => 'Track your productivity';

  @override
  String get home_logTravel => 'Log Travel';

  @override
  String get home_logWork => 'Log Work';

  @override
  String get home_quickEntry => 'Quick Entry';

  @override
  String get home_quickTravelEntry => 'Quick travel entry';

  @override
  String get home_quickWorkEntry => 'Quick work entry';

  @override
  String get home_noEntriesYet => 'No entries yet';

  @override
  String get home_viewAllArrow => 'View All →';

  @override
  String home_travelRoute(String from, String to) {
    return 'Travel: $from → $to';
  }

  @override
  String get home_fullDay => 'Full day';

  @override
  String get entry_deleteEntry => 'Delete Entry';

  @override
  String entry_deleteConfirm(String type) {
    return 'Are you sure you want to delete this $type entry?';
  }

  @override
  String entry_deletedSuccess(String type) {
    return '$type entry deleted successfully';
  }

  @override
  String error_deleteFailed(String error) {
    return 'Failed to delete entry: $error';
  }

  @override
  String error_loadingEntries(String error) {
    return 'Error loading entries: $error';
  }

  @override
  String get contract_maxHoursError => 'Hours cannot exceed 168 per week';

  @override
  String get contract_invalidHours => 'Invalid hours';

  @override
  String get contract_minutesError => 'Minutes must be 0-59';

  @override
  String contract_hoursPerDayValue(String hours) {
    return '$hours hours/day';
  }

  @override
  String get contract_hrsWeek => 'hrs/week';

  @override
  String export_shareSubject(String fileName) {
    return 'Time Tracker Export - $fileName';
  }

  @override
  String get export_shareText =>
      'Please find attached the time tracker report.';

  @override
  String error_shareFile(String error) {
    return 'Could not share file: $error';
  }
}
