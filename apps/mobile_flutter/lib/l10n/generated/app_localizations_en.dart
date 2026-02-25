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
  String get common_back => 'Back';

  @override
  String get common_saved => 'saved';

  @override
  String get common_updated => 'updated';

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
  String get common_optional => '(optional)';

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
  String get settings_dailyReminder => 'Daily reminder';

  @override
  String get settings_dailyReminderDesc =>
      'Get a reminder at your chosen time every day';

  @override
  String get settings_dailyReminderTime => 'Reminder time';

  @override
  String get settings_dailyReminderText => 'Reminder text';

  @override
  String get settings_dailyReminderTextHint => 'Write your reminder message';

  @override
  String get settings_dailyReminderDefaultText => 'Time to log your hours';

  @override
  String get settings_dailyReminderPermissionDenied =>
      'Notification permission is required for reminders.';

  @override
  String settings_reminderSetupFailed(String error) {
    return 'Reminder setup failed: $error';
  }

  @override
  String get settings_crashlyticsTestNonFatalTitle =>
      'Crashlytics test (non-fatal)';

  @override
  String get settings_crashlyticsTestNonFatalSubtitle =>
      'Send a non-fatal test event to Firebase';

  @override
  String get settings_crashlyticsTestFatalTitle =>
      'Crashlytics test (fatal crash)';

  @override
  String get settings_crashlyticsTestFatalSubtitle =>
      'Force app crash to verify Crashlytics';

  @override
  String get settings_crashlyticsDisabled =>
      'Crashlytics is disabled for this build.';

  @override
  String get settings_crashlyticsNonFatalSent =>
      'Crashlytics non-fatal event sent.';

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
    return 'Hours Accounted (to date): $worked / $target h';
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
  String get balance_underTarget => 'Under target';

  @override
  String get balance_overTarget => 'Over target';

  @override
  String balance_yearBalance(String year) {
    return 'Year Balance ($year)';
  }

  @override
  String balance_resetsOn(String date) {
    return 'Resets $date';
  }

  @override
  String balance_contractBalance(String date) {
    return 'Contract balance (since $date)';
  }

  @override
  String get balance_contractBalanceNoDate => 'Contract balance (since start)';

  @override
  String get balance_today_includes_offsets =>
      'Balance today (includes starting balance + adjustments)';

  @override
  String get balance_balanceTodayHeadline => 'Balance today';

  @override
  String balance_balanceTodaySubline(
      String opening, String adjustments, String yearChange) {
    return 'Opening $opening • Adjustments $adjustments • Year change $yearChange';
  }

  @override
  String get balance_adjustments_this_month => 'Adjustments (this month)';

  @override
  String get balance_adjustments_this_year => 'Adjustments (this year)';

  @override
  String get balance_recent_adjustments => 'Recent adjustments';

  @override
  String get balance_details => 'Details';

  @override
  String get balance_informationalOnly => 'Informational only';

  @override
  String balance_includesOpening(String balance, String date) {
    return 'Inkluderar ingående saldo ($balance) per $date';
  }

  @override
  String balance_yearlyLabel(int year) {
    return 'Yearly ($year)';
  }

  @override
  String balance_thisMonthLabel(String month) {
    return 'This month: $month';
  }

  @override
  String get balance_statusToDate => 'Status (to date):';

  @override
  String get balance_workedToDate => 'Accounted time (to date):';

  @override
  String balance_fullMonthTarget(String hours) {
    return 'Full month target: ${hours}h';
  }

  @override
  String balance_creditedPaidLeave(String hours) {
    return '+ ${hours}h credited leave';
  }

  @override
  String balance_manualAdjustments(String hours) {
    return '${hours}h manual adjustments';
  }

  @override
  String balance_percentFullMonthTarget(String percent) {
    return '$percent% of full month target';
  }

  @override
  String balance_fullYearTarget(String hours) {
    return 'Full year target: ${hours}h';
  }

  @override
  String balance_includesAdjustments(String hours) {
    return 'Includes adjustments: ${hours}h';
  }

  @override
  String get balance_loggedTime => 'Logged time';

  @override
  String get balance_creditedLeave => 'Credited leave';

  @override
  String get balance_accountedTime => 'Accounted time';

  @override
  String get balance_plannedTimeSinceBaseline =>
      'Planned time (since baseline)';

  @override
  String get balance_differenceVsPlan => 'Over/under plan';

  @override
  String balance_countingFrom(String date) {
    return 'Counting from: $date';
  }

  @override
  String get balance_planCalculatedFromStart =>
      'Plan is calculated from start date';

  @override
  String get balance_travelExcluded => 'Travel (excluded by settings)';

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
  String get redDay_currentPersonalDays => 'Current personal red days';

  @override
  String get redDay_noPersonalDaysYet => 'No personal red days added yet.';

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
  String get leave_unknownType => 'Unknown leave type';

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
  String travel_legLabel(int number) {
    return 'Travel $number';
  }

  @override
  String get travel_addLeg => 'Add Travel Leg';

  @override
  String get travel_addAnotherLeg => 'Add Another Travel';

  @override
  String get travel_sourceAuto => 'Auto';

  @override
  String get travel_sourceManual => 'Manual';

  @override
  String get travel_total => 'Total travel';

  @override
  String get entry_from => 'From';

  @override
  String get entry_to => 'To';

  @override
  String get entry_duration => 'Duration';

  @override
  String get entry_date => 'Date';

  @override
  String get entry_notes => 'Notes (Optional)';

  @override
  String get entry_shifts => 'Shifts';

  @override
  String get entry_addShift => 'Add Shift';

  @override
  String get entry_travelLegUpdateNotice =>
      'First leg updates the existing entry; extra legs become new entries.';

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
  String get settings_travelLogging => 'Travel time logging';

  @override
  String get settings_travelLoggingDesc =>
      'Enable travel time entry and related stats';

  @override
  String get settings_changePassword => 'Change Password';

  @override
  String get settings_changePasswordDesc => 'Update your account password';

  @override
  String get settings_changePasswordSent =>
      'Password reset link sent to your email';

  @override
  String get settings_contactSupport => 'Contact Support';

  @override
  String get settings_contactSupportDesc => 'Get help or report an issue';

  @override
  String get settings_deleteAccount => 'Delete Account';

  @override
  String get settings_deleteAccountDesc =>
      'Permanently delete your account and all data';

  @override
  String get settings_deleteAccountConfirmTitle => 'Delete Account?';

  @override
  String get settings_deleteAccountConfirmBody =>
      'This will permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get settings_deleteAccountConfirmHint => 'Type DELETE to confirm';

  @override
  String get settings_deleteAccountSuccess => 'Account deleted successfully';

  @override
  String settings_deleteAccountError(String error) {
    return 'Failed to delete account: $error';
  }

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
  String get common_noDataToExport => 'No data to export';

  @override
  String get common_exportSuccess => 'Export successful';

  @override
  String get common_exportFailed => 'Export failed';

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
  String get home_timeBalanceTitle => 'Balance today';

  @override
  String get home_balanceSubtitle => 'Incl. opening + adjustments';

  @override
  String get home_changeVsPlan => 'Over/under plan';

  @override
  String get home_loggedTimeTitle => 'Logged time';

  @override
  String get home_seeMore => 'See more →';

  @override
  String get home_sinceStart => 'since start';

  @override
  String home_monthProgress(
      String month, String worked, String planned, String delta) {
    return '$month: $worked / $planned  $delta';
  }

  @override
  String home_monthProgressNoTarget(String month, String since, String worked) {
    return '$month ($since): $worked';
  }

  @override
  String get home_thisYear => 'This year';

  @override
  String get home_thisYearSinceStart => 'This year (since start)';

  @override
  String get home_backfillWarning =>
      'You have entries before your start date. Balance is calculated from the start date.';

  @override
  String get home_backfillChange => 'Change';

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

  @override
  String get entry_saveEntry => 'Save Entry';

  @override
  String get entry_editEntry => 'Edit Entry';

  @override
  String get entry_saveChanges => 'Save Changes';

  @override
  String get entry_calculate => 'Calculate';

  @override
  String get entry_logTravel => 'Log Travel';

  @override
  String get entry_deleteTitle => 'Delete Entry';

  @override
  String get error_selectBothLocations =>
      'Please select both departure and arrival locations';

  @override
  String get error_selectWorkLocation => 'Please select a work location';

  @override
  String get error_selectEndTime => 'Please select an end time';

  @override
  String get error_signInRequired => 'Please sign in to save entries';

  @override
  String error_savingEntry(String error) {
    return 'Error saving entry: $error';
  }

  @override
  String error_calculatingTravelTime(String error) {
    return 'Failed to calculate travel time: $error';
  }

  @override
  String get error_invalidHours => 'Hours must be a non-negative number';

  @override
  String get error_invalidMinutes => 'Minutes must be between 0 and 59';

  @override
  String get error_durationRequired =>
      'Please enter a valid duration (greater than 0)';

  @override
  String get error_endTimeBeforeStart => 'End time must be after start time';

  @override
  String error_invalidShiftTime(int number) {
    return 'Shift $number has invalid times (end must be after start)';
  }

  @override
  String get form_departure => 'Departure';

  @override
  String get form_arrival => 'Arrival';

  @override
  String get form_location => 'Location';

  @override
  String get form_date => 'Date';

  @override
  String get form_startTime => 'Start Time';

  @override
  String get form_endTime => 'End Time';

  @override
  String get form_duration => 'Duration';

  @override
  String get form_notesOptional => 'Notes (optional)';

  @override
  String get form_selectLocation => 'Select a location';

  @override
  String get form_calculateFromLocations => 'Calculate from locations';

  @override
  String get form_manualDuration => 'Manual Duration';

  @override
  String get form_hours => 'Hours';

  @override
  String get form_minutes => 'Minutes';

  @override
  String get form_unpaidBreakMinutes => 'Unpaid break (min)';

  @override
  String form_shiftLabel(int number) {
    return 'Shift $number';
  }

  @override
  String get form_span => 'Span';

  @override
  String get form_break => 'Break';

  @override
  String get form_worked => 'Worked';

  @override
  String get form_useLocationForAllShifts => 'Use this location for all shifts';

  @override
  String get form_shiftLocation => 'Shift location';

  @override
  String get form_shiftNotes => 'Shift notes';

  @override
  String get form_shiftNotesHint =>
      'Add notes for this shift (e.g., specific tasks, issues)';

  @override
  String get form_sameAsDefault => 'Same as default';

  @override
  String get form_dayNotes => 'Day notes';

  @override
  String get export_includeAllData => 'Include all data';

  @override
  String get export_includeAllDataDesc =>
      'Export all entries regardless of date';

  @override
  String get export_startDate => 'Start Date';

  @override
  String get export_endDate => 'End Date';

  @override
  String get export_selectStartDate => 'Select start date';

  @override
  String get export_selectEndDate => 'Select end date';

  @override
  String get export_entryType => 'Entry Type';

  @override
  String get export_travelOnly => 'Travel Entries Only';

  @override
  String get export_travelOnlyDesc => 'Export only travel time entries';

  @override
  String get export_workOnly => 'Work Entries Only';

  @override
  String get export_workOnlyDesc => 'Export only work shift entries';

  @override
  String get export_both => 'Both';

  @override
  String get export_bothDesc => 'Export all entries (travel + work)';

  @override
  String get export_leaveOnly => 'Leave Entries Only';

  @override
  String get export_leaveOnlyDesc => 'Export only absence/leave entries';

  @override
  String get export_formatTitle => 'Export Format';

  @override
  String get export_excelFormat => 'Excel (.xlsx)';

  @override
  String get export_excelDesc => 'Professional format with formatting';

  @override
  String get export_csvFormat => 'CSV (.csv)';

  @override
  String get export_csvDesc => 'Simple text format';

  @override
  String get export_options => 'Export Options';

  @override
  String get export_filename => 'Filename';

  @override
  String get export_filenameHint => 'Enter custom filename';

  @override
  String get export_summary => 'Export Summary';

  @override
  String export_totalEntries(int count) {
    return 'Total entries: $count';
  }

  @override
  String export_travelEntries(int count) {
    return 'Travel entries: $count';
  }

  @override
  String export_workEntries(int count) {
    return 'Work entries: $count';
  }

  @override
  String export_totalHours(String hours) {
    return 'Total hours: $hours';
  }

  @override
  String export_totalMinutes(int minutes) {
    return 'Total minutes: $minutes';
  }

  @override
  String export_leaveEntriesCount(int count) {
    return 'Leave entries: $count';
  }

  @override
  String get export_button => 'Export';

  @override
  String get export_enterFilename => 'Please enter a filename';

  @override
  String get export_noEntriesInRange =>
      'No entries found for the selected date range';

  @override
  String export_errorPreparing(String error) {
    return 'Error preparing export: $error';
  }

  @override
  String get redDay_editRedDay => 'Edit Red Day';

  @override
  String get redDay_markAsRedDay => 'Mark as Red Day';

  @override
  String get redDay_duration => 'Duration';

  @override
  String get redDay_morningAM => 'Morning (AM)';

  @override
  String get redDay_afternoonPM => 'Afternoon (PM)';

  @override
  String get redDay_reasonHint => 'e.g., Personal day, Appointment...';

  @override
  String get redDay_remove => 'Remove';

  @override
  String get redDay_removeTitle => 'Remove Red Day?';

  @override
  String get redDay_removeMessage =>
      'This will remove the personal red day marker from this date.';

  @override
  String get redDay_updated => 'Red day updated';

  @override
  String get redDay_added => 'Red day added';

  @override
  String get redDay_removed => 'Red day removed';

  @override
  String redDay_errorSaving(String error) {
    return 'Error saving red day: $error';
  }

  @override
  String redDay_errorRemoving(String error) {
    return 'Error removing red day: $error';
  }

  @override
  String get adjustment_editAdjustment => 'Edit Adjustment';

  @override
  String get adjustment_addAdjustment => 'Add Adjustment';

  @override
  String get adjustment_deleteTitle => 'Delete Adjustment';

  @override
  String get adjustment_deleteMessage =>
      'Are you sure you want to delete this adjustment?';

  @override
  String get adjustment_update => 'Update';

  @override
  String adjustment_failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String adjustment_failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_notSignedIn => 'Not signed in';

  @override
  String get profile_editName => 'Edit Name';

  @override
  String get profile_labelName => 'Name';

  @override
  String get profile_labelEmail => 'Email';

  @override
  String get profile_memberSince => 'Member since';

  @override
  String get profile_totalHoursLogged => 'Total hours logged';

  @override
  String get profile_nameUpdated => 'Name updated successfully';

  @override
  String profile_nameUpdateFailed(String error) {
    return 'Failed to update name: $error';
  }

  @override
  String get location_addLocation => 'Add Location';

  @override
  String get location_addFirstLocation => 'Add First Location';

  @override
  String get location_deleteLocation => 'Delete Location';

  @override
  String location_deleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get location_manageLocations => 'Manage Locations';

  @override
  String auth_signupFailed(String error) {
    return 'Failed to open signup page: $error';
  }

  @override
  String auth_subscriptionFailed(String error) {
    return 'Failed to open subscription page: $error';
  }

  @override
  String get auth_completeRegistration => 'Complete Registration';

  @override
  String get auth_openSignupPage => 'Open Signup Page';

  @override
  String get auth_signOut => 'Sign Out';

  @override
  String get auth_signInPrompt => 'Sign in to your account';

  @override
  String get auth_legalRequired => 'Legal Acceptance Required';

  @override
  String get auth_legalDescription =>
      'You must accept our terms of service and privacy policy to continue.';

  @override
  String get auth_legalVisitSignup =>
      'Visit our signup page to complete this step.';

  @override
  String get account_createTitle => 'Create Account';

  @override
  String get account_createOnWeb => 'Create your account on the web';

  @override
  String get account_createDescription =>
      'To create an account, please visit our registration page.';

  @override
  String get account_alreadyHaveAccount =>
      'I already have an account → Sign In';

  @override
  String get account_openSignupPage => 'Open Registration Page';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_passwordLabel => 'Password';

  @override
  String get auth_forgotPassword => 'Forgot Password?';

  @override
  String get auth_signInButton => 'Sign In';

  @override
  String get auth_noAccount => 'Don\'t have an account?';

  @override
  String get auth_signUpLink => 'Sign Up';

  @override
  String get password_resetTitle => 'Reset Password';

  @override
  String get password_forgotTitle => 'Forgot your password?';

  @override
  String get password_forgotDescription =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get password_emailLabel => 'Email';

  @override
  String get password_emailHint => 'Enter your email address';

  @override
  String get password_emailRequired => 'Email is required';

  @override
  String get password_emailInvalid => 'Please enter a valid email address';

  @override
  String get password_sendResetLink => 'Send Reset Link';

  @override
  String get password_backToSignIn => 'Back to Sign In';

  @override
  String get password_resetLinkSent => 'Reset link sent to your email';

  @override
  String get welcome_title => 'Welcome to KvikTime';

  @override
  String get welcome_subtitle => 'Track your travel time effortlessly';

  @override
  String get welcome_signIn => 'Sign In';

  @override
  String get welcome_getStarted => 'Get Started';

  @override
  String get welcome_footer =>
      'New to KvikTime? Create an account to get started.';

  @override
  String get welcome_urlError =>
      'Could not open sign up page. Please try again.';

  @override
  String get edit_title => 'Edit Entry';

  @override
  String get edit_travel => 'Travel';

  @override
  String get edit_work => 'Work';

  @override
  String get edit_addTravelEntry => 'Add Travel Entry';

  @override
  String get edit_addShift => 'Add Shift';

  @override
  String get edit_notes => 'Notes';

  @override
  String get edit_notesHint => 'Add any additional notes...';

  @override
  String get edit_travelNotesHint =>
      'Add any additional notes for all travel entries...';

  @override
  String edit_trip(int number) {
    return 'Trip $number';
  }

  @override
  String edit_shift(int number) {
    return 'Shift $number';
  }

  @override
  String get edit_from => 'From';

  @override
  String get edit_to => 'To';

  @override
  String get edit_departureHint => 'Departure location';

  @override
  String get edit_destinationHint => 'Destination location';

  @override
  String get edit_hours => 'Hours';

  @override
  String get edit_minutes => 'Minutes';

  @override
  String get edit_total => 'Total';

  @override
  String get edit_startTime => 'Start Time';

  @override
  String get edit_endTime => 'End Time';

  @override
  String get edit_selectTime => 'Select time';

  @override
  String get edit_toLabel => 'to';

  @override
  String get edit_save => 'Save';

  @override
  String get edit_cancel => 'Cancel';

  @override
  String edit_errorSaving(String error) {
    return 'Error saving entry: $error';
  }

  @override
  String get editMode_singleEntryInfo_work =>
      'Editing one entry. To add another shift for this date, create a new entry.';

  @override
  String get editMode_singleEntryInfo_travel =>
      'Editing one entry. To add another travel leg for this date, create a new entry.';

  @override
  String get editMode_addNewEntryForDate => 'Add new entry for this date';

  @override
  String get dateRange_title => 'Select Date Range';

  @override
  String get dateRange_description => 'Choose a time period to analyze';

  @override
  String get dateRange_quickSelections => 'Quick Selections';

  @override
  String get dateRange_customRange => 'Custom Range';

  @override
  String get dateRange_startDate => 'Start Date';

  @override
  String get dateRange_endDate => 'End Date';

  @override
  String get dateRange_apply => 'Apply';

  @override
  String get dateRange_last7Days => 'Last 7 Days';

  @override
  String get dateRange_last30Days => 'Last 30 Days';

  @override
  String get dateRange_thisMonth => 'This Month';

  @override
  String get dateRange_lastMonth => 'Last Month';

  @override
  String get dateRange_thisYear => 'This Year';

  @override
  String get quickEntry_signInRequired => 'Please sign in to add entries.';

  @override
  String quickEntry_error(String error) {
    return 'Error: $error';
  }

  @override
  String get quickEntry_multiSegment => 'Multi-Segment';

  @override
  String get quickEntry_clear => 'Clear';

  @override
  String location_saved(String name) {
    return 'Location \"$name\" saved!';
  }

  @override
  String get location_saveTitle => 'Save Location';

  @override
  String location_address(String address) {
    return 'Address: $address';
  }

  @override
  String get dev_addSampleData => 'Add Sample Data';

  @override
  String get dev_addSampleDataDesc => 'Create test entries from the last week';

  @override
  String get dev_sampleDataAdded => 'Sample data added successfully';

  @override
  String dev_sampleDataFailed(String error) {
    return 'Failed to add sample data: $error';
  }

  @override
  String get dev_signInRequired => 'Please sign in to add sample data.';

  @override
  String get dev_syncing => 'Syncing to Supabase...';

  @override
  String get dev_syncSuccess => '✅ Sync completed successfully!';

  @override
  String dev_syncFailed(String error) {
    return '❌ Sync failed: $error';
  }

  @override
  String get dev_syncToSupabase => 'Sync to Supabase';

  @override
  String get dev_syncToSupabaseDesc =>
      'Manually sync local entries to Supabase cloud';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get settings_languageSwedish => 'Svenska';

  @override
  String get simpleEntry_validDuration => 'Please enter a valid duration';

  @override
  String simpleEntry_entrySaved(String type, String action) {
    return '$type entry $action successfully! 🎉';
  }

  @override
  String get history_currentlySelected => 'Currently selected';

  @override
  String history_tapToFilter(String label) {
    return 'Tap to filter by $label entries';
  }

  @override
  String history_holidayWork(String name) {
    return 'Holiday work: $name';
  }

  @override
  String get history_redDay => 'Red day';

  @override
  String get history_noDescription => 'No description';

  @override
  String get history_title => 'History';

  @override
  String get history_travel => 'Travel';

  @override
  String get history_worked => 'Worked';

  @override
  String get history_totalWorked => 'Total worked';

  @override
  String get history_work => 'Work';

  @override
  String get history_all => 'All';

  @override
  String get history_yesterday => 'Yesterday';

  @override
  String get history_last7Days => 'Last 7 Days';

  @override
  String get history_custom => 'Custom';

  @override
  String get history_searchHint => 'Search by location, notes...';

  @override
  String get history_loadingEntries => 'Loading entries...';

  @override
  String get history_noEntriesFound => 'No entries found';

  @override
  String get history_tryAdjustingFilters =>
      'Try adjusting your filters or search terms';

  @override
  String get history_holidayWorkBadge => 'Holiday Work';

  @override
  String get history_autoBadge => 'Auto';

  @override
  String history_autoMarked(String name) {
    return 'Auto-marked: $name';
  }

  @override
  String get overview_totalHours => 'Total Hours';

  @override
  String get overview_allActivities => 'All activities';

  @override
  String get overview_totalEntries => 'Total Entries';

  @override
  String get overview_thisPeriod => 'This period';

  @override
  String get overview_travelTime => 'Travel Time';

  @override
  String get overview_totalCommute => 'Total commute';

  @override
  String get overview_workTime => 'Work Time';

  @override
  String get overview_totalWork => 'Total work';

  @override
  String get overview_quickInsights => 'Quick Insights';

  @override
  String get overview_activityDistribution => 'Activity Distribution';

  @override
  String get overview_recentActivity => 'Recent Activity';

  @override
  String get overview_viewAll => 'View All';

  @override
  String get overview_noDataAvailable => 'No data available';

  @override
  String get overview_errorLoadingData => 'Error loading data';

  @override
  String get overview_travel => 'Travel';

  @override
  String get overview_work => 'Work';

  @override
  String get overview_trackedWork => 'Tracked work';

  @override
  String get overview_trackedTravel => 'Tracked travel';

  @override
  String get overview_totalLoggedTime => 'Total logged time';

  @override
  String get overview_workPlusTravel => 'Work + travel';

  @override
  String get overview_creditedLeave => 'Credited leave';

  @override
  String get overview_accountedTime => 'Accounted time';

  @override
  String get overview_loggedPlusCreditedLeave => 'Logged + credited leave';

  @override
  String get overview_plannedTime => 'Planned time';

  @override
  String get overview_scheduledTarget => 'Scheduled target';

  @override
  String get overview_differenceVsPlan => 'Over/under plan';

  @override
  String get overview_accountedMinusPlanned => 'Accounted - planned';

  @override
  String get overview_balanceAfterPeriod => 'Balance at end of period';

  @override
  String get overview_startPlusAdjPlusDiff => 'Start + adjustments + change';

  @override
  String get overview_endBalanceFormula =>
      'End balance = Start balance + Adjustments in period + Over/under plan';

  @override
  String get balance_accountedTooltip => 'Logged time + credited leave';

  @override
  String get location_fullAddress => 'Full address';

  @override
  String get entry_logTravelEntry => 'Log Travel Entry';

  @override
  String get entry_logWorkEntry => 'Log Work Entry';

  @override
  String get trends_monthlyComparison => 'Monthly Comparison';

  @override
  String get trends_currentMonth => 'Current Month';

  @override
  String get trends_previousMonth => 'Previous Month';

  @override
  String get trends_workHours => 'Work Hours';

  @override
  String get trends_weeklyHours => 'Weekly Hours';

  @override
  String get trends_dailyTrends => 'Daily Trends (Last 7 Days)';

  @override
  String get trends_total => 'total';

  @override
  String get trends_work => 'work';

  @override
  String get trends_travel => 'travel';

  @override
  String get leave_recentLeaves => 'Recent Leaves';

  @override
  String get leave_fullDay => 'Full Day';

  @override
  String get leave_totalLeaveDays => 'Total Leave Days';

  @override
  String get leave_noLeavesRecorded => 'No leaves recorded';

  @override
  String get leave_noLeavesDescription => 'Your leave history will appear here';

  @override
  String get insight_peakPerformance => 'Peak Performance';

  @override
  String insight_peakPerformanceDesc(String day, String hours) {
    return 'Your most productive day was $day with $hours hours';
  }

  @override
  String get insight_locationInsights => 'Location Insights';

  @override
  String insight_locationInsightsDesc(String location) {
    return '$location is your most frequent location';
  }

  @override
  String get insight_timeManagement => 'Time Management';

  @override
  String insight_timeManagementDesc(String hours) {
    return 'You worked $hours hours in this period';
  }

  @override
  String get profile_signOut => 'Sign Out';

  @override
  String get form_dateTime => 'Date & Time';

  @override
  String get form_travelRoute => 'Travel Route';

  @override
  String get form_workLocation => 'Work Location';

  @override
  String get form_workDetails => 'Work Details';

  @override
  String get nav_history => 'History';

  @override
  String balance_thisWeek(String range) {
    return 'THIS WEEK: $range';
  }

  @override
  String balance_hoursWorked(String worked, String target) {
    return 'Hours Accounted (to date): $worked / $target h';
  }

  @override
  String get balance_over => 'Over';

  @override
  String get balance_under => 'Under';

  @override
  String get balance_timeDebt => 'Under target';

  @override
  String balance_includesOpeningBalance(String balance, String date) {
    return 'Includes opening balance ($balance) as of $date';
  }

  @override
  String balance_includesOpeningBalanceShort(String balance) {
    return 'Includes opening balance ($balance)';
  }

  @override
  String balance_loggedSince(String date) {
    return 'Logged since $date';
  }

  @override
  String balance_startingBalanceAsOf(String date, String value) {
    return 'Starting balance ($date): $value';
  }

  @override
  String get balance_balanceToday => 'BALANCE TODAY';

  @override
  String balance_netThisYear(String value) {
    return 'Net this year (logged): $value';
  }

  @override
  String get balance_netThisYearLabel => 'Net this year';

  @override
  String balance_startingBalanceValue(String value) {
    return 'Starting balance: $value';
  }

  @override
  String get balance_startingBalance => 'Starting balance';

  @override
  String get balance_breakdown => 'BREAKDOWN';

  @override
  String get balance_adjustments => 'Adjustments';

  @override
  String balance_fullMonthTargetValue(String value) {
    return 'Full month target: $value';
  }

  @override
  String balance_creditedPaidLeaveValue(String value) {
    return '+ $value credited leave';
  }

  @override
  String balance_manualAdjustmentsValue(String value) {
    return '$value manual adjustments';
  }

  @override
  String balance_fullYearTargetValue(String value) {
    return 'Full year target: $value';
  }

  @override
  String balance_creditedHoursValue(String value) {
    return 'Credited Hours: $value';
  }

  @override
  String balance_includesAdjustmentsValue(String value) {
    return 'Includes adjustments: $value';
  }

  @override
  String get locations_errorLoading => 'Error loading data';

  @override
  String get locations_distribution => 'Location Distribution';

  @override
  String get locations_details => 'Location Details';

  @override
  String get locations_noData => 'No location data';

  @override
  String get locations_noDataDescription =>
      'No entries found for the selected period';

  @override
  String get locations_noDataAvailable => 'No location data available';

  @override
  String get locations_totalHours => 'Total Hours';

  @override
  String get locations_entries => 'Entries';

  @override
  String get locations_workTime => 'Work Time';

  @override
  String get locations_travelTime => 'Travel Time';

  @override
  String get chart_timeDistribution => 'Time Distribution';

  @override
  String get chart_workTime => 'Work Time';

  @override
  String get chart_travelTime => 'Travel Time';

  @override
  String get chart_totalTime => 'Total Time';

  @override
  String get chart_noDataAvailable => 'No data available';

  @override
  String get chart_startTracking =>
      'Start tracking your time to see statistics';

  @override
  String get chart_allTime => 'All time';

  @override
  String get chart_today => 'Today';

  @override
  String get balance_todaysBalance => 'Today\'s Balance';

  @override
  String get balance_workVsTravel => 'Work vs Travel';

  @override
  String get balance_balanced => 'Balanced';

  @override
  String get balance_unbalanced => 'Unbalanced';

  @override
  String get balance_work => 'Work';

  @override
  String get balance_travel => 'Travel';

  @override
  String get balance_entries => 'Entries';

  @override
  String get settings_darkMode => 'Dark Mode';

  @override
  String get settings_darkModeActive => 'Dark theme is active';

  @override
  String get settings_switchToDark => 'Switch to dark theme';

  @override
  String get settings_darkModeEnabled => 'Dark mode enabled';

  @override
  String get settings_lightModeEnabled => 'Light mode enabled';

  @override
  String get entry_endTime => 'End time';

  @override
  String get entry_fromHint => 'Enter departure location';

  @override
  String get entry_toHint => 'Enter arrival location';

  @override
  String get entry_location => 'Location';

  @override
  String get entry_locationHint => 'Enter work location';

  @override
  String get entry_hours => 'Hours';

  @override
  String get entry_minutes => 'Minutes';

  @override
  String get entry_shift => 'Shift';

  @override
  String get entry_notesHint => 'Add any additional details...';

  @override
  String get entry_calculating => 'Calculating...';

  @override
  String get entry_calculateTravelTime => 'Calculate Travel Time';

  @override
  String entry_travelTimeCalculated(String duration, String distance) {
    return 'Travel time calculated: $duration ($distance)';
  }

  @override
  String entry_total(String duration) {
    return 'Total: $duration';
  }

  @override
  String get entry_publicHoliday => 'Public Holiday';

  @override
  String get entry_publicHolidaySweden => 'Public holiday in Sweden';

  @override
  String get entry_redDayWarning =>
      'Red day. Hours entered here may count as holiday work.';

  @override
  String get entry_personalRedDay => 'Personal red day';

  @override
  String get error_addAtLeastOneShift => 'Please add at least one shift.';

  @override
  String get shift_morning => 'Morning Shift';

  @override
  String get shift_afternoon => 'Afternoon Shift';

  @override
  String get shift_evening => 'Evening Shift';

  @override
  String get shift_night => 'Night Shift';

  @override
  String get shift_unknown => 'Unknown Shift';

  @override
  String get simpleEntry_fromLocation => 'From Location';

  @override
  String get simpleEntry_toLocation => 'To Location';

  @override
  String get simpleEntry_pleaseEnterDeparture =>
      'Please enter departure location';

  @override
  String get simpleEntry_pleaseEnterArrival => 'Please enter arrival location';

  @override
  String get quickEntry_editEntry => 'Edit Entry';

  @override
  String get quickEntry_quickEntry => 'Quick Entry';

  @override
  String get quickEntry_travelTimeMinutes => 'Travel Time (minutes)';

  @override
  String get quickEntry_travelTimeHint => 'e.g., 45';

  @override
  String get quickEntry_additionalInfo => 'Additional Info (Optional)';

  @override
  String get quickEntry_additionalInfoHint => 'Notes, delays, etc.';

  @override
  String get quickEntry_updateEntry => 'Update Entry';

  @override
  String get quickEntry_addEntry => 'Add Entry';

  @override
  String get quickEntry_saving => 'Saving...';

  @override
  String get multiSegment_editJourney => 'Edit Multi-Segment Journey';

  @override
  String get multiSegment_journey => 'Multi-Segment Journey';

  @override
  String get multiSegment_journeySegments => 'Journey Segments';

  @override
  String get multiSegment_firstSegment => 'First Segment';

  @override
  String get multiSegment_addNextSegment => 'Add Next Segment';

  @override
  String get multiSegment_travelTimeMinutes => 'Travel Time (minutes)';

  @override
  String get multiSegment_travelTimeHint => 'e.g., 20';

  @override
  String get multiSegment_addFirstSegment => 'Add First Segment';

  @override
  String get multiSegment_saveJourney => 'Save Journey';

  @override
  String get multiSegment_saving => 'Saving...';

  @override
  String get multiSegment_pleaseEnterDeparture =>
      'Please enter departure location';

  @override
  String get multiSegment_pleaseEnterArrival => 'Please enter arrival location';

  @override
  String get multiSegment_pleaseEnterTravelTime => 'Please enter travel time';

  @override
  String get entryDetail_workSession => 'Work Session';

  @override
  String get dateRange_quickSelect => 'Quick Select';

  @override
  String get dateRange_yesterday => 'Yesterday';

  @override
  String get dateRange_thisWeek => 'This Week';

  @override
  String get dateRange_lastWeek => 'Last Week';

  @override
  String get home_workSession => 'Work Session';

  @override
  String get home_paidLeave => 'Credited Leave';

  @override
  String get home_sickLeave => 'Sick Leave';

  @override
  String get home_vab => 'VAB (Child Care)';

  @override
  String get home_unpaidLeave => 'Unpaid Leave';

  @override
  String get home_logTravelEntry => 'Log Travel Entry';

  @override
  String get home_tripDetails => 'Trip Details';

  @override
  String get home_addAnotherTrip => 'Add Another Trip';

  @override
  String get home_totalDuration => 'Total Duration';

  @override
  String get home_logWorkEntry => 'Log Work Entry';

  @override
  String get home_workShifts => 'Work Shifts';

  @override
  String get home_addAnotherShift => 'Add Another Shift';

  @override
  String get home_startTime => 'Start Time';

  @override
  String get home_endTime => 'End Time';

  @override
  String get home_logEntry => 'Log Entry';

  @override
  String get home_selectTime => 'Select time';

  @override
  String get home_timeExample => 'e.g. 9:00 AM';

  @override
  String get home_noRemarks => 'No remarks';

  @override
  String home_targetToDateZero(String hours) {
    return 'Target to date: ${hours}h (weekend/red day)';
  }

  @override
  String home_loggedHours(String hours) {
    return 'Logged: ${hours}h';
  }

  @override
  String get common_swapLocations => 'Swap locations';

  @override
  String get form_departureLocation => 'Departure location';

  @override
  String get form_arrivalLocation => 'Arrival location';

  @override
  String get form_additionalInformation => 'Additional information';

  @override
  String get form_pleaseSelectDate => 'Please select a date';

  @override
  String get dateRange_last90Days => 'Last 90 Days';

  @override
  String get form_shiftLocationHint => 'Enter shift location';

  @override
  String error_negativeBreakMinutes(Object number) {
    return 'Shift $number: Break minutes cannot be negative';
  }

  @override
  String error_breakExceedsSpan(
      Object number, Object breakMinutes, Object spanMinutes) {
    return 'Shift $number: Break minutes ($breakMinutes) cannot exceed span (${spanMinutes}m)';
  }

  @override
  String get home_trackWorkShifts => 'Track your work shifts';

  @override
  String get travel_removeLeg => 'Remove travel leg';

  @override
  String get error_addAtLeastOneTravelLeg =>
      'Please add at least one travel leg';

  @override
  String error_selectTravelLocations(Object number) {
    return 'Travel $number: Please select both from and to locations';
  }

  @override
  String error_invalidTravelDuration(Object number) {
    return 'Travel $number: Please enter a valid duration (greater than 0)';
  }

  @override
  String get travel_notesHint => 'Add details about your travel...';

  @override
  String get common_user => 'User';

  @override
  String get settings_timeBalanceTracking => 'Time balance tracking';

  @override
  String get settings_timeBalanceTrackingDesc =>
      'Turn off if you only want to log hours without comparing against a target.';

  @override
  String leave_daysDecimal(String days) {
    return '$days days';
  }

  @override
  String get trends_errorLoadingData => 'Error loading trends data';

  @override
  String get trends_tryRefreshingPage => 'Please try refreshing the page';

  @override
  String get trends_target => 'Target';

  @override
  String get trends_noHoursDataAvailable => 'No hours data available';

  @override
  String network_offlinePending(int count) {
    return 'Offline - $count changes pending';
  }

  @override
  String get network_youAreOffline => 'You are offline';

  @override
  String get network_syncingChanges => 'Syncing changes...';

  @override
  String network_readyToSync(int count) {
    return '$count changes ready to sync';
  }

  @override
  String get network_syncNow => 'Sync Now';

  @override
  String get network_offlineTooltip => 'Offline';

  @override
  String network_pendingTooltip(int count) {
    return '$count pending';
  }

  @override
  String get network_offlineSnackbar =>
      'You are offline. Changes will sync when connected.';

  @override
  String get network_backOnline => 'Back online';

  @override
  String network_syncedChanges(int count) {
    return 'Synced $count changes';
  }

  @override
  String network_syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get network_networkErrorTryAgain => 'Network error. Please try again.';

  @override
  String get paywall_notAuthenticated => 'Not authenticated';

  @override
  String get paywall_title => 'KvikTime Premium';

  @override
  String get paywall_unlockAllFeatures => 'Unlock all KvikTime features';

  @override
  String get paywall_subscribeWithGooglePlay =>
      'Subscribe with Google Play Billing to continue.';

  @override
  String get paywall_featureFullHistoryReports => 'Full history & reports';

  @override
  String get paywall_featureCloudSync => 'Cloud sync across devices';

  @override
  String get paywall_featureSecureSubscription => 'Secure subscription state';

  @override
  String paywall_currentEntitlement(String status) {
    return 'Current entitlement: $status';
  }

  @override
  String get paywall_subscriptionUnavailable => 'Subscription unavailable';

  @override
  String paywall_subscribe(String price) {
    return 'Subscribe $price';
  }

  @override
  String get paywall_restorePurchase => 'Restore purchase';

  @override
  String get paywall_manageSubscriptionGooglePlay =>
      'Manage subscription in Google Play';

  @override
  String get paywall_signOut => 'Sign out';

  @override
  String get location_addNewLocation => 'Add New Location';

  @override
  String get location_saveFrequentPlace => 'Save a place you visit frequently';

  @override
  String get location_details => 'Location Details';

  @override
  String get location_name => 'Location Name';

  @override
  String get location_nameHint => 'e.g., Office, Home, Client Site';

  @override
  String get location_nameShortHint => 'e.g., Home, Office, Gym';

  @override
  String get location_enterName => 'Please enter a location name';

  @override
  String get location_enterAddress => 'Please enter an address';

  @override
  String get location_addedSuccessfully => 'Location added successfully';

  @override
  String get location_kpiTotal => 'Total';

  @override
  String get location_kpiFavorites => 'Favorites';

  @override
  String get location_kpiTotalUses => 'Total Uses';

  @override
  String get location_searchLocations => 'Search locations...';

  @override
  String get location_noLocationsYet => 'No locations yet';

  @override
  String get location_trySearchOrAdd =>
      'Try searching or adding a new location';

  @override
  String get location_noMatchesFound => 'No matches found';

  @override
  String get location_tryDifferentSearch => 'Try a different search term';

  @override
  String get location_noSavedYet => 'No saved locations yet';

  @override
  String get location_addFirstToGetStarted =>
      'Add your first location to get started';

  @override
  String get location_removeFromFavorites => 'Remove from favorites';

  @override
  String get location_addToFavorites => 'Add to favorites';

  @override
  String get location_savedLocations => 'Saved Locations';

  @override
  String get location_addressSuggestions => 'Address Suggestions';

  @override
  String get location_searchingAddresses => 'Searching addresses...';

  @override
  String get location_recentAddresses => 'Recent Addresses';

  @override
  String get location_startTypingToAdd => 'Start typing to add a new location';

  @override
  String get location_recentLocations => 'Recent Locations';

  @override
  String location_saveAsNew(String address) {
    return 'Save \"$address\" as new location';
  }

  @override
  String get location_favorites => 'Favorites';

  @override
  String get location_recent => 'Recent';

  @override
  String edit_durationAutofilledFromHistory(int minutes) {
    return 'Duration auto-filled from history ($minutes min)';
  }

  @override
  String get edit_quickDuration => 'Quick Duration';

  @override
  String get edit_copyYesterday => 'Copy Yesterday';

  @override
  String get edit_noWorkEntryYesterday => 'No work entry found for yesterday';

  @override
  String get edit_copiedYesterdayShiftTimes =>
      'Copied yesterday\'s shift times';

  @override
  String get edit_swapFromTo => 'Swap From/To';

  @override
  String get home_trackJourneyDetails => 'Track your journey details';

  @override
  String home_entryWillBeLoggedFor(String date) {
    return 'Entry will be logged for $date';
  }

  @override
  String get home_travelEntryLoggedSuccess =>
      'Travel entry logged successfully!';

  @override
  String get home_workEntriesLoggedSuccess =>
      'Work entries logged successfully!';

  @override
  String get home_workEntryLoggedSuccess => 'Work entry logged successfully!';

  @override
  String get nav_navigateAwayTitle => 'Navigate Away?';

  @override
  String get nav_leavePageConfirm =>
      'Are you sure you want to leave this page?';

  @override
  String get nav_continue => 'Continue';

  @override
  String get nav_travelEntries => 'Travel Entries';

  @override
  String get nav_locations => 'Locations';

  @override
  String get nav_analyticsDashboard => 'Analytics Dashboard';

  @override
  String get nav_adminOnly => 'Admin Only';

  @override
  String get location_enterNameAndAddress =>
      'Please enter both name and address.';

  @override
  String get location_deletedSuccessfully => 'Location deleted!';

  @override
  String get analytics_accessDeniedAdminRequired =>
      'Access denied. Admin privileges required.';

  @override
  String get analytics_accessDeniedRedirecting =>
      'Access denied. Redirecting...';

  @override
  String get analytics_dashboardTitle => 'Analytics Dashboard';

  @override
  String get analytics_adminBadge => 'ADMIN';

  @override
  String get analytics_errorLoadingDashboard => 'Error loading dashboard';

  @override
  String get analytics_noDataAvailable => 'No data available';

  @override
  String get analytics_kpiSectionTitle => 'Key Performance Indicators';

  @override
  String get analytics_kpiTotalHoursWeek => 'Total Hours (This Week)';

  @override
  String get analytics_kpiActiveUsers => 'Active Users';

  @override
  String get analytics_kpiOvertimeBalance => 'Overtime Balance';

  @override
  String get analytics_kpiAvgDailyHours => 'Avg Daily Hours';

  @override
  String get analytics_chartsSectionTitle => 'Charts & Trends';

  @override
  String get analytics_dailyTrends7d => '7-Day Daily Trends';

  @override
  String get analytics_userDistribution => 'User Distribution';

  @override
  String get adminUsers_title => 'User Management';

  @override
  String get adminUsers_searchHint => 'Search users...';

  @override
  String get adminUsers_filterByRole => 'Filter by Role';

  @override
  String get adminUsers_roleAll => 'All';

  @override
  String get adminUsers_roleAdmin => 'Admin';

  @override
  String get adminUsers_roleUser => 'User';

  @override
  String get adminUsers_failedLoadUsers => 'Failed to load users';

  @override
  String adminUsers_noUsersFoundQuery(String query) {
    return 'No users found matching \"$query\"';
  }

  @override
  String get adminUsers_noUsersFound => 'No users found';

  @override
  String get adminUsers_noName => 'No name';

  @override
  String get adminUsers_noEmail => 'No email';

  @override
  String get adminUsers_disable => 'Disable';

  @override
  String get adminUsers_enable => 'Enable';

  @override
  String get adminUsers_tooltipDetails => 'Details';

  @override
  String get adminUsers_userDetails => 'User Details';

  @override
  String get adminUsers_labelUid => 'UID';

  @override
  String get adminUsers_labelEmail => 'Email';

  @override
  String get adminUsers_labelName => 'Name';

  @override
  String get adminUsers_labelStatus => 'Status';

  @override
  String get adminUsers_labelCreated => 'Created';

  @override
  String get adminUsers_labelUpdated => 'Updated';

  @override
  String get adminUsers_none => 'None';

  @override
  String get adminUsers_statusDisabled => 'Disabled';

  @override
  String get adminUsers_statusActive => 'Active';

  @override
  String get adminUsers_disableUserTitle => 'Disable User';

  @override
  String adminUsers_disableUserConfirm(String name) {
    return 'Are you sure you want to disable $name?';
  }

  @override
  String get adminUsers_thisUser => 'this user';

  @override
  String get adminUsers_userDisabledSuccess => 'User disabled successfully';

  @override
  String get adminUsers_enableUserTitle => 'Enable User';

  @override
  String adminUsers_enableUserConfirm(String name) {
    return 'Are you sure you want to enable $name?';
  }

  @override
  String get adminUsers_userEnabledSuccess => 'User enabled successfully';

  @override
  String get adminUsers_confirmPermanentDeletion =>
      'Confirm Permanent Deletion';

  @override
  String get adminUsers_deleteWarning =>
      'Warning: This action cannot be undone. All user data will be permanently deleted.';

  @override
  String get adminUsers_typeDeleteToConfirm => 'Type DELETE to confirm:';

  @override
  String get adminUsers_typeDeleteHere => 'Type DELETE here';

  @override
  String get adminUsers_userDeletedSuccess => 'User deleted successfully';

  @override
  String adminUsers_failedDeleteUser(String error) {
    return 'Failed to delete user: $error';
  }

  @override
  String get auth_newToKvikTime => 'New to KvikTime?';

  @override
  String get auth_createAccount => 'Create Account';

  @override
  String get auth_redirectNote =>
      'New users will be redirected to our account creation page';

  @override
  String get auth_signInInvalidCredentials =>
      'Invalid email or password. Please check your credentials.';

  @override
  String get auth_signInNetworkError =>
      'Cannot reach server. Check your internet connection and try again.';

  @override
  String get auth_signInGenericError =>
      'An error occurred during sign in. Please try again.';

  @override
  String get auth_invalidEmail => 'Invalid email';

  @override
  String get auth_passwordRequired => 'Password is required';

  @override
  String get signup_subtitle =>
      'Sign up in the app and continue to subscription.';

  @override
  String get signup_firstNameLabel => 'First name';

  @override
  String get signup_lastNameLabel => 'Last name';

  @override
  String get signup_firstNameRequired => 'First name is required';

  @override
  String get signup_lastNameRequired => 'Last name is required';

  @override
  String get signup_confirmPasswordLabel => 'Confirm password';

  @override
  String get signup_confirmPasswordRequired => 'Confirm your password';

  @override
  String get signup_passwordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get signup_passwordStrongRequired =>
      'Password must include uppercase, lowercase, number, and special character.';

  @override
  String get signup_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signup_acceptLegalPrefix => 'I accept the';

  @override
  String get signup_acceptLegalAnd => 'and';

  @override
  String get signup_acceptLegalRequired =>
      'You must accept Terms and Privacy Policy to continue.';

  @override
  String get signup_errorRateLimit =>
      'Too many email requests. Wait a few minutes and try again.';

  @override
  String get signup_errorEmailNotConfirmed =>
      'Email confirmation is required. Check your inbox and confirm, then sign in.';

  @override
  String get signup_errorUserExists =>
      'An account with this email already exists. Please sign in.';

  @override
  String get signup_errorGeneric =>
      'Could not create account. Please try again.';

  @override
  String get legal_acceptTitle => 'Terms & Privacy';

  @override
  String get legal_acceptBody =>
      'To continue using KvikTime, please review and accept our Terms of Service and Privacy Policy.';

  @override
  String get legal_acceptButton => 'I Accept';

  @override
  String get reportsCustom_periodToday => 'Today';

  @override
  String get reportsCustom_periodThisWeek => 'This week';

  @override
  String get reportsCustom_periodLast7Days => 'Last 7 days';

  @override
  String get reportsCustom_periodThisMonth => 'This month';

  @override
  String get reportsCustom_periodLastMonth => 'Last month';

  @override
  String get reportsCustom_periodThisYear => 'This year';

  @override
  String get reportsCustom_periodCustom => 'Custom...';

  @override
  String get reportsCustom_filterAll => 'All';

  @override
  String get reportsCustom_filterWork => 'Work';

  @override
  String get reportsCustom_filterTravel => 'Travel';

  @override
  String get reportsCustom_filterLeave => 'Leaves';

  @override
  String get reportsCustom_workDays => 'Work days';

  @override
  String get reportsCustom_daysWithWork => 'Days with work';

  @override
  String get reportsCustom_averagePerDay => 'Average per day';

  @override
  String get reportsCustom_workedTime => 'Worked time';

  @override
  String get reportsCustom_breaks => 'Breaks';

  @override
  String reportsCustom_breakAveragePerShift(String value) {
    return '$value / shift';
  }

  @override
  String get reportsCustom_longestShift => 'Longest shift';

  @override
  String get reportsCustom_noLocationProvided => 'No location provided';

  @override
  String get reportsCustom_travelTime => 'Travel time';

  @override
  String get reportsCustom_totalTravelTime => 'Total travel time';

  @override
  String get reportsCustom_trips => 'Trips';

  @override
  String get reportsCustom_tripCount => 'Number of trips';

  @override
  String get reportsCustom_averagePerTrip => 'Average per trip';

  @override
  String get reportsCustom_averageTravelTime => 'Average travel time';

  @override
  String get reportsCustom_topRoutes => 'Top routes';

  @override
  String reportsCustom_topRouteLine(String route, int count, String duration) {
    return '$route - $count trips - $duration';
  }

  @override
  String get reportsCustom_leaveDays => 'Leave days';

  @override
  String get reportsCustom_totalInPeriod => 'Total in period';

  @override
  String get reportsCustom_leaveEntries => 'Leave entries';

  @override
  String get reportsCustom_registeredEntries => 'Registered entries';

  @override
  String get reportsCustom_paidLeave => 'Credited leave';

  @override
  String get reportsCustom_paidLeaveTypes => 'Vacation/Sick/VAB';

  @override
  String get reportsCustom_unpaidLeave => 'Unpaid leave';

  @override
  String get reportsCustom_unpaidLeaveType => 'Unpaid leave';

  @override
  String get reportsCustom_balanceAdjustments => 'Balance adjustments';

  @override
  String reportsCustom_openingBalanceEffectiveFrom(String value, String date) {
    return 'Opening balance: $value (effective from $date)';
  }

  @override
  String reportsCustom_timeAdjustmentsTotal(String value) {
    return 'Time adjustments: $value';
  }

  @override
  String get reportsCustom_timeAdjustmentsInPeriod =>
      'Time adjustments in period';

  @override
  String get reportsCustom_noNote => 'No note';

  @override
  String reportsCustom_balanceAtPeriodStart(String value) {
    return 'Balance at period start: $value';
  }

  @override
  String reportsCustom_balanceAtPeriodEnd(String value) {
    return 'Balance at period end: $value';
  }

  @override
  String get reportsCustom_periodStartIncludesStartDateAdjustmentsHint =>
      'Adjustments on the start date are included in the period start balance.';

  @override
  String get reportsCustom_entriesInPeriod => 'Entries in period';

  @override
  String get reportsCustom_emptyTitle => 'No entries in this period';

  @override
  String get reportsCustom_emptySubtitle => 'Change period or filter';

  @override
  String get reportsCustom_exportCsv => 'Export CSV';

  @override
  String get reportsCustom_exportExcel => 'Export Excel';

  @override
  String get reportsCustom_exportCsvDone => 'Export CSV: done';

  @override
  String get reportsCustom_exportExcelDone => 'Export Excel: done';

  @override
  String reportsCustom_exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get reportsExport_entriesSheetName => 'Entries';

  @override
  String get reportsExport_adjustmentsSheetName => 'Balance adjustments';

  @override
  String get reportsExport_openingBalanceRow => 'Opening balance';

  @override
  String get reportsExport_timeAdjustmentRow => 'Time adjustment';

  @override
  String get reportsExport_timeAdjustmentsTotalRow => 'Time adjustments total';

  @override
  String get reportsExport_periodStartBalanceRow => 'Balance at period start';

  @override
  String get reportsExport_periodEndBalanceRow => 'Balance at period end';

  @override
  String get reportsExport_colType => 'Type';

  @override
  String get reportsExport_colDate => 'Date';

  @override
  String get reportsExport_colMinutes => 'Minutes';

  @override
  String get reportsExport_colHours => 'Hours';

  @override
  String get reportsExport_colNote => 'Note';

  @override
  String get reportsExport_fileName => 'report_export';

  @override
  String get reportsMetric_tracked => 'Tracked';

  @override
  String get reportsMetric_leave => 'Leave';

  @override
  String get reportsMetric_accounted => 'Accounted';

  @override
  String get reportsMetric_delta => 'Delta';

  @override
  String get reportsMetric_trackedPlusLeave => 'Tracked + leave';

  @override
  String get reportsMetric_accountedMinusTarget => 'Accounted - target';

  @override
  String get session_expiredTitle => 'Session Expired';

  @override
  String get session_expiredBody =>
      'Your session has expired. Please sign in again to continue.';

  @override
  String get session_signInAgain => 'Sign In Again';

  @override
  String get common_continue => 'Continue';

  @override
  String get onboarding_step1Title => 'Welcome';

  @override
  String get onboarding_step2Title => 'Contract';

  @override
  String get onboarding_step3Title => 'Starting balance';

  @override
  String onboarding_stepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboarding_modeQuestion => 'How do you want to use KvikTime?';

  @override
  String get onboarding_modeSubtitle =>
      'Set the basics once and track the change over time.';

  @override
  String get onboarding_modeBalance => 'Time balance (recommended)';

  @override
  String get onboarding_modeLogOnly => 'Log time only';

  @override
  String get onboarding_toggleTravel => 'Log travel time';

  @override
  String get onboarding_togglePaidLeave => 'Track paid leave';

  @override
  String get onboarding_contractTitle => 'Quick contract setup';

  @override
  String get onboarding_contractBody =>
      'We prefill safe defaults so you can get started quickly.';

  @override
  String onboarding_contractWorkdays(int days) {
    return 'Workdays: $days';
  }

  @override
  String get onboarding_baselineTitle => 'What\'s your plus/minus right now?';

  @override
  String get onboarding_baselineHelp =>
      'Ask payroll/manager: What is my plus/minus today?';

  @override
  String get onboarding_baselineNote => 'Do not enter total worked time.';

  @override
  String get onboarding_baselineLabel => 'Balance baseline';

  @override
  String get onboarding_baselinePlaceholder => '+29h or -5h';

  @override
  String get onboarding_baselineError =>
      'Enter a balance like +29h, -5h, or +29h 30m.';

  @override
  String get legal_documentNotFound => 'Document not found';

  @override
  String get legal_documentLoadFailed => 'Failed to load document';

  @override
  String get accountStatus_loading => 'Checking account status...';

  @override
  String get accountStatus_setupIncompleteTitle => 'Account setup incomplete';

  @override
  String get accountStatus_setupIncompleteBody =>
      'We could not finish setting up your account profile. Please retry.';

  @override
  String accountStatus_loadFailed(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get exportHeader_type => 'Type';

  @override
  String get exportHeader_date => 'Date';

  @override
  String get exportHeader_from => 'From';

  @override
  String get exportHeader_to => 'To';

  @override
  String get exportHeader_travelMinutes => 'Travel Minutes';

  @override
  String get exportHeader_travelDistance => 'Travel Distance (km)';

  @override
  String get exportHeader_shiftNumber => 'Shift Number';

  @override
  String get exportHeader_shiftStart => 'Shift Start';

  @override
  String get exportHeader_shiftEnd => 'Shift End';

  @override
  String get exportHeader_spanMinutes => 'Span Minutes';

  @override
  String get exportHeader_unpaidBreakMinutes => 'Unpaid Break Minutes';

  @override
  String get exportHeader_workedMinutes => 'Worked Minutes';

  @override
  String get exportHeader_workedHours => 'Worked Hours';

  @override
  String get exportHeader_shiftLocation => 'Shift Location';

  @override
  String get exportHeader_shiftNotes => 'Shift Notes';

  @override
  String get exportHeader_entryNotes => 'Entry Notes';

  @override
  String get exportHeader_createdAt => 'Created At';

  @override
  String get exportHeader_updatedAt => 'Updated At';

  @override
  String get exportHeader_holidayWork => 'Holiday Work';

  @override
  String get exportHeader_holidayName => 'Holiday Name';

  @override
  String get exportHeader_minutes => 'Minutes';

  @override
  String get exportHeader_notes => 'Notes';

  @override
  String get exportHeader_paidUnpaid => 'Paid/Unpaid';

  @override
  String get exportSummary_generatedAt => 'Generated at';

  @override
  String get exportSummary_trackedWork => 'Tracked work';

  @override
  String get exportSummary_trackedTravel => 'Tracked travel';

  @override
  String get exportSummary_balanceOffsets => 'Balance offsets';

  @override
  String get exportSummary_manualAdjustments => 'Manual adjustments';

  @override
  String get exportSummary_contractSettings => 'Contract settings';

  @override
  String get exportSummary_carryOver => 'Carry-over from earlier';

  @override
  String get exportSummary_manualCorrections =>
      'Manual corrections in this period';

  @override
  String get exportSummary_balanceAtStart =>
      'Balance at start of selected period';

  @override
  String get exportSummary_balanceAfterThis => 'Balance after this period';

  @override
  String get exportSummary_totalTrackedOnly => 'TOTAL (tracked only)';

  @override
  String get exportSummary_paidLeaveCredit => 'Paid leave credit';

  @override
  String exportSummary_paidLeaveCreditNote(String hours) {
    return 'Paid leave credit: ${hours}h (not worked)';
  }

  @override
  String exportSummary_totalTrackedExcludes(String sheetName) {
    return 'TOTAL (tracked only) excludes Leave and Balance events. See $sheetName.';
  }

  @override
  String get export_leaveSick => 'Leave (Sick)';

  @override
  String get export_leaveVab => 'VAB';

  @override
  String get export_leavePaidVacation => 'Leave (Paid Vacation)';

  @override
  String get export_leaveUnpaid => 'Unpaid Leave';

  @override
  String get export_leaveUnknown => 'Leave (Unknown)';

  @override
  String get export_paid => 'Paid';

  @override
  String get export_unpaid => 'Unpaid';

  @override
  String get export_yes => 'Yes';

  @override
  String get export_no => 'No';

  @override
  String get export_total => 'TOTAL';

  @override
  String get export_errorEmptyData => 'Generated export data is empty';

  @override
  String get export_errorUnsupportedFormat => 'Unsupported export format';

  @override
  String get export_errorMissingConfig => 'Missing configuration';

  @override
  String get export_summarySheetName => 'Summary (Easy)';

  @override
  String get export_balanceEventsSheetName => 'Balance Events';
}
