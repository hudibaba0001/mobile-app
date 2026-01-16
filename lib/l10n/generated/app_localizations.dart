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

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_saved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get common_saved;

  /// No description provided for @common_updated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get common_updated;

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

  /// No description provided for @entry_saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get entry_saveEntry;

  /// No description provided for @entry_editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get entry_editEntry;

  /// No description provided for @entry_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get entry_deleteTitle;

  /// No description provided for @error_selectBothLocations.
  ///
  /// In en, this message translates to:
  /// **'Please select both departure and arrival locations'**
  String get error_selectBothLocations;

  /// No description provided for @error_selectWorkLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a work location'**
  String get error_selectWorkLocation;

  /// No description provided for @error_selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select an end time'**
  String get error_selectEndTime;

  /// No description provided for @error_signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to save entries'**
  String get error_signInRequired;

  /// No description provided for @error_savingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error saving entry: {error}'**
  String error_savingEntry(String error);

  /// No description provided for @error_calculatingTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate travel time: {error}'**
  String error_calculatingTravelTime(String error);

  /// No description provided for @form_departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get form_departure;

  /// No description provided for @form_arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get form_arrival;

  /// No description provided for @form_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get form_location;

  /// No description provided for @form_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get form_date;

  /// No description provided for @form_startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get form_startTime;

  /// No description provided for @form_endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get form_endTime;

  /// No description provided for @form_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get form_duration;

  /// No description provided for @form_notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get form_notesOptional;

  /// No description provided for @form_selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select a location'**
  String get form_selectLocation;

  /// No description provided for @form_calculateFromLocations.
  ///
  /// In en, this message translates to:
  /// **'Calculate from locations'**
  String get form_calculateFromLocations;

  /// No description provided for @form_manualDuration.
  ///
  /// In en, this message translates to:
  /// **'Manual Duration'**
  String get form_manualDuration;

  /// No description provided for @form_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get form_hours;

  /// No description provided for @form_minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get form_minutes;

  /// No description provided for @export_includeAllData.
  ///
  /// In en, this message translates to:
  /// **'Include all data'**
  String get export_includeAllData;

  /// No description provided for @export_includeAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all entries regardless of date'**
  String get export_includeAllDataDesc;

  /// No description provided for @export_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get export_startDate;

  /// No description provided for @export_endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get export_endDate;

  /// No description provided for @export_selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get export_selectStartDate;

  /// No description provided for @export_selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get export_selectEndDate;

  /// No description provided for @export_entryType.
  ///
  /// In en, this message translates to:
  /// **'Entry Type'**
  String get export_entryType;

  /// No description provided for @export_travelOnly.
  ///
  /// In en, this message translates to:
  /// **'Travel Entries Only'**
  String get export_travelOnly;

  /// No description provided for @export_travelOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Export only travel time entries'**
  String get export_travelOnlyDesc;

  /// No description provided for @export_workOnly.
  ///
  /// In en, this message translates to:
  /// **'Work Entries Only'**
  String get export_workOnly;

  /// No description provided for @export_workOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Export only work shift entries'**
  String get export_workOnlyDesc;

  /// No description provided for @export_both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get export_both;

  /// No description provided for @export_bothDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all entries (travel + work)'**
  String get export_bothDesc;

  /// No description provided for @export_formatTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get export_formatTitle;

  /// No description provided for @export_excelFormat.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx)'**
  String get export_excelFormat;

  /// No description provided for @export_excelDesc.
  ///
  /// In en, this message translates to:
  /// **'Professional format with formatting'**
  String get export_excelDesc;

  /// No description provided for @export_csvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV (.csv)'**
  String get export_csvFormat;

  /// No description provided for @export_csvDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple text format'**
  String get export_csvDesc;

  /// No description provided for @export_options.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get export_options;

  /// No description provided for @export_filename.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get export_filename;

  /// No description provided for @export_filenameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter custom filename'**
  String get export_filenameHint;

  /// No description provided for @export_summary.
  ///
  /// In en, this message translates to:
  /// **'Export Summary'**
  String get export_summary;

  /// No description provided for @export_totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total entries: {count}'**
  String export_totalEntries(int count);

  /// No description provided for @export_travelEntries.
  ///
  /// In en, this message translates to:
  /// **'Travel entries: {count}'**
  String export_travelEntries(int count);

  /// No description provided for @export_workEntries.
  ///
  /// In en, this message translates to:
  /// **'Work entries: {count}'**
  String export_workEntries(int count);

  /// No description provided for @export_totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total hours: {hours}'**
  String export_totalHours(String hours);

  /// No description provided for @export_button.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export_button;

  /// No description provided for @export_enterFilename.
  ///
  /// In en, this message translates to:
  /// **'Please enter a filename'**
  String get export_enterFilename;

  /// No description provided for @export_noEntriesInRange.
  ///
  /// In en, this message translates to:
  /// **'No entries found for the selected date range'**
  String get export_noEntriesInRange;

  /// No description provided for @export_errorPreparing.
  ///
  /// In en, this message translates to:
  /// **'Error preparing export: {error}'**
  String export_errorPreparing(String error);

  /// No description provided for @redDay_editRedDay.
  ///
  /// In en, this message translates to:
  /// **'Edit Red Day'**
  String get redDay_editRedDay;

  /// No description provided for @redDay_markAsRedDay.
  ///
  /// In en, this message translates to:
  /// **'Mark as Red Day'**
  String get redDay_markAsRedDay;

  /// No description provided for @redDay_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get redDay_duration;

  /// No description provided for @redDay_morningAM.
  ///
  /// In en, this message translates to:
  /// **'Morning (AM)'**
  String get redDay_morningAM;

  /// No description provided for @redDay_afternoonPM.
  ///
  /// In en, this message translates to:
  /// **'Afternoon (PM)'**
  String get redDay_afternoonPM;

  /// No description provided for @redDay_reasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Personal day, Appointment...'**
  String get redDay_reasonHint;

  /// No description provided for @redDay_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get redDay_remove;

  /// No description provided for @redDay_removeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Red Day?'**
  String get redDay_removeTitle;

  /// No description provided for @redDay_removeMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the personal red day marker from this date.'**
  String get redDay_removeMessage;

  /// No description provided for @redDay_updated.
  ///
  /// In en, this message translates to:
  /// **'Red day updated'**
  String get redDay_updated;

  /// No description provided for @redDay_added.
  ///
  /// In en, this message translates to:
  /// **'Red day added'**
  String get redDay_added;

  /// No description provided for @redDay_removed.
  ///
  /// In en, this message translates to:
  /// **'Red day removed'**
  String get redDay_removed;

  /// No description provided for @redDay_errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving red day: {error}'**
  String redDay_errorSaving(String error);

  /// No description provided for @redDay_errorRemoving.
  ///
  /// In en, this message translates to:
  /// **'Error removing red day: {error}'**
  String redDay_errorRemoving(String error);

  /// No description provided for @adjustment_editAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Edit Adjustment'**
  String get adjustment_editAdjustment;

  /// No description provided for @adjustment_addAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get adjustment_addAdjustment;

  /// No description provided for @adjustment_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Adjustment'**
  String get adjustment_deleteTitle;

  /// No description provided for @adjustment_deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this adjustment?'**
  String get adjustment_deleteMessage;

  /// No description provided for @adjustment_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get adjustment_update;

  /// No description provided for @adjustment_failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String adjustment_failedToSave(String error);

  /// No description provided for @adjustment_failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String adjustment_failedToDelete(String error);

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profile_notSignedIn;

  /// No description provided for @profile_editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get profile_editName;

  /// No description provided for @profile_nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully'**
  String get profile_nameUpdated;

  /// No description provided for @profile_nameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update name: {error}'**
  String profile_nameUpdateFailed(String error);

  /// No description provided for @location_addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get location_addLocation;

  /// No description provided for @location_addFirstLocation.
  ///
  /// In en, this message translates to:
  /// **'Add First Location'**
  String get location_addFirstLocation;

  /// No description provided for @location_deleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Delete Location'**
  String get location_deleteLocation;

  /// No description provided for @location_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String location_deleteConfirm(String name);

  /// No description provided for @location_manageLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get location_manageLocations;

  /// No description provided for @auth_signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open signup page: {error}'**
  String auth_signupFailed(String error);

  /// No description provided for @auth_subscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open subscription page: {error}'**
  String auth_subscriptionFailed(String error);

  /// No description provided for @auth_completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get auth_completeRegistration;

  /// No description provided for @auth_openSignupPage.
  ///
  /// In en, this message translates to:
  /// **'Open Signup Page'**
  String get auth_openSignupPage;

  /// No description provided for @auth_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get auth_signOut;

  /// No description provided for @password_resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get password_resetTitle;

  /// No description provided for @password_forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get password_forgotTitle;

  /// No description provided for @password_forgotDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get password_forgotDescription;

  /// No description provided for @password_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get password_emailLabel;

  /// No description provided for @password_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get password_emailHint;

  /// No description provided for @password_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get password_emailRequired;

  /// No description provided for @password_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get password_emailInvalid;

  /// No description provided for @password_sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get password_sendResetLink;

  /// No description provided for @password_backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get password_backToSignIn;

  /// No description provided for @password_resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to your email'**
  String get password_resetLinkSent;

  /// No description provided for @welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KvikTime'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your travel time effortlessly'**
  String get welcome_subtitle;

  /// No description provided for @welcome_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get welcome_signIn;

  /// No description provided for @welcome_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcome_getStarted;

  /// No description provided for @welcome_footer.
  ///
  /// In en, this message translates to:
  /// **'New to KvikTime? Create an account to get started.'**
  String get welcome_footer;

  /// No description provided for @welcome_urlError.
  ///
  /// In en, this message translates to:
  /// **'Could not open sign up page. Please try again.'**
  String get welcome_urlError;

  /// No description provided for @edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get edit_title;

  /// No description provided for @edit_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get edit_travel;

  /// No description provided for @edit_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get edit_work;

  /// No description provided for @edit_addTravelEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Travel Entry'**
  String get edit_addTravelEntry;

  /// No description provided for @edit_addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get edit_addShift;

  /// No description provided for @edit_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get edit_notes;

  /// No description provided for @edit_notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes...'**
  String get edit_notesHint;

  /// No description provided for @edit_travelNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes for all travel entries...'**
  String get edit_travelNotesHint;

  /// No description provided for @edit_trip.
  ///
  /// In en, this message translates to:
  /// **'Trip {number}'**
  String edit_trip(int number);

  /// No description provided for @edit_shift.
  ///
  /// In en, this message translates to:
  /// **'Shift {number}'**
  String edit_shift(int number);

  /// No description provided for @edit_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get edit_from;

  /// No description provided for @edit_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get edit_to;

  /// No description provided for @edit_departureHint.
  ///
  /// In en, this message translates to:
  /// **'Departure location'**
  String get edit_departureHint;

  /// No description provided for @edit_destinationHint.
  ///
  /// In en, this message translates to:
  /// **'Destination location'**
  String get edit_destinationHint;

  /// No description provided for @edit_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get edit_hours;

  /// No description provided for @edit_minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get edit_minutes;

  /// No description provided for @edit_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get edit_total;

  /// No description provided for @edit_startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get edit_startTime;

  /// No description provided for @edit_endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get edit_endTime;

  /// No description provided for @edit_selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get edit_selectTime;

  /// No description provided for @edit_toLabel.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get edit_toLabel;

  /// No description provided for @edit_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get edit_save;

  /// No description provided for @edit_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get edit_cancel;

  /// No description provided for @edit_errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving entry: {error}'**
  String edit_errorSaving(String error);

  /// No description provided for @dateRange_title.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get dateRange_title;

  /// No description provided for @dateRange_description.
  ///
  /// In en, this message translates to:
  /// **'Choose a time period to analyze'**
  String get dateRange_description;

  /// No description provided for @dateRange_quickSelections.
  ///
  /// In en, this message translates to:
  /// **'Quick Selections'**
  String get dateRange_quickSelections;

  /// No description provided for @dateRange_customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get dateRange_customRange;

  /// No description provided for @dateRange_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get dateRange_startDate;

  /// No description provided for @dateRange_endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get dateRange_endDate;

  /// No description provided for @dateRange_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dateRange_apply;

  /// No description provided for @dateRange_last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get dateRange_last7Days;

  /// No description provided for @dateRange_last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get dateRange_last30Days;

  /// No description provided for @dateRange_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dateRange_thisMonth;

  /// No description provided for @dateRange_lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get dateRange_lastMonth;

  /// No description provided for @dateRange_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get dateRange_thisYear;

  /// No description provided for @quickEntry_signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add entries.'**
  String get quickEntry_signInRequired;

  /// No description provided for @quickEntry_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String quickEntry_error(String error);

  /// No description provided for @quickEntry_multiSegment.
  ///
  /// In en, this message translates to:
  /// **'Multi-Segment'**
  String get quickEntry_multiSegment;

  /// No description provided for @quickEntry_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get quickEntry_clear;

  /// No description provided for @location_saved.
  ///
  /// In en, this message translates to:
  /// **'Location \"{name}\" saved!'**
  String location_saved(String name);

  /// No description provided for @location_saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get location_saveTitle;

  /// No description provided for @location_address.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String location_address(String address);

  /// No description provided for @dev_addSampleData.
  ///
  /// In en, this message translates to:
  /// **'Add Sample Data'**
  String get dev_addSampleData;

  /// No description provided for @dev_addSampleDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Create test entries from the last week'**
  String get dev_addSampleDataDesc;

  /// No description provided for @dev_sampleDataAdded.
  ///
  /// In en, this message translates to:
  /// **'Sample data added successfully'**
  String get dev_sampleDataAdded;

  /// No description provided for @dev_sampleDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add sample data: {error}'**
  String dev_sampleDataFailed(String error);

  /// No description provided for @dev_signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add sample data.'**
  String get dev_signInRequired;

  /// No description provided for @dev_syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing to Supabase...'**
  String get dev_syncing;

  /// No description provided for @dev_syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Sync completed successfully!'**
  String get dev_syncSuccess;

  /// No description provided for @dev_syncFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Sync failed: {error}'**
  String dev_syncFailed(String error);

  /// No description provided for @dev_syncToSupabase.
  ///
  /// In en, this message translates to:
  /// **'Sync to Supabase'**
  String get dev_syncToSupabase;

  /// No description provided for @dev_syncToSupabaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Manually sync local entries to Supabase cloud'**
  String get dev_syncToSupabaseDesc;

  /// No description provided for @settings_languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_languageEnglish;

  /// No description provided for @settings_languageSwedish.
  ///
  /// In en, this message translates to:
  /// **'Svenska'**
  String get settings_languageSwedish;

  /// No description provided for @simpleEntry_validDuration.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid duration'**
  String get simpleEntry_validDuration;

  /// No description provided for @simpleEntry_entrySaved.
  ///
  /// In en, this message translates to:
  /// **'{type} entry {action} successfully! 🎉'**
  String simpleEntry_entrySaved(String type, String action);

  /// No description provided for @account_createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get account_createTitle;

  /// No description provided for @account_createOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Create your account on the web'**
  String get account_createOnWeb;

  /// No description provided for @account_createDescription.
  ///
  /// In en, this message translates to:
  /// **'To create an account, please visit our signup page in your web browser.'**
  String get account_createDescription;

  /// No description provided for @account_openSignupPage.
  ///
  /// In en, this message translates to:
  /// **'Open signup page'**
  String get account_openSignupPage;

  /// No description provided for @account_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account → Login'**
  String get account_alreadyHaveAccount;

  /// No description provided for @history_currentlySelected.
  ///
  /// In en, this message translates to:
  /// **'Currently selected'**
  String get history_currentlySelected;

  /// No description provided for @history_tapToFilter.
  ///
  /// In en, this message translates to:
  /// **'Tap to filter by {label} entries'**
  String history_tapToFilter(String label);

  /// No description provided for @history_holidayWork.
  ///
  /// In en, this message translates to:
  /// **'Holiday work: {name}'**
  String history_holidayWork(String name);

  /// No description provided for @history_redDay.
  ///
  /// In en, this message translates to:
  /// **'Red day'**
  String get history_redDay;

  /// No description provided for @history_noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get history_noDescription;

  /// No description provided for @overview_totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get overview_totalHours;

  /// No description provided for @overview_allActivities.
  ///
  /// In en, this message translates to:
  /// **'All activities'**
  String get overview_allActivities;

  /// No description provided for @overview_totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get overview_totalEntries;

  /// No description provided for @overview_thisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get overview_thisPeriod;

  /// No description provided for @overview_travelTime.
  ///
  /// In en, this message translates to:
  /// **'Travel Time'**
  String get overview_travelTime;

  /// No description provided for @overview_totalCommute.
  ///
  /// In en, this message translates to:
  /// **'Total commute'**
  String get overview_totalCommute;

  /// No description provided for @overview_workTime.
  ///
  /// In en, this message translates to:
  /// **'Work Time'**
  String get overview_workTime;

  /// No description provided for @overview_totalWork.
  ///
  /// In en, this message translates to:
  /// **'Total work'**
  String get overview_totalWork;

  /// No description provided for @overview_quickInsights.
  ///
  /// In en, this message translates to:
  /// **'Quick Insights'**
  String get overview_quickInsights;

  /// No description provided for @overview_activityDistribution.
  ///
  /// In en, this message translates to:
  /// **'Activity Distribution'**
  String get overview_activityDistribution;

  /// No description provided for @overview_recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get overview_recentActivity;

  /// No description provided for @overview_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get overview_viewAll;

  /// No description provided for @overview_noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get overview_noDataAvailable;

  /// No description provided for @overview_errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get overview_errorLoadingData;

  /// No description provided for @overview_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get overview_travel;

  /// No description provided for @overview_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get overview_work;

  /// No description provided for @location_fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get location_fullAddress;

  /// No description provided for @auth_legalRequired.
  ///
  /// In en, this message translates to:
  /// **'Legal Acceptance Required'**
  String get auth_legalRequired;

  /// No description provided for @auth_legalDescription.
  ///
  /// In en, this message translates to:
  /// **'You must accept our Terms of Service and Privacy Policy to continue using the app.'**
  String get auth_legalDescription;

  /// No description provided for @auth_legalVisitSignup.
  ///
  /// In en, this message translates to:
  /// **'Please visit our signup page to complete this step.'**
  String get auth_legalVisitSignup;

  /// No description provided for @entry_logTravelEntry.
  ///
  /// In en, this message translates to:
  /// **'Log Travel Entry'**
  String get entry_logTravelEntry;

  /// No description provided for @entry_logWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'Log Work Entry'**
  String get entry_logWorkEntry;

  /// No description provided for @trends_monthlyComparison.
  ///
  /// In en, this message translates to:
  /// **'Monthly Comparison'**
  String get trends_monthlyComparison;

  /// No description provided for @trends_currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get trends_currentMonth;

  /// No description provided for @trends_previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get trends_previousMonth;

  /// No description provided for @trends_workHours.
  ///
  /// In en, this message translates to:
  /// **'Work Hours'**
  String get trends_workHours;

  /// No description provided for @trends_weeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly Hours'**
  String get trends_weeklyHours;

  /// No description provided for @trends_dailyTrends.
  ///
  /// In en, this message translates to:
  /// **'Daily Trends (Last 7 Days)'**
  String get trends_dailyTrends;

  /// No description provided for @trends_total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get trends_total;

  /// No description provided for @trends_work.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get trends_work;

  /// No description provided for @trends_travel.
  ///
  /// In en, this message translates to:
  /// **'travel'**
  String get trends_travel;

  /// No description provided for @leave_recentLeaves.
  ///
  /// In en, this message translates to:
  /// **'Recent Leaves'**
  String get leave_recentLeaves;

  /// No description provided for @leave_fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get leave_fullDay;

  /// No description provided for @leave_totalLeaveDays.
  ///
  /// In en, this message translates to:
  /// **'Total Leave Days'**
  String get leave_totalLeaveDays;

  /// No description provided for @leave_noLeavesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No leaves recorded'**
  String get leave_noLeavesRecorded;

  /// No description provided for @leave_noLeavesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your leave history will appear here'**
  String get leave_noLeavesDescription;

  /// No description provided for @insight_peakPerformance.
  ///
  /// In en, this message translates to:
  /// **'Peak Performance'**
  String get insight_peakPerformance;

  /// No description provided for @insight_peakPerformanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Your most productive day was {day} with {hours} hours'**
  String insight_peakPerformanceDesc(String day, String hours);

  /// No description provided for @insight_locationInsights.
  ///
  /// In en, this message translates to:
  /// **'Location Insights'**
  String get insight_locationInsights;

  /// No description provided for @insight_locationInsightsDesc.
  ///
  /// In en, this message translates to:
  /// **'{location} is your most frequent location'**
  String insight_locationInsightsDesc(String location);

  /// No description provided for @insight_timeManagement.
  ///
  /// In en, this message translates to:
  /// **'Time Management'**
  String get insight_timeManagement;

  /// No description provided for @insight_timeManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'You worked {hours} hours in this period'**
  String insight_timeManagementDesc(String hours);

  /// No description provided for @profile_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profile_signOut;

  /// No description provided for @form_dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get form_dateTime;

  /// No description provided for @form_travelRoute.
  ///
  /// In en, this message translates to:
  /// **'Travel Route'**
  String get form_travelRoute;

  /// No description provided for @form_workLocation.
  ///
  /// In en, this message translates to:
  /// **'Work Location'**
  String get form_workLocation;

  /// No description provided for @form_workDetails.
  ///
  /// In en, this message translates to:
  /// **'Work Details'**
  String get form_workDetails;

  /// No description provided for @nav_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get nav_history;

  /// No description provided for @balance_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK: {range}'**
  String balance_thisWeek(String range);

  /// No description provided for @balance_hoursWorked.
  ///
  /// In en, this message translates to:
  /// **'Hours Worked (to date): {worked} / {target} h'**
  String balance_hoursWorked(String worked, String target);

  /// No description provided for @balance_over.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get balance_over;

  /// No description provided for @balance_under.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get balance_under;

  /// No description provided for @balance_timeDebt.
  ///
  /// In en, this message translates to:
  /// **'You maintain a time debt'**
  String get balance_timeDebt;

  /// No description provided for @balance_includesOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Includes opening balance ({balance}) as of {date}'**
  String balance_includesOpeningBalance(String balance, String date);

  /// No description provided for @balance_includesOpeningBalanceShort.
  ///
  /// In en, this message translates to:
  /// **'Includes opening balance ({balance})'**
  String balance_includesOpeningBalanceShort(String balance);
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
