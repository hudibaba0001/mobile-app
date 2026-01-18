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
  String get entry_notes => 'Notes (Optional)';

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

  @override
  String get entry_saveEntry => 'Save Entry';

  @override
  String get entry_editEntry => 'Edit Entry';

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
  String get account_createTitle => 'Create Account';

  @override
  String get account_createOnWeb => 'Create your account on the web';

  @override
  String get account_createDescription =>
      'To create an account, please visit our signup page in your web browser.';

  @override
  String get account_openSignupPage => 'Open signup page';

  @override
  String get account_alreadyHaveAccount => 'I already have an account → Login';

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
  String get location_fullAddress => 'Full address';

  @override
  String get auth_legalRequired => 'Legal Acceptance Required';

  @override
  String get auth_legalDescription =>
      'You must accept our Terms of Service and Privacy Policy to continue using the app.';

  @override
  String get auth_legalVisitSignup =>
      'Please visit our signup page to complete this step.';

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
    return 'Hours Worked (to date): $worked / $target h';
  }

  @override
  String get balance_over => 'Over';

  @override
  String get balance_under => 'Under';

  @override
  String get balance_timeDebt => 'You maintain a time debt';

  @override
  String balance_includesOpeningBalance(String balance, String date) {
    return 'Includes opening balance ($balance) as of $date';
  }

  @override
  String balance_includesOpeningBalanceShort(String balance) {
    return 'Includes opening balance ($balance)';
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
  String get home_paidLeave => 'Paid Leave';

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
}
