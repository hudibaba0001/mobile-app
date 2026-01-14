import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'KvikTime'**
  String get appTitle;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset;

  /// No description provided for @common_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get common_share;

  /// No description provided for @common_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get common_export;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get common_thisWeek;

  /// No description provided for @common_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get common_thisMonth;

  /// No description provided for @common_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get common_thisYear;

  /// No description provided for @common_days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# day} other {# days}}'**
  String common_days(int count);

  /// No description provided for @common_hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# hour} other {# hours}}'**
  String common_hours(int count);

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get nav_calendar;

  /// No description provided for @nav_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get nav_reports;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settings_signOut;

  /// No description provided for @settings_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get settings_signUp;

  /// No description provided for @settings_manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settings_manageSubscription;

  /// No description provided for @settings_contractSettings.
  ///
  /// In en, this message translates to:
  /// **'Contract Settings'**
  String get settings_contractSettings;

  /// No description provided for @settings_contractDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your contract percentage and work hours'**
  String get settings_contractDescription;

  /// No description provided for @settings_publicHolidays.
  ///
  /// In en, this message translates to:
  /// **'Public Holidays'**
  String get settings_publicHolidays;

  /// No description provided for @settings_autoMarkHolidays.
  ///
  /// In en, this message translates to:
  /// **'Auto-mark public holidays'**
  String get settings_autoMarkHolidays;

  /// No description provided for @settings_holidayRegion.
  ///
  /// In en, this message translates to:
  /// **'Sweden (Svenska helgdagar)'**
  String get settings_holidayRegion;

  /// No description provided for @settings_viewHolidays.
  ///
  /// In en, this message translates to:
  /// **'View holidays for {year}'**
  String settings_viewHolidays(int year);

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_themeLight;

  /// No description provided for @settings_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_themeDark;

  /// No description provided for @settings_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_themeSystem;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settings_languageSystem;

  /// No description provided for @settings_data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settings_data;

  /// No description provided for @settings_clearDemoData.
  ///
  /// In en, this message translates to:
  /// **'Clear Demo Data'**
  String get settings_clearDemoData;

  /// No description provided for @settings_clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settings_clearAllData;

  /// No description provided for @settings_clearDemoDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove all demo entries. Are you sure?'**
  String get settings_clearDemoDataConfirm;

  /// No description provided for @settings_clearAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL your data. This action cannot be undone. Are you sure?'**
  String get settings_clearAllDataConfirm;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settings_version(String version);

  /// No description provided for @settings_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settings_terms;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacy;

  /// No description provided for @contract_title.
  ///
  /// In en, this message translates to:
  /// **'Contract Settings'**
  String get contract_title;

  /// No description provided for @contract_headerTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract Settings'**
  String get contract_headerTitle;

  /// No description provided for @contract_headerDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure your contract percentage and full-time hours for accurate work time tracking and overtime calculations.'**
  String get contract_headerDescription;

  /// No description provided for @contract_percentage.
  ///
  /// In en, this message translates to:
  /// **'Contract Percentage'**
  String get contract_percentage;

  /// No description provided for @contract_percentageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter percentage (0-100)'**
  String get contract_percentageHint;

  /// No description provided for @contract_percentageError.
  ///
  /// In en, this message translates to:
  /// **'Percentage must be between 0 and 100'**
  String get contract_percentageError;

  /// No description provided for @contract_fullTimeHours.
  ///
  /// In en, this message translates to:
  /// **'Full-time Hours per Week'**
  String get contract_fullTimeHours;

  /// No description provided for @contract_fullTimeHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Enter hours per week (e.g., 40)'**
  String get contract_fullTimeHoursHint;

  /// No description provided for @contract_fullTimeHoursError.
  ///
  /// In en, this message translates to:
  /// **'Hours must be greater than 0'**
  String get contract_fullTimeHoursError;

  /// No description provided for @contract_startingBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get contract_startingBalance;

  /// No description provided for @contract_startingBalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your starting point for balance calculations. Ask your manager for your flex saldo as of this date.'**
  String get contract_startingBalanceDescription;

  /// No description provided for @contract_startTrackingFrom.
  ///
  /// In en, this message translates to:
  /// **'Start tracking from'**
  String get contract_startTrackingFrom;

  /// No description provided for @contract_openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening time balance'**
  String get contract_openingBalance;

  /// No description provided for @contract_creditPlus.
  ///
  /// In en, this message translates to:
  /// **'Credit (+)'**
  String get contract_creditPlus;

  /// No description provided for @contract_deficitMinus.
  ///
  /// In en, this message translates to:
  /// **'Deficit (−)'**
  String get contract_deficitMinus;

  /// No description provided for @contract_creditExplanation.
  ///
  /// In en, this message translates to:
  /// **'Credit means you have extra time (ahead of schedule)'**
  String get contract_creditExplanation;

  /// No description provided for @contract_deficitExplanation.
  ///
  /// In en, this message translates to:
  /// **'Deficit means you owe time (behind schedule)'**
  String get contract_deficitExplanation;

  /// No description provided for @contract_livePreview.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get contract_livePreview;

  /// No description provided for @contract_contractType.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contract_contractType;

  /// No description provided for @contract_fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get contract_fullTime;

  /// No description provided for @contract_partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get contract_partTime;

  /// No description provided for @contract_allowedHours.
  ///
  /// In en, this message translates to:
  /// **'Allowed Hours'**
  String get contract_allowedHours;

  /// No description provided for @contract_dailyHours.
  ///
  /// In en, this message translates to:
  /// **'Daily Hours'**
  String get contract_dailyHours;

  /// No description provided for @contract_resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get contract_resetToDefaults;

  /// No description provided for @contract_resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will reset your contract settings to 100% full-time with 40 hours per week, and clear your starting balance. Are you sure?'**
  String get contract_resetConfirm;

  /// No description provided for @contract_saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get contract_saveSettings;

  /// No description provided for @contract_savedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contract settings saved successfully!'**
  String get contract_savedSuccess;

  /// No description provided for @contract_resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contract settings reset to defaults'**
  String get contract_resetSuccess;

  /// No description provided for @balance_title.
  ///
  /// In en, this message translates to:
  /// **'Time Balance'**
  String get balance_title;

  /// No description provided for @balance_myTimeBalance.
  ///
  /// In en, this message translates to:
  /// **'My Time Balance ({year})'**
  String balance_myTimeBalance(int year);

  /// No description provided for @balance_thisYear.
  ///
  /// In en, this message translates to:
  /// **'THIS YEAR: {year}'**
  String balance_thisYear(int year);

  /// No description provided for @balance_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH: {month}'**
  String balance_thisMonth(String month);

  /// No description provided for @balance_hoursWorkedToDate.
  ///
  /// In en, this message translates to:
  /// **'Hours Worked (to date): {worked} / {target} h'**
  String balance_hoursWorkedToDate(String worked, String target);

  /// No description provided for @balance_creditedHours.
  ///
  /// In en, this message translates to:
  /// **'Credited Hours: {hours} h'**
  String balance_creditedHours(String hours);

  /// No description provided for @balance_statusOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get balance_statusOver;

  /// No description provided for @balance_statusUnder.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get balance_statusUnder;

  /// No description provided for @balance_status.
  ///
  /// In en, this message translates to:
  /// **'Status: {variance} h ({status})'**
  String balance_status(String variance, String status);

  /// No description provided for @balance_percentOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of target'**
  String balance_percentOfTarget(String percent);

  /// No description provided for @balance_yearlyRunningBalance.
  ///
  /// In en, this message translates to:
  /// **'YEARLY RUNNING BALANCE'**
  String get balance_yearlyRunningBalance;

  /// No description provided for @balance_totalAccumulation.
  ///
  /// In en, this message translates to:
  /// **'Total Accumulation:'**
  String get balance_totalAccumulation;

  /// No description provided for @balance_inCredit.
  ///
  /// In en, this message translates to:
  /// **'You are in credit'**
  String get balance_inCredit;

  /// No description provided for @balance_inDebt.
  ///
  /// In en, this message translates to:
  /// **'You maintain a time debt'**
  String get balance_inDebt;

  /// No description provided for @balance_includesOpening.
  ///
  /// In en, this message translates to:
  /// **'Includes opening balance ({balance}) as of {date}'**
  String balance_includesOpening(String balance, String date);

  /// No description provided for @adjustment_title.
  ///
  /// In en, this message translates to:
  /// **'Balance Adjustments'**
  String get adjustment_title;

  /// No description provided for @adjustment_description.
  ///
  /// In en, this message translates to:
  /// **'Manual corrections to your balance (e.g., manager adjustments)'**
  String get adjustment_description;

  /// No description provided for @adjustment_add.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get adjustment_add;

  /// No description provided for @adjustment_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Adjustment'**
  String get adjustment_edit;

  /// No description provided for @adjustment_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent Adjustments'**
  String get adjustment_recent;

  /// No description provided for @adjustment_effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get adjustment_effectiveDate;

  /// No description provided for @adjustment_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adjustment_amount;

  /// No description provided for @adjustment_noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get adjustment_noteOptional;

  /// No description provided for @adjustment_noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Manager correction'**
  String get adjustment_noteHint;

  /// No description provided for @adjustment_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this adjustment?'**
  String get adjustment_deleteConfirm;

  /// No description provided for @adjustment_saveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String adjustment_saveError(String error);

  /// No description provided for @adjustment_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an adjustment amount'**
  String get adjustment_enterAmount;

  /// No description provided for @adjustment_minutesError.
  ///
  /// In en, this message translates to:
  /// **'Minutes must be between 0 and 59'**
  String get adjustment_minutesError;

  /// No description provided for @redDay_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get redDay_auto;

  /// No description provided for @redDay_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get redDay_personal;

  /// No description provided for @redDay_fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get redDay_fullDay;

  /// No description provided for @redDay_halfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get redDay_halfDay;

  /// No description provided for @redDay_am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get redDay_am;

  /// No description provided for @redDay_pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get redDay_pm;

  /// No description provided for @redDay_publicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Public holiday in Sweden'**
  String get redDay_publicHoliday;

  /// No description provided for @redDay_autoMarked.
  ///
  /// In en, this message translates to:
  /// **'Auto-marked: {holidayName}'**
  String redDay_autoMarked(String holidayName);

  /// No description provided for @redDay_holidayWorkNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a public holiday (Auto). Hours entered here may count as holiday work.'**
  String get redDay_holidayWorkNotice;

  /// No description provided for @redDay_personalNotice.
  ///
  /// In en, this message translates to:
  /// **'Red day (Personal). Hours entered may count as holiday work.'**
  String get redDay_personalNotice;

  /// No description provided for @redDay_addPersonal.
  ///
  /// In en, this message translates to:
  /// **'Add Personal Red Day'**
  String get redDay_addPersonal;

  /// No description provided for @redDay_editPersonal.
  ///
  /// In en, this message translates to:
  /// **'Edit Personal Red Day'**
  String get redDay_editPersonal;

  /// No description provided for @redDay_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get redDay_reason;

  /// No description provided for @redDay_halfDayReducesScheduled.
  ///
  /// In en, this message translates to:
  /// **'Half-day red day reduces scheduled hours by 50%.'**
  String get redDay_halfDayReducesScheduled;

  /// No description provided for @leave_title.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leave_title;

  /// No description provided for @leave_summary.
  ///
  /// In en, this message translates to:
  /// **'Leave Summary {year}'**
  String leave_summary(int year);

  /// No description provided for @leave_paidVacation.
  ///
  /// In en, this message translates to:
  /// **'Paid Vacation'**
  String get leave_paidVacation;

  /// No description provided for @leave_sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get leave_sickLeave;

  /// No description provided for @leave_vab.
  ///
  /// In en, this message translates to:
  /// **'VAB (Child Care)'**
  String get leave_vab;

  /// No description provided for @leave_unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Leave'**
  String get leave_unpaid;

  /// No description provided for @leave_totalDays.
  ///
  /// In en, this message translates to:
  /// **'Total Leave Days'**
  String get leave_totalDays;

  /// No description provided for @leave_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent Leaves'**
  String get leave_recent;

  /// No description provided for @leave_noRecords.
  ///
  /// In en, this message translates to:
  /// **'No leaves recorded'**
  String get leave_noRecords;

  /// No description provided for @leave_historyAppears.
  ///
  /// In en, this message translates to:
  /// **'Your leave history will appear here'**
  String get leave_historyAppears;

  /// No description provided for @leave_daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {0 days} =1 {1 day} other {{count} days}}'**
  String leave_daysCount(int count);

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reports_title;

  /// No description provided for @reports_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reports_overview;

  /// No description provided for @reports_trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get reports_trends;

  /// No description provided for @reports_timeBalance.
  ///
  /// In en, this message translates to:
  /// **'Time Balance'**
  String get reports_timeBalance;

  /// No description provided for @reports_leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get reports_leaves;

  /// No description provided for @reports_exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get reports_exportData;

  /// No description provided for @reports_serverAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Server analytics'**
  String get reports_serverAnalytics;

  /// No description provided for @export_title.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get export_title;

  /// No description provided for @export_format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get export_format;

  /// No description provided for @export_excel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get export_excel;

  /// No description provided for @export_csv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get export_csv;

  /// No description provided for @export_dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get export_dateRange;

  /// No description provided for @export_allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get export_allTime;

  /// No description provided for @export_fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get export_fileName;

  /// No description provided for @export_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating {format} export...'**
  String export_generating(String format);

  /// No description provided for @export_complete.
  ///
  /// In en, this message translates to:
  /// **'Export Complete'**
  String get export_complete;

  /// No description provided for @export_savedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{format} file has been saved successfully.'**
  String export_savedSuccess(String format);

  /// No description provided for @export_sharePrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to share it via email or another app?'**
  String get export_sharePrompt;

  /// No description provided for @export_downloadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{format} file downloaded successfully!'**
  String export_downloadedSuccess(String format);

  /// No description provided for @export_failed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String export_failed(String error);

  /// No description provided for @export_noData.
  ///
  /// In en, this message translates to:
  /// **'No data available for export'**
  String get export_noData;

  /// No description provided for @export_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries to export. Please select entries with data.'**
  String get export_noEntries;

  /// No description provided for @home_todaysTotals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Totals'**
  String get home_todaysTotals;

  /// No description provided for @home_weeklyStats.
  ///
  /// In en, this message translates to:
  /// **'Weekly Stats'**
  String get home_weeklyStats;

  /// No description provided for @home_quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get home_quickActions;

  /// No description provided for @home_recentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent Entries'**
  String get home_recentEntries;

  /// No description provided for @home_addWork.
  ///
  /// In en, this message translates to:
  /// **'Add Work'**
  String get home_addWork;

  /// No description provided for @home_addTravel.
  ///
  /// In en, this message translates to:
  /// **'Add Travel'**
  String get home_addTravel;

  /// No description provided for @home_addLeave.
  ///
  /// In en, this message translates to:
  /// **'Add Leave'**
  String get home_addLeave;

  /// No description provided for @home_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get home_viewAll;

  /// No description provided for @home_noEntries.
  ///
  /// In en, this message translates to:
  /// **'No recent entries'**
  String get home_noEntries;

  /// No description provided for @home_holidayWork.
  ///
  /// In en, this message translates to:
  /// **'Holiday Work'**
  String get home_holidayWork;

  /// No description provided for @entry_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get entry_travel;

  /// No description provided for @entry_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get entry_work;

  /// No description provided for @entry_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get entry_from;

  /// No description provided for @entry_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get entry_to;

  /// No description provided for @entry_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get entry_duration;

  /// No description provided for @entry_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entry_date;

  /// No description provided for @entry_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get entry_notes;

  /// No description provided for @entry_shifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get entry_shifts;

  /// No description provided for @entry_addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get entry_addShift;

  /// No description provided for @error_loadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get error_loadingData;

  /// No description provided for @error_loadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Error loading balance'**
  String get error_loadingBalance;

  /// No description provided for @error_userNotAuth.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get error_userNotAuth;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error_generic;

  /// No description provided for @error_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get error_networkError;

  /// No description provided for @absence_title.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get absence_title;

  /// No description provided for @absence_addAbsence.
  ///
  /// In en, this message translates to:
  /// **'Add Absence'**
  String get absence_addAbsence;

  /// No description provided for @absence_editAbsence.
  ///
  /// In en, this message translates to:
  /// **'Edit Absence'**
  String get absence_editAbsence;

  /// No description provided for @absence_deleteAbsence.
  ///
  /// In en, this message translates to:
  /// **'Delete Absence'**
  String get absence_deleteAbsence;

  /// No description provided for @absence_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this absence?'**
  String get absence_deleteConfirm;

  /// No description provided for @absence_noAbsences.
  ///
  /// In en, this message translates to:
  /// **'No absences for {year}'**
  String absence_noAbsences(int year);

  /// No description provided for @absence_addHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add vacation, sick leave, or VAB'**
  String get absence_addHint;

  /// No description provided for @absence_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading absences'**
  String get absence_errorLoading;

  /// No description provided for @absence_type.
  ///
  /// In en, this message translates to:
  /// **'Absence Type'**
  String get absence_type;

  /// No description provided for @absence_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get absence_date;

  /// No description provided for @absence_halfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get absence_halfDay;

  /// No description provided for @absence_fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get absence_fullDay;

  /// No description provided for @absence_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get absence_notes;

  /// No description provided for @absence_savedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Absence saved successfully'**
  String get absence_savedSuccess;

  /// No description provided for @absence_deletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Absence deleted'**
  String get absence_deletedSuccess;

  /// No description provided for @absence_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save absence'**
  String get absence_saveFailed;

  /// No description provided for @absence_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete absence'**
  String get absence_deleteFailed;

  /// No description provided for @settings_manageLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get settings_manageLocations;

  /// No description provided for @settings_manageLocationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add and edit your frequent locations'**
  String get settings_manageLocationsDesc;

  /// No description provided for @settings_absences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get settings_absences;

  /// No description provided for @settings_absencesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage vacation, sick leave, and VAB'**
  String get settings_absencesDesc;

  /// No description provided for @settings_subscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Update payment method and subscription plan'**
  String get settings_subscriptionDesc;

  /// No description provided for @settings_welcomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Show Welcome Screen'**
  String get settings_welcomeScreen;

  /// No description provided for @settings_welcomeScreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Show introduction on next launch'**
  String get settings_welcomeScreenDesc;

  /// No description provided for @settings_region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settings_region;

  /// No description provided for @common_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get common_unknown;

  /// No description provided for @common_noRemarks.
  ///
  /// In en, this message translates to:
  /// **'No remarks'**
  String get common_noRemarks;

  /// No description provided for @common_workSession.
  ///
  /// In en, this message translates to:
  /// **'Work Session'**
  String get common_workSession;

  /// No description provided for @common_confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get common_confirmDelete;

  /// No description provided for @common_durationFormat.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String common_durationFormat(int hours, int minutes);

  /// No description provided for @common_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get common_profile;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String common_required(String field);

  /// No description provided for @common_invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get common_invalidNumber;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Time Tracker'**
  String get home_title;

  /// No description provided for @home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your productivity'**
  String get home_subtitle;

  /// No description provided for @home_logTravel.
  ///
  /// In en, this message translates to:
  /// **'Log Travel'**
  String get home_logTravel;

  /// No description provided for @home_logWork.
  ///
  /// In en, this message translates to:
  /// **'Log Work'**
  String get home_logWork;

  /// No description provided for @home_quickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get home_quickEntry;

  /// No description provided for @home_quickTravelEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick travel entry'**
  String get home_quickTravelEntry;

  /// No description provided for @home_quickWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick work entry'**
  String get home_quickWorkEntry;

  /// No description provided for @home_noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get home_noEntriesYet;

  /// No description provided for @home_viewAllArrow.
  ///
  /// In en, this message translates to:
  /// **'View All →'**
  String get home_viewAllArrow;

  /// No description provided for @home_travelRoute.
  ///
  /// In en, this message translates to:
  /// **'Travel: {from} → {to}'**
  String home_travelRoute(String from, String to);

  /// No description provided for @home_fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get home_fullDay;

  /// No description provided for @entry_deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get entry_deleteEntry;

  /// No description provided for @entry_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this {type} entry?'**
  String entry_deleteConfirm(String type);

  /// No description provided for @entry_deletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type} entry deleted successfully'**
  String entry_deletedSuccess(String type);

  /// No description provided for @error_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete entry: {error}'**
  String error_deleteFailed(String error);

  /// No description provided for @error_loadingEntries.
  ///
  /// In en, this message translates to:
  /// **'Error loading entries: {error}'**
  String error_loadingEntries(String error);

  /// No description provided for @contract_maxHoursError.
  ///
  /// In en, this message translates to:
  /// **'Hours cannot exceed 168 per week'**
  String get contract_maxHoursError;

  /// No description provided for @contract_invalidHours.
  ///
  /// In en, this message translates to:
  /// **'Invalid hours'**
  String get contract_invalidHours;

  /// No description provided for @contract_minutesError.
  ///
  /// In en, this message translates to:
  /// **'Minutes must be 0-59'**
  String get contract_minutesError;

  /// No description provided for @contract_hoursPerDayValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours/day'**
  String contract_hoursPerDayValue(String hours);

  /// No description provided for @contract_hrsWeek.
  ///
  /// In en, this message translates to:
  /// **'hrs/week'**
  String get contract_hrsWeek;

  /// No description provided for @export_shareSubject.
  ///
  /// In en, this message translates to:
  /// **'Time Tracker Export - {fileName}'**
  String export_shareSubject(String fileName);

  /// No description provided for @export_shareText.
  ///
  /// In en, this message translates to:
  /// **'Please find attached the time tracker report.'**
  String get export_shareText;

  /// No description provided for @error_shareFile.
  ///
  /// In en, this message translates to:
  /// **'Could not share file: {error}'**
  String error_shareFile(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
