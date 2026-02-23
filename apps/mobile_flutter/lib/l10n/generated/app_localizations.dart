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

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get common_optional;

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

  /// No description provided for @settings_dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settings_dailyReminder;

  /// No description provided for @settings_dailyReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder at your chosen time every day'**
  String get settings_dailyReminderDesc;

  /// No description provided for @settings_dailyReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settings_dailyReminderTime;

  /// No description provided for @settings_dailyReminderText.
  ///
  /// In en, this message translates to:
  /// **'Reminder text'**
  String get settings_dailyReminderText;

  /// No description provided for @settings_dailyReminderTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reminder message'**
  String get settings_dailyReminderTextHint;

  /// No description provided for @settings_dailyReminderDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Time to log your hours'**
  String get settings_dailyReminderDefaultText;

  /// No description provided for @settings_dailyReminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required for reminders.'**
  String get settings_dailyReminderPermissionDenied;

  /// No description provided for @settings_reminderSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Reminder setup failed: {error}'**
  String settings_reminderSetupFailed(String error);

  /// No description provided for @settings_crashlyticsTestNonFatalTitle.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics test (non-fatal)'**
  String get settings_crashlyticsTestNonFatalTitle;

  /// No description provided for @settings_crashlyticsTestNonFatalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a non-fatal test event to Firebase'**
  String get settings_crashlyticsTestNonFatalSubtitle;

  /// No description provided for @settings_crashlyticsTestFatalTitle.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics test (fatal crash)'**
  String get settings_crashlyticsTestFatalTitle;

  /// No description provided for @settings_crashlyticsTestFatalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Force app crash to verify Crashlytics'**
  String get settings_crashlyticsTestFatalSubtitle;

  /// No description provided for @settings_crashlyticsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics is disabled for this build.'**
  String get settings_crashlyticsDisabled;

  /// No description provided for @settings_crashlyticsNonFatalSent.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics non-fatal event sent.'**
  String get settings_crashlyticsNonFatalSent;

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

  /// No description provided for @contract_employerMode.
  ///
  /// In en, this message translates to:
  /// **'Employer Mode'**
  String get contract_employerMode;

  /// No description provided for @contract_modeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get contract_modeStandard;

  /// No description provided for @contract_modeStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get contract_modeStrict;

  /// No description provided for @contract_modeFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get contract_modeFlexible;

  /// No description provided for @contract_modeStrictDesc.
  ///
  /// In en, this message translates to:
  /// **'Strict validation of hours'**
  String get contract_modeStrictDesc;

  /// No description provided for @contract_modeFlexibleDesc.
  ///
  /// In en, this message translates to:
  /// **'No warnings for overages'**
  String get contract_modeFlexibleDesc;

  /// No description provided for @contract_modeStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard balance tracking'**
  String get contract_modeStandardDesc;

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
  /// **'Hours Accounted (to date): {worked} / {target} h'**
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

  /// No description provided for @balance_underTarget.
  ///
  /// In en, this message translates to:
  /// **'Under target'**
  String get balance_underTarget;

  /// No description provided for @balance_overTarget.
  ///
  /// In en, this message translates to:
  /// **'Over target'**
  String get balance_overTarget;

  /// No description provided for @balance_yearBalance.
  ///
  /// In en, this message translates to:
  /// **'Year Balance ({year})'**
  String balance_yearBalance(String year);

  /// No description provided for @balance_resetsOn.
  ///
  /// In en, this message translates to:
  /// **'Resets {date}'**
  String balance_resetsOn(String date);

  /// No description provided for @balance_contractBalance.
  ///
  /// In en, this message translates to:
  /// **'Contract balance (since {date})'**
  String balance_contractBalance(String date);

  /// No description provided for @balance_contractBalanceNoDate.
  ///
  /// In en, this message translates to:
  /// **'Contract balance (since start)'**
  String get balance_contractBalanceNoDate;

  /// No description provided for @balance_today_includes_offsets.
  ///
  /// In en, this message translates to:
  /// **'Balance today (includes starting balance + adjustments)'**
  String get balance_today_includes_offsets;

  /// No description provided for @balance_balanceTodayHeadline.
  ///
  /// In en, this message translates to:
  /// **'Balance today'**
  String get balance_balanceTodayHeadline;

  /// No description provided for @balance_balanceTodaySubline.
  ///
  /// In en, this message translates to:
  /// **'Opening {opening} • Adjustments {adjustments} • Year change {yearChange}'**
  String balance_balanceTodaySubline(
      String opening, String adjustments, String yearChange);

  /// No description provided for @balance_adjustments_this_month.
  ///
  /// In en, this message translates to:
  /// **'Adjustments (this month)'**
  String get balance_adjustments_this_month;

  /// No description provided for @balance_adjustments_this_year.
  ///
  /// In en, this message translates to:
  /// **'Adjustments (this year)'**
  String get balance_adjustments_this_year;

  /// No description provided for @balance_recent_adjustments.
  ///
  /// In en, this message translates to:
  /// **'Recent adjustments'**
  String get balance_recent_adjustments;

  /// No description provided for @balance_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get balance_details;

  /// No description provided for @balance_informationalOnly.
  ///
  /// In en, this message translates to:
  /// **'Informational only'**
  String get balance_informationalOnly;

  /// No description provided for @balance_includesOpening.
  ///
  /// In en, this message translates to:
  /// **'Inkluderar ingående saldo ({balance}) per {date}'**
  String balance_includesOpening(String balance, String date);

  /// No description provided for @balance_yearlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Yearly ({year})'**
  String balance_yearlyLabel(int year);

  /// No description provided for @balance_thisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This month: {month}'**
  String balance_thisMonthLabel(String month);

  /// No description provided for @balance_statusToDate.
  ///
  /// In en, this message translates to:
  /// **'Status (to date):'**
  String get balance_statusToDate;

  /// No description provided for @balance_workedToDate.
  ///
  /// In en, this message translates to:
  /// **'Accounted time (to date):'**
  String get balance_workedToDate;

  /// No description provided for @balance_fullMonthTarget.
  ///
  /// In en, this message translates to:
  /// **'Full month target: {hours}h'**
  String balance_fullMonthTarget(String hours);

  /// No description provided for @balance_creditedPaidLeave.
  ///
  /// In en, this message translates to:
  /// **'+ {hours}h credited leave'**
  String balance_creditedPaidLeave(String hours);

  /// No description provided for @balance_manualAdjustments.
  ///
  /// In en, this message translates to:
  /// **'{hours}h manual adjustments'**
  String balance_manualAdjustments(String hours);

  /// No description provided for @balance_percentFullMonthTarget.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of full month target'**
  String balance_percentFullMonthTarget(String percent);

  /// No description provided for @balance_fullYearTarget.
  ///
  /// In en, this message translates to:
  /// **'Full year target: {hours}h'**
  String balance_fullYearTarget(String hours);

  /// No description provided for @balance_includesAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Includes adjustments: {hours}h'**
  String balance_includesAdjustments(String hours);

  /// No description provided for @balance_loggedTime.
  ///
  /// In en, this message translates to:
  /// **'Worked time'**
  String get balance_loggedTime;

  /// No description provided for @balance_creditedLeave.
  ///
  /// In en, this message translates to:
  /// **'Credited leave'**
  String get balance_creditedLeave;

  /// No description provided for @balance_accountedTime.
  ///
  /// In en, this message translates to:
  /// **'Accounted time'**
  String get balance_accountedTime;

  /// No description provided for @balance_plannedTimeSinceBaseline.
  ///
  /// In en, this message translates to:
  /// **'Planned time (since baseline)'**
  String get balance_plannedTimeSinceBaseline;

  /// No description provided for @balance_differenceVsPlan.
  ///
  /// In en, this message translates to:
  /// **'Over/under plan'**
  String get balance_differenceVsPlan;

  /// No description provided for @balance_countingFrom.
  ///
  /// In en, this message translates to:
  /// **'Counting from: {date}'**
  String balance_countingFrom(String date);

  /// No description provided for @balance_planCalculatedFromStart.
  ///
  /// In en, this message translates to:
  /// **'Plan is calculated from start date'**
  String get balance_planCalculatedFromStart;

  /// No description provided for @balance_travelExcluded.
  ///
  /// In en, this message translates to:
  /// **'Travel (excluded by settings)'**
  String get balance_travelExcluded;

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

  /// No description provided for @redDay_currentPersonalDays.
  ///
  /// In en, this message translates to:
  /// **'Current personal red days'**
  String get redDay_currentPersonalDays;

  /// No description provided for @redDay_noPersonalDaysYet.
  ///
  /// In en, this message translates to:
  /// **'No personal red days added yet.'**
  String get redDay_noPersonalDaysYet;

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

  /// No description provided for @leave_unknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown leave type'**
  String get leave_unknownType;

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

  /// No description provided for @travel_legLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel {number}'**
  String travel_legLabel(int number);

  /// No description provided for @travel_addLeg.
  ///
  /// In en, this message translates to:
  /// **'Add Travel Leg'**
  String get travel_addLeg;

  /// No description provided for @travel_addAnotherLeg.
  ///
  /// In en, this message translates to:
  /// **'Add Another Travel'**
  String get travel_addAnotherLeg;

  /// No description provided for @travel_sourceAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get travel_sourceAuto;

  /// No description provided for @travel_sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get travel_sourceManual;

  /// No description provided for @travel_total.
  ///
  /// In en, this message translates to:
  /// **'Total travel'**
  String get travel_total;

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
  /// **'Notes (Optional)'**
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

  /// No description provided for @entry_travelLegUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'First leg updates the existing entry; extra legs become new entries.'**
  String get entry_travelLegUpdateNotice;

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

  /// No description provided for @settings_travelLogging.
  ///
  /// In en, this message translates to:
  /// **'Travel time logging'**
  String get settings_travelLogging;

  /// No description provided for @settings_travelLoggingDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable travel time entry and related stats'**
  String get settings_travelLoggingDesc;

  /// No description provided for @settings_changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settings_changePassword;

  /// No description provided for @settings_changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settings_changePasswordDesc;

  /// No description provided for @settings_changePasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get settings_changePasswordSent;

  /// No description provided for @settings_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settings_contactSupport;

  /// No description provided for @settings_contactSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help or report an issue'**
  String get settings_contactSupportDesc;

  /// No description provided for @settings_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settings_deleteAccount;

  /// No description provided for @settings_deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get settings_deleteAccountDesc;

  /// No description provided for @settings_deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get settings_deleteAccountConfirmTitle;

  /// No description provided for @settings_deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data. This action cannot be undone.'**
  String get settings_deleteAccountConfirmBody;

  /// No description provided for @settings_deleteAccountConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get settings_deleteAccountConfirmHint;

  /// No description provided for @settings_deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get settings_deleteAccountSuccess;

  /// No description provided for @settings_deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String settings_deleteAccountError(String error);

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

  /// No description provided for @common_noDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get common_noDataToExport;

  /// No description provided for @common_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get common_exportSuccess;

  /// No description provided for @common_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get common_exportFailed;

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

  /// No description provided for @home_timeBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance today'**
  String get home_timeBalanceTitle;

  /// No description provided for @home_balanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incl. opening + adjustments'**
  String get home_balanceSubtitle;

  /// No description provided for @home_changeVsPlan.
  ///
  /// In en, this message translates to:
  /// **'Over/under plan'**
  String get home_changeVsPlan;

  /// No description provided for @home_loggedTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged time'**
  String get home_loggedTimeTitle;

  /// No description provided for @home_seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more →'**
  String get home_seeMore;

  /// No description provided for @home_sinceStart.
  ///
  /// In en, this message translates to:
  /// **'since start'**
  String get home_sinceStart;

  /// No description provided for @home_monthProgress.
  ///
  /// In en, this message translates to:
  /// **'{month}: {worked} / {planned}  {delta}'**
  String home_monthProgress(
      String month, String worked, String planned, String delta);

  /// No description provided for @home_monthProgressNoTarget.
  ///
  /// In en, this message translates to:
  /// **'{month} ({since}): {worked}'**
  String home_monthProgressNoTarget(String month, String since, String worked);

  /// No description provided for @home_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get home_thisYear;

  /// No description provided for @home_thisYearSinceStart.
  ///
  /// In en, this message translates to:
  /// **'This year (since start)'**
  String get home_thisYearSinceStart;

  /// No description provided for @home_backfillWarning.
  ///
  /// In en, this message translates to:
  /// **'You have entries before your start date. Balance is calculated from the start date.'**
  String get home_backfillWarning;

  /// No description provided for @home_backfillChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get home_backfillChange;

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

  /// No description provided for @entry_saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get entry_saveChanges;

  /// No description provided for @entry_calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get entry_calculate;

  /// No description provided for @entry_logTravel.
  ///
  /// In en, this message translates to:
  /// **'Log Travel'**
  String get entry_logTravel;

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

  /// No description provided for @error_invalidHours.
  ///
  /// In en, this message translates to:
  /// **'Hours must be a non-negative number'**
  String get error_invalidHours;

  /// No description provided for @error_invalidMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes must be between 0 and 59'**
  String get error_invalidMinutes;

  /// No description provided for @error_durationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid duration (greater than 0)'**
  String get error_durationRequired;

  /// No description provided for @error_endTimeBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get error_endTimeBeforeStart;

  /// No description provided for @error_invalidShiftTime.
  ///
  /// In en, this message translates to:
  /// **'Shift {number} has invalid times (end must be after start)'**
  String error_invalidShiftTime(int number);

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

  /// No description provided for @form_unpaidBreakMinutes.
  ///
  /// In en, this message translates to:
  /// **'Unpaid break (min)'**
  String get form_unpaidBreakMinutes;

  /// No description provided for @form_shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift {number}'**
  String form_shiftLabel(int number);

  /// No description provided for @form_span.
  ///
  /// In en, this message translates to:
  /// **'Span'**
  String get form_span;

  /// No description provided for @form_break.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get form_break;

  /// No description provided for @form_worked.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get form_worked;

  /// No description provided for @form_useLocationForAllShifts.
  ///
  /// In en, this message translates to:
  /// **'Use this location for all shifts'**
  String get form_useLocationForAllShifts;

  /// No description provided for @form_shiftLocation.
  ///
  /// In en, this message translates to:
  /// **'Shift location'**
  String get form_shiftLocation;

  /// No description provided for @form_shiftNotes.
  ///
  /// In en, this message translates to:
  /// **'Shift notes'**
  String get form_shiftNotes;

  /// No description provided for @form_shiftNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes for this shift (e.g., specific tasks, issues)'**
  String get form_shiftNotesHint;

  /// No description provided for @form_sameAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Same as default'**
  String get form_sameAsDefault;

  /// No description provided for @form_dayNotes.
  ///
  /// In en, this message translates to:
  /// **'Day notes'**
  String get form_dayNotes;

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

  /// No description provided for @profile_labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_labelName;

  /// No description provided for @profile_labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_labelEmail;

  /// No description provided for @profile_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profile_memberSince;

  /// No description provided for @profile_totalHoursLogged.
  ///
  /// In en, this message translates to:
  /// **'Total hours logged'**
  String get profile_totalHoursLogged;

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

  /// No description provided for @auth_signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get auth_signInPrompt;

  /// No description provided for @auth_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_emailLabel;

  /// No description provided for @auth_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_passwordLabel;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_signInButton;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_noAccount;

  /// No description provided for @auth_signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signUpLink;

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

  /// No description provided for @editMode_singleEntryInfo_work.
  ///
  /// In en, this message translates to:
  /// **'Editing one entry. To add another shift for this date, create a new entry.'**
  String get editMode_singleEntryInfo_work;

  /// No description provided for @editMode_singleEntryInfo_travel.
  ///
  /// In en, this message translates to:
  /// **'Editing one entry. To add another travel leg for this date, create a new entry.'**
  String get editMode_singleEntryInfo_travel;

  /// No description provided for @editMode_addNewEntryForDate.
  ///
  /// In en, this message translates to:
  /// **'Add new entry for this date'**
  String get editMode_addNewEntryForDate;

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

  /// No description provided for @history_title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history_title;

  /// No description provided for @history_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get history_travel;

  /// No description provided for @history_worked.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get history_worked;

  /// No description provided for @history_totalWorked.
  ///
  /// In en, this message translates to:
  /// **'Total worked'**
  String get history_totalWorked;

  /// No description provided for @history_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get history_work;

  /// No description provided for @history_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get history_all;

  /// No description provided for @history_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get history_yesterday;

  /// No description provided for @history_last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get history_last7Days;

  /// No description provided for @history_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get history_custom;

  /// No description provided for @history_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by location, notes...'**
  String get history_searchHint;

  /// No description provided for @history_loadingEntries.
  ///
  /// In en, this message translates to:
  /// **'Loading entries...'**
  String get history_loadingEntries;

  /// No description provided for @history_noEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No entries found'**
  String get history_noEntriesFound;

  /// No description provided for @history_tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search terms'**
  String get history_tryAdjustingFilters;

  /// No description provided for @history_holidayWorkBadge.
  ///
  /// In en, this message translates to:
  /// **'Holiday Work'**
  String get history_holidayWorkBadge;

  /// No description provided for @history_autoBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get history_autoBadge;

  /// No description provided for @history_autoMarked.
  ///
  /// In en, this message translates to:
  /// **'Auto-marked: {name}'**
  String history_autoMarked(String name);

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

  /// No description provided for @overview_trackedWork.
  ///
  /// In en, this message translates to:
  /// **'Tracked work'**
  String get overview_trackedWork;

  /// No description provided for @overview_trackedTravel.
  ///
  /// In en, this message translates to:
  /// **'Tracked travel'**
  String get overview_trackedTravel;

  /// No description provided for @overview_totalLoggedTime.
  ///
  /// In en, this message translates to:
  /// **'Total logged time'**
  String get overview_totalLoggedTime;

  /// No description provided for @overview_workPlusTravel.
  ///
  /// In en, this message translates to:
  /// **'Work + travel'**
  String get overview_workPlusTravel;

  /// No description provided for @overview_creditedLeave.
  ///
  /// In en, this message translates to:
  /// **'Credited leave'**
  String get overview_creditedLeave;

  /// No description provided for @overview_accountedTime.
  ///
  /// In en, this message translates to:
  /// **'Accounted time'**
  String get overview_accountedTime;

  /// No description provided for @overview_loggedPlusCreditedLeave.
  ///
  /// In en, this message translates to:
  /// **'Logged + credited leave'**
  String get overview_loggedPlusCreditedLeave;

  /// No description provided for @overview_plannedTime.
  ///
  /// In en, this message translates to:
  /// **'Planned time'**
  String get overview_plannedTime;

  /// No description provided for @overview_scheduledTarget.
  ///
  /// In en, this message translates to:
  /// **'Scheduled target'**
  String get overview_scheduledTarget;

  /// No description provided for @overview_differenceVsPlan.
  ///
  /// In en, this message translates to:
  /// **'Over/under plan'**
  String get overview_differenceVsPlan;

  /// No description provided for @overview_accountedMinusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Accounted - planned'**
  String get overview_accountedMinusPlanned;

  /// No description provided for @overview_balanceAfterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Balance at end of period'**
  String get overview_balanceAfterPeriod;

  /// No description provided for @overview_startPlusAdjPlusDiff.
  ///
  /// In en, this message translates to:
  /// **'Start + adjustments + change'**
  String get overview_startPlusAdjPlusDiff;

  /// No description provided for @overview_endBalanceFormula.
  ///
  /// In en, this message translates to:
  /// **'End balance = Start balance + Adjustments in period + Over/under plan'**
  String get overview_endBalanceFormula;

  /// No description provided for @balance_accountedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logged time + credited leave'**
  String get balance_accountedTooltip;

  /// No description provided for @location_fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get location_fullAddress;

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
  /// **'Hours Accounted (to date): {worked} / {target} h'**
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
  /// **'Under target'**
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

  /// Label shown when tracking started after the period start
  ///
  /// In en, this message translates to:
  /// **'Logged since {date}'**
  String balance_loggedSince(String date);

  /// Label showing the starting balance as of the tracking start date
  ///
  /// In en, this message translates to:
  /// **'Starting balance ({date}): {value}'**
  String balance_startingBalanceAsOf(String date, String value);

  /// Header for the primary balance display (includes starting balance)
  ///
  /// In en, this message translates to:
  /// **'BALANCE TODAY'**
  String get balance_balanceToday;

  /// Secondary line showing year-only balance from logged hours
  ///
  /// In en, this message translates to:
  /// **'Net this year (logged): {value}'**
  String balance_netThisYear(String value);

  /// Short label for net this year in breakdown
  ///
  /// In en, this message translates to:
  /// **'Net this year'**
  String get balance_netThisYearLabel;

  /// Line showing the starting balance value
  ///
  /// In en, this message translates to:
  /// **'Starting balance: {value}'**
  String balance_startingBalanceValue(String value);

  /// Short label for starting balance
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get balance_startingBalance;

  /// Header for the balance breakdown section
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get balance_breakdown;

  /// Label for manual adjustments in breakdown
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get balance_adjustments;

  /// No description provided for @balance_fullMonthTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Full month target: {value}'**
  String balance_fullMonthTargetValue(String value);

  /// No description provided for @balance_creditedPaidLeaveValue.
  ///
  /// In en, this message translates to:
  /// **'+ {value} credited leave'**
  String balance_creditedPaidLeaveValue(String value);

  /// No description provided for @balance_manualAdjustmentsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} manual adjustments'**
  String balance_manualAdjustmentsValue(String value);

  /// No description provided for @balance_fullYearTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Full year target: {value}'**
  String balance_fullYearTargetValue(String value);

  /// No description provided for @balance_creditedHoursValue.
  ///
  /// In en, this message translates to:
  /// **'Credited Hours: {value}'**
  String balance_creditedHoursValue(String value);

  /// No description provided for @balance_includesAdjustmentsValue.
  ///
  /// In en, this message translates to:
  /// **'Includes adjustments: {value}'**
  String balance_includesAdjustmentsValue(String value);

  /// No description provided for @locations_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get locations_errorLoading;

  /// No description provided for @locations_distribution.
  ///
  /// In en, this message translates to:
  /// **'Location Distribution'**
  String get locations_distribution;

  /// No description provided for @locations_details.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locations_details;

  /// No description provided for @locations_noData.
  ///
  /// In en, this message translates to:
  /// **'No location data'**
  String get locations_noData;

  /// No description provided for @locations_noDataDescription.
  ///
  /// In en, this message translates to:
  /// **'No entries found for the selected period'**
  String get locations_noDataDescription;

  /// No description provided for @locations_noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No location data available'**
  String get locations_noDataAvailable;

  /// No description provided for @locations_totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get locations_totalHours;

  /// No description provided for @locations_entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get locations_entries;

  /// No description provided for @locations_workTime.
  ///
  /// In en, this message translates to:
  /// **'Work Time'**
  String get locations_workTime;

  /// No description provided for @locations_travelTime.
  ///
  /// In en, this message translates to:
  /// **'Travel Time'**
  String get locations_travelTime;

  /// No description provided for @chart_timeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Time Distribution'**
  String get chart_timeDistribution;

  /// No description provided for @chart_workTime.
  ///
  /// In en, this message translates to:
  /// **'Work Time'**
  String get chart_workTime;

  /// No description provided for @chart_travelTime.
  ///
  /// In en, this message translates to:
  /// **'Travel Time'**
  String get chart_travelTime;

  /// No description provided for @chart_totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get chart_totalTime;

  /// No description provided for @chart_noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get chart_noDataAvailable;

  /// No description provided for @chart_startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your time to see statistics'**
  String get chart_startTracking;

  /// No description provided for @chart_allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get chart_allTime;

  /// No description provided for @chart_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chart_today;

  /// No description provided for @balance_todaysBalance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Balance'**
  String get balance_todaysBalance;

  /// No description provided for @balance_workVsTravel.
  ///
  /// In en, this message translates to:
  /// **'Work vs Travel'**
  String get balance_workVsTravel;

  /// No description provided for @balance_balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balance_balanced;

  /// No description provided for @balance_unbalanced.
  ///
  /// In en, this message translates to:
  /// **'Unbalanced'**
  String get balance_unbalanced;

  /// No description provided for @balance_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get balance_work;

  /// No description provided for @balance_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get balance_travel;

  /// No description provided for @balance_entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get balance_entries;

  /// No description provided for @settings_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_darkMode;

  /// No description provided for @settings_darkModeActive.
  ///
  /// In en, this message translates to:
  /// **'Dark theme is active'**
  String get settings_darkModeActive;

  /// No description provided for @settings_switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get settings_switchToDark;

  /// No description provided for @settings_darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get settings_darkModeEnabled;

  /// No description provided for @settings_lightModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Light mode enabled'**
  String get settings_lightModeEnabled;

  /// No description provided for @entry_endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get entry_endTime;

  /// No description provided for @entry_fromHint.
  ///
  /// In en, this message translates to:
  /// **'Enter departure location'**
  String get entry_fromHint;

  /// No description provided for @entry_toHint.
  ///
  /// In en, this message translates to:
  /// **'Enter arrival location'**
  String get entry_toHint;

  /// No description provided for @entry_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get entry_location;

  /// No description provided for @entry_locationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter work location'**
  String get entry_locationHint;

  /// No description provided for @entry_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get entry_hours;

  /// No description provided for @entry_minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get entry_minutes;

  /// No description provided for @entry_shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get entry_shift;

  /// No description provided for @entry_notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional details...'**
  String get entry_notesHint;

  /// No description provided for @entry_calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get entry_calculating;

  /// No description provided for @entry_calculateTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Calculate Travel Time'**
  String get entry_calculateTravelTime;

  /// No description provided for @entry_travelTimeCalculated.
  ///
  /// In en, this message translates to:
  /// **'Travel time calculated: {duration} ({distance})'**
  String entry_travelTimeCalculated(String duration, String distance);

  /// No description provided for @entry_total.
  ///
  /// In en, this message translates to:
  /// **'Total: {duration}'**
  String entry_total(String duration);

  /// No description provided for @entry_publicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday'**
  String get entry_publicHoliday;

  /// No description provided for @entry_publicHolidaySweden.
  ///
  /// In en, this message translates to:
  /// **'Public holiday in Sweden'**
  String get entry_publicHolidaySweden;

  /// No description provided for @entry_redDayWarning.
  ///
  /// In en, this message translates to:
  /// **'Red day. Hours entered here may count as holiday work.'**
  String get entry_redDayWarning;

  /// No description provided for @entry_personalRedDay.
  ///
  /// In en, this message translates to:
  /// **'Personal red day'**
  String get entry_personalRedDay;

  /// No description provided for @error_addAtLeastOneShift.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one shift.'**
  String get error_addAtLeastOneShift;

  /// No description provided for @shift_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning Shift'**
  String get shift_morning;

  /// No description provided for @shift_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon Shift'**
  String get shift_afternoon;

  /// No description provided for @shift_evening.
  ///
  /// In en, this message translates to:
  /// **'Evening Shift'**
  String get shift_evening;

  /// No description provided for @shift_night.
  ///
  /// In en, this message translates to:
  /// **'Night Shift'**
  String get shift_night;

  /// No description provided for @shift_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Shift'**
  String get shift_unknown;

  /// No description provided for @simpleEntry_fromLocation.
  ///
  /// In en, this message translates to:
  /// **'From Location'**
  String get simpleEntry_fromLocation;

  /// No description provided for @simpleEntry_toLocation.
  ///
  /// In en, this message translates to:
  /// **'To Location'**
  String get simpleEntry_toLocation;

  /// No description provided for @simpleEntry_pleaseEnterDeparture.
  ///
  /// In en, this message translates to:
  /// **'Please enter departure location'**
  String get simpleEntry_pleaseEnterDeparture;

  /// No description provided for @simpleEntry_pleaseEnterArrival.
  ///
  /// In en, this message translates to:
  /// **'Please enter arrival location'**
  String get simpleEntry_pleaseEnterArrival;

  /// No description provided for @quickEntry_editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get quickEntry_editEntry;

  /// No description provided for @quickEntry_quickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get quickEntry_quickEntry;

  /// No description provided for @quickEntry_travelTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Travel Time (minutes)'**
  String get quickEntry_travelTimeMinutes;

  /// No description provided for @quickEntry_travelTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 45'**
  String get quickEntry_travelTimeHint;

  /// No description provided for @quickEntry_additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info (Optional)'**
  String get quickEntry_additionalInfo;

  /// No description provided for @quickEntry_additionalInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Notes, delays, etc.'**
  String get quickEntry_additionalInfoHint;

  /// No description provided for @quickEntry_updateEntry.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get quickEntry_updateEntry;

  /// No description provided for @quickEntry_addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get quickEntry_addEntry;

  /// No description provided for @quickEntry_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get quickEntry_saving;

  /// No description provided for @multiSegment_editJourney.
  ///
  /// In en, this message translates to:
  /// **'Edit Multi-Segment Journey'**
  String get multiSegment_editJourney;

  /// No description provided for @multiSegment_journey.
  ///
  /// In en, this message translates to:
  /// **'Multi-Segment Journey'**
  String get multiSegment_journey;

  /// No description provided for @multiSegment_journeySegments.
  ///
  /// In en, this message translates to:
  /// **'Journey Segments'**
  String get multiSegment_journeySegments;

  /// No description provided for @multiSegment_firstSegment.
  ///
  /// In en, this message translates to:
  /// **'First Segment'**
  String get multiSegment_firstSegment;

  /// No description provided for @multiSegment_addNextSegment.
  ///
  /// In en, this message translates to:
  /// **'Add Next Segment'**
  String get multiSegment_addNextSegment;

  /// No description provided for @multiSegment_travelTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Travel Time (minutes)'**
  String get multiSegment_travelTimeMinutes;

  /// No description provided for @multiSegment_travelTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 20'**
  String get multiSegment_travelTimeHint;

  /// No description provided for @multiSegment_addFirstSegment.
  ///
  /// In en, this message translates to:
  /// **'Add First Segment'**
  String get multiSegment_addFirstSegment;

  /// No description provided for @multiSegment_saveJourney.
  ///
  /// In en, this message translates to:
  /// **'Save Journey'**
  String get multiSegment_saveJourney;

  /// No description provided for @multiSegment_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get multiSegment_saving;

  /// No description provided for @multiSegment_pleaseEnterDeparture.
  ///
  /// In en, this message translates to:
  /// **'Please enter departure location'**
  String get multiSegment_pleaseEnterDeparture;

  /// No description provided for @multiSegment_pleaseEnterArrival.
  ///
  /// In en, this message translates to:
  /// **'Please enter arrival location'**
  String get multiSegment_pleaseEnterArrival;

  /// No description provided for @multiSegment_pleaseEnterTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter travel time'**
  String get multiSegment_pleaseEnterTravelTime;

  /// No description provided for @entryDetail_workSession.
  ///
  /// In en, this message translates to:
  /// **'Work Session'**
  String get entryDetail_workSession;

  /// No description provided for @dateRange_quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get dateRange_quickSelect;

  /// No description provided for @dateRange_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateRange_yesterday;

  /// No description provided for @dateRange_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get dateRange_thisWeek;

  /// No description provided for @dateRange_lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get dateRange_lastWeek;

  /// No description provided for @home_workSession.
  ///
  /// In en, this message translates to:
  /// **'Work Session'**
  String get home_workSession;

  /// No description provided for @home_paidLeave.
  ///
  /// In en, this message translates to:
  /// **'Credited Leave'**
  String get home_paidLeave;

  /// No description provided for @home_sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get home_sickLeave;

  /// No description provided for @home_vab.
  ///
  /// In en, this message translates to:
  /// **'VAB (Child Care)'**
  String get home_vab;

  /// No description provided for @home_unpaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Leave'**
  String get home_unpaidLeave;

  /// No description provided for @home_logTravelEntry.
  ///
  /// In en, this message translates to:
  /// **'Log Travel Entry'**
  String get home_logTravelEntry;

  /// No description provided for @home_tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get home_tripDetails;

  /// No description provided for @home_addAnotherTrip.
  ///
  /// In en, this message translates to:
  /// **'Add Another Trip'**
  String get home_addAnotherTrip;

  /// No description provided for @home_totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get home_totalDuration;

  /// No description provided for @home_logWorkEntry.
  ///
  /// In en, this message translates to:
  /// **'Log Work Entry'**
  String get home_logWorkEntry;

  /// No description provided for @home_workShifts.
  ///
  /// In en, this message translates to:
  /// **'Work Shifts'**
  String get home_workShifts;

  /// No description provided for @home_addAnotherShift.
  ///
  /// In en, this message translates to:
  /// **'Add Another Shift'**
  String get home_addAnotherShift;

  /// No description provided for @home_startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get home_startTime;

  /// No description provided for @home_endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get home_endTime;

  /// No description provided for @home_logEntry.
  ///
  /// In en, this message translates to:
  /// **'Log Entry'**
  String get home_logEntry;

  /// No description provided for @home_selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get home_selectTime;

  /// No description provided for @home_timeExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9:00 AM'**
  String get home_timeExample;

  /// No description provided for @home_noRemarks.
  ///
  /// In en, this message translates to:
  /// **'No remarks'**
  String get home_noRemarks;

  /// No description provided for @home_targetToDateZero.
  ///
  /// In en, this message translates to:
  /// **'Target to date: {hours}h (weekend/red day)'**
  String home_targetToDateZero(String hours);

  /// No description provided for @home_loggedHours.
  ///
  /// In en, this message translates to:
  /// **'Logged: {hours}h'**
  String home_loggedHours(String hours);

  /// No description provided for @common_swapLocations.
  ///
  /// In en, this message translates to:
  /// **'Swap locations'**
  String get common_swapLocations;

  /// No description provided for @form_departureLocation.
  ///
  /// In en, this message translates to:
  /// **'Departure location'**
  String get form_departureLocation;

  /// No description provided for @form_arrivalLocation.
  ///
  /// In en, this message translates to:
  /// **'Arrival location'**
  String get form_arrivalLocation;

  /// No description provided for @form_additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get form_additionalInformation;

  /// No description provided for @form_pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get form_pleaseSelectDate;

  /// No description provided for @dateRange_last90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get dateRange_last90Days;

  /// No description provided for @form_shiftLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter shift location'**
  String get form_shiftLocationHint;

  /// No description provided for @error_negativeBreakMinutes.
  ///
  /// In en, this message translates to:
  /// **'Shift {number}: Break minutes cannot be negative'**
  String error_negativeBreakMinutes(Object number);

  /// No description provided for @error_breakExceedsSpan.
  ///
  /// In en, this message translates to:
  /// **'Shift {number}: Break minutes ({breakMinutes}) cannot exceed span ({spanMinutes}m)'**
  String error_breakExceedsSpan(
      Object number, Object breakMinutes, Object spanMinutes);

  /// No description provided for @home_trackWorkShifts.
  ///
  /// In en, this message translates to:
  /// **'Track your work shifts'**
  String get home_trackWorkShifts;

  /// No description provided for @travel_removeLeg.
  ///
  /// In en, this message translates to:
  /// **'Remove travel leg'**
  String get travel_removeLeg;

  /// No description provided for @error_addAtLeastOneTravelLeg.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one travel leg'**
  String get error_addAtLeastOneTravelLeg;

  /// No description provided for @error_selectTravelLocations.
  ///
  /// In en, this message translates to:
  /// **'Travel {number}: Please select both from and to locations'**
  String error_selectTravelLocations(Object number);

  /// No description provided for @error_invalidTravelDuration.
  ///
  /// In en, this message translates to:
  /// **'Travel {number}: Please enter a valid duration (greater than 0)'**
  String error_invalidTravelDuration(Object number);

  /// No description provided for @travel_notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add details about your travel...'**
  String get travel_notesHint;

  /// No description provided for @common_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get common_user;

  /// No description provided for @settings_timeBalanceTracking.
  ///
  /// In en, this message translates to:
  /// **'Time balance tracking'**
  String get settings_timeBalanceTracking;

  /// No description provided for @settings_timeBalanceTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn off if you only want to log hours without comparing against a target.'**
  String get settings_timeBalanceTrackingDesc;

  /// No description provided for @leave_daysDecimal.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String leave_daysDecimal(String days);

  /// No description provided for @trends_errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading trends data'**
  String get trends_errorLoadingData;

  /// No description provided for @trends_tryRefreshingPage.
  ///
  /// In en, this message translates to:
  /// **'Please try refreshing the page'**
  String get trends_tryRefreshingPage;

  /// No description provided for @trends_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get trends_target;

  /// No description provided for @trends_noHoursDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hours data available'**
  String get trends_noHoursDataAvailable;

  /// No description provided for @network_offlinePending.
  ///
  /// In en, this message translates to:
  /// **'Offline - {count} changes pending'**
  String network_offlinePending(int count);

  /// No description provided for @network_youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get network_youAreOffline;

  /// No description provided for @network_syncingChanges.
  ///
  /// In en, this message translates to:
  /// **'Syncing changes...'**
  String get network_syncingChanges;

  /// No description provided for @network_readyToSync.
  ///
  /// In en, this message translates to:
  /// **'{count} changes ready to sync'**
  String network_readyToSync(int count);

  /// No description provided for @network_syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get network_syncNow;

  /// No description provided for @network_offlineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get network_offlineTooltip;

  /// No description provided for @network_pendingTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String network_pendingTooltip(int count);

  /// No description provided for @network_offlineSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Changes will sync when connected.'**
  String get network_offlineSnackbar;

  /// No description provided for @network_backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get network_backOnline;

  /// No description provided for @network_syncedChanges.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} changes'**
  String network_syncedChanges(int count);

  /// No description provided for @network_syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String network_syncFailed(String error);

  /// No description provided for @network_networkErrorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get network_networkErrorTryAgain;

  /// No description provided for @paywall_notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get paywall_notAuthenticated;

  /// No description provided for @paywall_title.
  ///
  /// In en, this message translates to:
  /// **'KvikTime Premium'**
  String get paywall_title;

  /// No description provided for @paywall_unlockAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock all KvikTime features'**
  String get paywall_unlockAllFeatures;

  /// No description provided for @paywall_subscribeWithGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Subscribe with Google Play Billing to continue.'**
  String get paywall_subscribeWithGooglePlay;

  /// No description provided for @paywall_featureFullHistoryReports.
  ///
  /// In en, this message translates to:
  /// **'Full history & reports'**
  String get paywall_featureFullHistoryReports;

  /// No description provided for @paywall_featureCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync across devices'**
  String get paywall_featureCloudSync;

  /// No description provided for @paywall_featureSecureSubscription.
  ///
  /// In en, this message translates to:
  /// **'Secure subscription state'**
  String get paywall_featureSecureSubscription;

  /// No description provided for @paywall_currentEntitlement.
  ///
  /// In en, this message translates to:
  /// **'Current entitlement: {status}'**
  String paywall_currentEntitlement(String status);

  /// No description provided for @paywall_subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription unavailable'**
  String get paywall_subscriptionUnavailable;

  /// No description provided for @paywall_subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe {price}'**
  String paywall_subscribe(String price);

  /// No description provided for @paywall_restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get paywall_restorePurchase;

  /// No description provided for @paywall_manageSubscriptionGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription in Google Play'**
  String get paywall_manageSubscriptionGooglePlay;

  /// No description provided for @paywall_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get paywall_signOut;

  /// No description provided for @location_addNewLocation.
  ///
  /// In en, this message translates to:
  /// **'Add New Location'**
  String get location_addNewLocation;

  /// No description provided for @location_saveFrequentPlace.
  ///
  /// In en, this message translates to:
  /// **'Save a place you visit frequently'**
  String get location_saveFrequentPlace;

  /// No description provided for @location_details.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get location_details;

  /// No description provided for @location_name.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get location_name;

  /// No description provided for @location_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Office, Home, Client Site'**
  String get location_nameHint;

  /// No description provided for @location_nameShortHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Home, Office, Gym'**
  String get location_nameShortHint;

  /// No description provided for @location_enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location name'**
  String get location_enterName;

  /// No description provided for @location_enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get location_enterAddress;

  /// No description provided for @location_addedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location added successfully'**
  String get location_addedSuccessfully;

  /// No description provided for @location_kpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get location_kpiTotal;

  /// No description provided for @location_kpiFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get location_kpiFavorites;

  /// No description provided for @location_kpiTotalUses.
  ///
  /// In en, this message translates to:
  /// **'Total Uses'**
  String get location_kpiTotalUses;

  /// No description provided for @location_searchLocations.
  ///
  /// In en, this message translates to:
  /// **'Search locations...'**
  String get location_searchLocations;

  /// No description provided for @location_noLocationsYet.
  ///
  /// In en, this message translates to:
  /// **'No locations yet'**
  String get location_noLocationsYet;

  /// No description provided for @location_trySearchOrAdd.
  ///
  /// In en, this message translates to:
  /// **'Try searching or adding a new location'**
  String get location_trySearchOrAdd;

  /// No description provided for @location_noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get location_noMatchesFound;

  /// No description provided for @location_tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get location_tryDifferentSearch;

  /// No description provided for @location_noSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No saved locations yet'**
  String get location_noSavedYet;

  /// No description provided for @location_addFirstToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add your first location to get started'**
  String get location_addFirstToGetStarted;

  /// No description provided for @location_removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get location_removeFromFavorites;

  /// No description provided for @location_addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get location_addToFavorites;

  /// No description provided for @location_savedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved Locations'**
  String get location_savedLocations;

  /// No description provided for @location_addressSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Address Suggestions'**
  String get location_addressSuggestions;

  /// No description provided for @location_searchingAddresses.
  ///
  /// In en, this message translates to:
  /// **'Searching addresses...'**
  String get location_searchingAddresses;

  /// No description provided for @location_recentAddresses.
  ///
  /// In en, this message translates to:
  /// **'Recent Addresses'**
  String get location_recentAddresses;

  /// No description provided for @location_startTypingToAdd.
  ///
  /// In en, this message translates to:
  /// **'Start typing to add a new location'**
  String get location_startTypingToAdd;

  /// No description provided for @location_recentLocations.
  ///
  /// In en, this message translates to:
  /// **'Recent Locations'**
  String get location_recentLocations;

  /// No description provided for @location_saveAsNew.
  ///
  /// In en, this message translates to:
  /// **'Save \"{address}\" as new location'**
  String location_saveAsNew(String address);

  /// No description provided for @location_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get location_favorites;

  /// No description provided for @location_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get location_recent;

  /// No description provided for @edit_durationAutofilledFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Duration auto-filled from history ({minutes} min)'**
  String edit_durationAutofilledFromHistory(int minutes);

  /// No description provided for @edit_quickDuration.
  ///
  /// In en, this message translates to:
  /// **'Quick Duration'**
  String get edit_quickDuration;

  /// No description provided for @edit_copyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Copy Yesterday'**
  String get edit_copyYesterday;

  /// No description provided for @edit_noWorkEntryYesterday.
  ///
  /// In en, this message translates to:
  /// **'No work entry found for yesterday'**
  String get edit_noWorkEntryYesterday;

  /// No description provided for @edit_copiedYesterdayShiftTimes.
  ///
  /// In en, this message translates to:
  /// **'Copied yesterday\'s shift times'**
  String get edit_copiedYesterdayShiftTimes;

  /// No description provided for @edit_swapFromTo.
  ///
  /// In en, this message translates to:
  /// **'Swap From/To'**
  String get edit_swapFromTo;

  /// No description provided for @home_trackJourneyDetails.
  ///
  /// In en, this message translates to:
  /// **'Track your journey details'**
  String get home_trackJourneyDetails;

  /// No description provided for @home_entryWillBeLoggedFor.
  ///
  /// In en, this message translates to:
  /// **'Entry will be logged for {date}'**
  String home_entryWillBeLoggedFor(String date);

  /// No description provided for @home_travelEntryLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Travel entry logged successfully!'**
  String get home_travelEntryLoggedSuccess;

  /// No description provided for @home_workEntriesLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work entries logged successfully!'**
  String get home_workEntriesLoggedSuccess;

  /// No description provided for @home_workEntryLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work entry logged successfully!'**
  String get home_workEntryLoggedSuccess;

  /// No description provided for @nav_navigateAwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate Away?'**
  String get nav_navigateAwayTitle;

  /// No description provided for @nav_leavePageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this page?'**
  String get nav_leavePageConfirm;

  /// No description provided for @nav_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get nav_continue;

  /// No description provided for @nav_travelEntries.
  ///
  /// In en, this message translates to:
  /// **'Travel Entries'**
  String get nav_travelEntries;

  /// No description provided for @nav_locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get nav_locations;

  /// No description provided for @nav_analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get nav_analyticsDashboard;

  /// No description provided for @nav_adminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin Only'**
  String get nav_adminOnly;

  /// No description provided for @location_enterNameAndAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter both name and address.'**
  String get location_enterNameAndAddress;

  /// No description provided for @location_deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location deleted!'**
  String get location_deletedSuccessfully;

  /// No description provided for @analytics_accessDeniedAdminRequired.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Admin privileges required.'**
  String get analytics_accessDeniedAdminRequired;

  /// No description provided for @analytics_accessDeniedRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Redirecting...'**
  String get analytics_accessDeniedRedirecting;

  /// No description provided for @analytics_dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analytics_dashboardTitle;

  /// No description provided for @analytics_adminBadge.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get analytics_adminBadge;

  /// No description provided for @analytics_errorLoadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard'**
  String get analytics_errorLoadingDashboard;

  /// No description provided for @analytics_noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get analytics_noDataAvailable;

  /// No description provided for @analytics_kpiSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Performance Indicators'**
  String get analytics_kpiSectionTitle;

  /// No description provided for @analytics_kpiTotalHoursWeek.
  ///
  /// In en, this message translates to:
  /// **'Total Hours (This Week)'**
  String get analytics_kpiTotalHoursWeek;

  /// No description provided for @analytics_kpiActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get analytics_kpiActiveUsers;

  /// No description provided for @analytics_kpiOvertimeBalance.
  ///
  /// In en, this message translates to:
  /// **'Overtime Balance'**
  String get analytics_kpiOvertimeBalance;

  /// No description provided for @analytics_kpiAvgDailyHours.
  ///
  /// In en, this message translates to:
  /// **'Avg Daily Hours'**
  String get analytics_kpiAvgDailyHours;

  /// No description provided for @analytics_chartsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Charts & Trends'**
  String get analytics_chartsSectionTitle;

  /// No description provided for @analytics_dailyTrends7d.
  ///
  /// In en, this message translates to:
  /// **'7-Day Daily Trends'**
  String get analytics_dailyTrends7d;

  /// No description provided for @analytics_userDistribution.
  ///
  /// In en, this message translates to:
  /// **'User Distribution'**
  String get analytics_userDistribution;

  /// No description provided for @adminUsers_title.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get adminUsers_title;

  /// No description provided for @adminUsers_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get adminUsers_searchHint;

  /// No description provided for @adminUsers_filterByRole.
  ///
  /// In en, this message translates to:
  /// **'Filter by Role'**
  String get adminUsers_filterByRole;

  /// No description provided for @adminUsers_roleAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminUsers_roleAll;

  /// No description provided for @adminUsers_roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminUsers_roleAdmin;

  /// No description provided for @adminUsers_roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminUsers_roleUser;

  /// No description provided for @adminUsers_failedLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get adminUsers_failedLoadUsers;

  /// No description provided for @adminUsers_noUsersFoundQuery.
  ///
  /// In en, this message translates to:
  /// **'No users found matching \"{query}\"'**
  String adminUsers_noUsersFoundQuery(String query);

  /// No description provided for @adminUsers_noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminUsers_noUsersFound;

  /// No description provided for @adminUsers_noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get adminUsers_noName;

  /// No description provided for @adminUsers_noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get adminUsers_noEmail;

  /// No description provided for @adminUsers_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get adminUsers_disable;

  /// No description provided for @adminUsers_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get adminUsers_enable;

  /// No description provided for @adminUsers_tooltipDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get adminUsers_tooltipDetails;

  /// No description provided for @adminUsers_userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get adminUsers_userDetails;

  /// No description provided for @adminUsers_labelUid.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get adminUsers_labelUid;

  /// No description provided for @adminUsers_labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminUsers_labelEmail;

  /// No description provided for @adminUsers_labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminUsers_labelName;

  /// No description provided for @adminUsers_labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminUsers_labelStatus;

  /// No description provided for @adminUsers_labelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get adminUsers_labelCreated;

  /// No description provided for @adminUsers_labelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get adminUsers_labelUpdated;

  /// No description provided for @adminUsers_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adminUsers_none;

  /// No description provided for @adminUsers_statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adminUsers_statusDisabled;

  /// No description provided for @adminUsers_statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminUsers_statusActive;

  /// No description provided for @adminUsers_disableUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable User'**
  String get adminUsers_disableUserTitle;

  /// No description provided for @adminUsers_disableUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable {name}?'**
  String adminUsers_disableUserConfirm(String name);

  /// No description provided for @adminUsers_thisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get adminUsers_thisUser;

  /// No description provided for @adminUsers_userDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'User disabled successfully'**
  String get adminUsers_userDisabledSuccess;

  /// No description provided for @adminUsers_enableUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable User'**
  String get adminUsers_enableUserTitle;

  /// No description provided for @adminUsers_enableUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enable {name}?'**
  String adminUsers_enableUserConfirm(String name);

  /// No description provided for @adminUsers_userEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'User enabled successfully'**
  String get adminUsers_userEnabledSuccess;

  /// No description provided for @adminUsers_confirmPermanentDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Permanent Deletion'**
  String get adminUsers_confirmPermanentDeletion;

  /// No description provided for @adminUsers_deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action cannot be undone. All user data will be permanently deleted.'**
  String get adminUsers_deleteWarning;

  /// No description provided for @adminUsers_typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get adminUsers_typeDeleteToConfirm;

  /// No description provided for @adminUsers_typeDeleteHere.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE here'**
  String get adminUsers_typeDeleteHere;

  /// No description provided for @adminUsers_userDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get adminUsers_userDeletedSuccess;

  /// No description provided for @adminUsers_failedDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user: {error}'**
  String adminUsers_failedDeleteUser(String error);

  /// No description provided for @auth_newToKvikTime.
  ///
  /// In en, this message translates to:
  /// **'New to KvikTime?'**
  String get auth_newToKvikTime;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get auth_createAccount;

  /// No description provided for @auth_redirectNote.
  ///
  /// In en, this message translates to:
  /// **'New users will be redirected to our account creation page'**
  String get auth_redirectNote;

  /// No description provided for @auth_signInInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check your credentials.'**
  String get auth_signInInvalidCredentials;

  /// No description provided for @auth_signInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server. Check your internet connection and try again.'**
  String get auth_signInNetworkError;

  /// No description provided for @auth_signInGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during sign in. Please try again.'**
  String get auth_signInGenericError;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get auth_invalidEmail;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get auth_passwordRequired;

  /// No description provided for @signup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up in the app and continue to subscription.'**
  String get signup_subtitle;

  /// No description provided for @signup_firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get signup_firstNameLabel;

  /// No description provided for @signup_lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get signup_lastNameLabel;

  /// No description provided for @signup_firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get signup_firstNameRequired;

  /// No description provided for @signup_lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get signup_lastNameRequired;

  /// No description provided for @signup_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signup_confirmPasswordLabel;

  /// No description provided for @signup_confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signup_confirmPasswordRequired;

  /// No description provided for @signup_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signup_passwordTooShort;

  /// No description provided for @signup_passwordStrongRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must include uppercase, lowercase, number, and special character.'**
  String get signup_passwordStrongRequired;

  /// No description provided for @signup_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signup_passwordsDoNotMatch;

  /// No description provided for @signup_acceptLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'I accept the'**
  String get signup_acceptLegalPrefix;

  /// No description provided for @signup_acceptLegalAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get signup_acceptLegalAnd;

  /// No description provided for @signup_acceptLegalRequired.
  ///
  /// In en, this message translates to:
  /// **'You must accept Terms and Privacy Policy to continue.'**
  String get signup_acceptLegalRequired;

  /// No description provided for @signup_errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many email requests. Wait a few minutes and try again.'**
  String get signup_errorRateLimit;

  /// No description provided for @signup_errorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email confirmation is required. Check your inbox and confirm, then sign in.'**
  String get signup_errorEmailNotConfirmed;

  /// No description provided for @signup_errorUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please sign in.'**
  String get signup_errorUserExists;

  /// No description provided for @signup_errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Please try again.'**
  String get signup_errorGeneric;

  /// No description provided for @legal_acceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get legal_acceptTitle;

  /// No description provided for @legal_acceptBody.
  ///
  /// In en, this message translates to:
  /// **'To continue using KvikTime, please review and accept our Terms of Service and Privacy Policy.'**
  String get legal_acceptBody;

  /// No description provided for @legal_acceptButton.
  ///
  /// In en, this message translates to:
  /// **'I Accept'**
  String get legal_acceptButton;

  /// No description provided for @reportsCustom_periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsCustom_periodToday;

  /// No description provided for @reportsCustom_periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reportsCustom_periodThisWeek;

  /// No description provided for @reportsCustom_periodLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get reportsCustom_periodLast7Days;

  /// No description provided for @reportsCustom_periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportsCustom_periodThisMonth;

  /// No description provided for @reportsCustom_periodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get reportsCustom_periodLastMonth;

  /// No description provided for @reportsCustom_periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get reportsCustom_periodThisYear;

  /// No description provided for @reportsCustom_periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get reportsCustom_periodCustom;

  /// No description provided for @reportsCustom_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsCustom_filterAll;

  /// No description provided for @reportsCustom_filterWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get reportsCustom_filterWork;

  /// No description provided for @reportsCustom_filterTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get reportsCustom_filterTravel;

  /// No description provided for @reportsCustom_filterLeave.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get reportsCustom_filterLeave;

  /// No description provided for @reportsCustom_workDays.
  ///
  /// In en, this message translates to:
  /// **'Work days'**
  String get reportsCustom_workDays;

  /// No description provided for @reportsCustom_daysWithWork.
  ///
  /// In en, this message translates to:
  /// **'Days with work'**
  String get reportsCustom_daysWithWork;

  /// No description provided for @reportsCustom_averagePerDay.
  ///
  /// In en, this message translates to:
  /// **'Average per day'**
  String get reportsCustom_averagePerDay;

  /// No description provided for @reportsCustom_workedTime.
  ///
  /// In en, this message translates to:
  /// **'Worked time'**
  String get reportsCustom_workedTime;

  /// No description provided for @reportsCustom_breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get reportsCustom_breaks;

  /// No description provided for @reportsCustom_breakAveragePerShift.
  ///
  /// In en, this message translates to:
  /// **'{value} / shift'**
  String reportsCustom_breakAveragePerShift(String value);

  /// No description provided for @reportsCustom_longestShift.
  ///
  /// In en, this message translates to:
  /// **'Longest shift'**
  String get reportsCustom_longestShift;

  /// No description provided for @reportsCustom_noLocationProvided.
  ///
  /// In en, this message translates to:
  /// **'No location provided'**
  String get reportsCustom_noLocationProvided;

  /// No description provided for @reportsCustom_travelTime.
  ///
  /// In en, this message translates to:
  /// **'Travel time'**
  String get reportsCustom_travelTime;

  /// No description provided for @reportsCustom_totalTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Total travel time'**
  String get reportsCustom_totalTravelTime;

  /// No description provided for @reportsCustom_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get reportsCustom_trips;

  /// No description provided for @reportsCustom_tripCount.
  ///
  /// In en, this message translates to:
  /// **'Number of trips'**
  String get reportsCustom_tripCount;

  /// No description provided for @reportsCustom_averagePerTrip.
  ///
  /// In en, this message translates to:
  /// **'Average per trip'**
  String get reportsCustom_averagePerTrip;

  /// No description provided for @reportsCustom_averageTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Average travel time'**
  String get reportsCustom_averageTravelTime;

  /// No description provided for @reportsCustom_topRoutes.
  ///
  /// In en, this message translates to:
  /// **'Top routes'**
  String get reportsCustom_topRoutes;

  /// No description provided for @reportsCustom_topRouteLine.
  ///
  /// In en, this message translates to:
  /// **'{route} - {count} trips - {duration}'**
  String reportsCustom_topRouteLine(String route, int count, String duration);

  /// No description provided for @reportsCustom_leaveDays.
  ///
  /// In en, this message translates to:
  /// **'Leave days'**
  String get reportsCustom_leaveDays;

  /// No description provided for @reportsCustom_totalInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total in period'**
  String get reportsCustom_totalInPeriod;

  /// No description provided for @reportsCustom_leaveEntries.
  ///
  /// In en, this message translates to:
  /// **'Leave entries'**
  String get reportsCustom_leaveEntries;

  /// No description provided for @reportsCustom_registeredEntries.
  ///
  /// In en, this message translates to:
  /// **'Registered entries'**
  String get reportsCustom_registeredEntries;

  /// No description provided for @reportsCustom_paidLeave.
  ///
  /// In en, this message translates to:
  /// **'Credited leave'**
  String get reportsCustom_paidLeave;

  /// No description provided for @reportsCustom_paidLeaveTypes.
  ///
  /// In en, this message translates to:
  /// **'Vacation/Sick/VAB'**
  String get reportsCustom_paidLeaveTypes;

  /// No description provided for @reportsCustom_unpaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Unpaid leave'**
  String get reportsCustom_unpaidLeave;

  /// No description provided for @reportsCustom_unpaidLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Unpaid leave'**
  String get reportsCustom_unpaidLeaveType;

  /// No description provided for @reportsCustom_balanceAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustments'**
  String get reportsCustom_balanceAdjustments;

  /// No description provided for @reportsCustom_openingBalanceEffectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Opening balance: {value} (effective from {date})'**
  String reportsCustom_openingBalanceEffectiveFrom(String value, String date);

  /// No description provided for @reportsCustom_timeAdjustmentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Time adjustments: {value}'**
  String reportsCustom_timeAdjustmentsTotal(String value);

  /// No description provided for @reportsCustom_timeAdjustmentsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Time adjustments in period'**
  String get reportsCustom_timeAdjustmentsInPeriod;

  /// No description provided for @reportsCustom_noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get reportsCustom_noNote;

  /// No description provided for @reportsCustom_balanceAtPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Balance at period start: {value}'**
  String reportsCustom_balanceAtPeriodStart(String value);

  /// No description provided for @reportsCustom_balanceAtPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'Balance at period end: {value}'**
  String reportsCustom_balanceAtPeriodEnd(String value);

  /// No description provided for @reportsCustom_periodStartIncludesStartDateAdjustmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Adjustments on the start date are included in the period start balance.'**
  String get reportsCustom_periodStartIncludesStartDateAdjustmentsHint;

  /// No description provided for @reportsCustom_entriesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Entries in period'**
  String get reportsCustom_entriesInPeriod;

  /// No description provided for @reportsCustom_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries in this period'**
  String get reportsCustom_emptyTitle;

  /// No description provided for @reportsCustom_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change period or filter'**
  String get reportsCustom_emptySubtitle;

  /// No description provided for @reportsCustom_exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportsCustom_exportCsv;

  /// No description provided for @reportsCustom_exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get reportsCustom_exportExcel;

  /// No description provided for @reportsCustom_exportCsvDone.
  ///
  /// In en, this message translates to:
  /// **'Export CSV: done'**
  String get reportsCustom_exportCsvDone;

  /// No description provided for @reportsCustom_exportExcelDone.
  ///
  /// In en, this message translates to:
  /// **'Export Excel: done'**
  String get reportsCustom_exportExcelDone;

  /// No description provided for @reportsCustom_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String reportsCustom_exportFailed(String error);

  /// No description provided for @reportsExport_entriesSheetName.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get reportsExport_entriesSheetName;

  /// No description provided for @reportsExport_adjustmentsSheetName.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustments'**
  String get reportsExport_adjustmentsSheetName;

  /// No description provided for @reportsExport_openingBalanceRow.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get reportsExport_openingBalanceRow;

  /// No description provided for @reportsExport_timeAdjustmentRow.
  ///
  /// In en, this message translates to:
  /// **'Time adjustment'**
  String get reportsExport_timeAdjustmentRow;

  /// No description provided for @reportsExport_timeAdjustmentsTotalRow.
  ///
  /// In en, this message translates to:
  /// **'Time adjustments total'**
  String get reportsExport_timeAdjustmentsTotalRow;

  /// No description provided for @reportsExport_periodStartBalanceRow.
  ///
  /// In en, this message translates to:
  /// **'Balance at period start'**
  String get reportsExport_periodStartBalanceRow;

  /// No description provided for @reportsExport_periodEndBalanceRow.
  ///
  /// In en, this message translates to:
  /// **'Balance at period end'**
  String get reportsExport_periodEndBalanceRow;

  /// No description provided for @reportsExport_colType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reportsExport_colType;

  /// No description provided for @reportsExport_colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsExport_colDate;

  /// No description provided for @reportsExport_colMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get reportsExport_colMinutes;

  /// No description provided for @reportsExport_colHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get reportsExport_colHours;

  /// No description provided for @reportsExport_colNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get reportsExport_colNote;

  /// No description provided for @reportsExport_fileName.
  ///
  /// In en, this message translates to:
  /// **'report_export'**
  String get reportsExport_fileName;

  /// No description provided for @reportsMetric_tracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get reportsMetric_tracked;

  /// No description provided for @reportsMetric_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get reportsMetric_leave;

  /// No description provided for @reportsMetric_accounted.
  ///
  /// In en, this message translates to:
  /// **'Accounted'**
  String get reportsMetric_accounted;

  /// No description provided for @reportsMetric_delta.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get reportsMetric_delta;

  /// No description provided for @reportsMetric_trackedPlusLeave.
  ///
  /// In en, this message translates to:
  /// **'Tracked + leave'**
  String get reportsMetric_trackedPlusLeave;

  /// No description provided for @reportsMetric_accountedMinusTarget.
  ///
  /// In en, this message translates to:
  /// **'Accounted - target'**
  String get reportsMetric_accountedMinusTarget;

  /// No description provided for @session_expiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get session_expiredTitle;

  /// No description provided for @session_expiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again to continue.'**
  String get session_expiredBody;

  /// No description provided for @session_signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign In Again'**
  String get session_signInAgain;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @onboarding_step1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboarding_step1Title;

  /// No description provided for @onboarding_step2Title.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get onboarding_step2Title;

  /// No description provided for @onboarding_step3Title.
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get onboarding_step3Title;

  /// No description provided for @onboarding_stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboarding_stepIndicator(int current, int total);

  /// No description provided for @onboarding_modeQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you want to use KvikTime?'**
  String get onboarding_modeQuestion;

  /// No description provided for @onboarding_modeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the basics once and track the change over time.'**
  String get onboarding_modeSubtitle;

  /// No description provided for @onboarding_modeBalance.
  ///
  /// In en, this message translates to:
  /// **'Time balance (recommended)'**
  String get onboarding_modeBalance;

  /// No description provided for @onboarding_modeLogOnly.
  ///
  /// In en, this message translates to:
  /// **'Log time only'**
  String get onboarding_modeLogOnly;

  /// No description provided for @onboarding_toggleTravel.
  ///
  /// In en, this message translates to:
  /// **'Log travel time'**
  String get onboarding_toggleTravel;

  /// No description provided for @onboarding_togglePaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Track paid leave'**
  String get onboarding_togglePaidLeave;

  /// No description provided for @onboarding_contractTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick contract setup'**
  String get onboarding_contractTitle;

  /// No description provided for @onboarding_contractBody.
  ///
  /// In en, this message translates to:
  /// **'We prefill safe defaults so you can get started quickly.'**
  String get onboarding_contractBody;

  /// No description provided for @onboarding_contractWorkdays.
  ///
  /// In en, this message translates to:
  /// **'Workdays: {days}'**
  String onboarding_contractWorkdays(int days);

  /// No description provided for @onboarding_baselineTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your plus/minus right now?'**
  String get onboarding_baselineTitle;

  /// No description provided for @onboarding_baselineHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask payroll/manager: What is my plus/minus today?'**
  String get onboarding_baselineHelp;

  /// No description provided for @onboarding_baselineNote.
  ///
  /// In en, this message translates to:
  /// **'Do not enter total worked time.'**
  String get onboarding_baselineNote;

  /// No description provided for @onboarding_baselineLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance baseline'**
  String get onboarding_baselineLabel;

  /// No description provided for @onboarding_baselinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'+29h or -5h'**
  String get onboarding_baselinePlaceholder;

  /// No description provided for @onboarding_baselineError.
  ///
  /// In en, this message translates to:
  /// **'Enter a balance like +29h, -5h, or +29h 30m.'**
  String get onboarding_baselineError;

  /// No description provided for @legal_documentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found'**
  String get legal_documentNotFound;

  /// No description provided for @legal_documentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load document'**
  String get legal_documentLoadFailed;

  /// No description provided for @accountStatus_loading.
  ///
  /// In en, this message translates to:
  /// **'Checking account status...'**
  String get accountStatus_loading;

  /// No description provided for @accountStatus_setupIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Account setup incomplete'**
  String get accountStatus_setupIncompleteTitle;

  /// No description provided for @accountStatus_setupIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'We could not finish setting up your account profile. Please retry.'**
  String get accountStatus_setupIncompleteBody;

  /// No description provided for @accountStatus_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String accountStatus_loadFailed(String error);
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
