import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ShikkhaAI'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get navStudy;

  /// No description provided for @navExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get navExam;

  /// No description provided for @navTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get navTopics;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get commonSeeAll;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsSystemDefault;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get settingsLanguageBangla;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out and return to login'**
  String get settingsLogOutSubtitle;

  /// No description provided for @settingsLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get settingsLogOutConfirmTitle;

  /// No description provided for @settingsLogOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogOutConfirmBody;

  /// No description provided for @settingsResetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset Onboarding'**
  String get settingsResetOnboarding;

  /// No description provided for @settingsResetOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all local data and restart setup'**
  String get settingsResetOnboardingSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsVersion;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerStudyCompanion.
  ///
  /// In en, this message translates to:
  /// **'Study Companion'**
  String get drawerStudyCompanion;

  /// No description provided for @drawerSmartExam.
  ///
  /// In en, this message translates to:
  /// **'Smart Exam'**
  String get drawerSmartExam;

  /// No description provided for @drawerStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get drawerStudyPlan;

  /// No description provided for @drawerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get drawerAnalytics;

  /// No description provided for @drawerHelpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get drawerHelpFeedback;

  /// No description provided for @drawerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, Student'**
  String get drawerGreeting;

  /// No description provided for @drawerStreakTagline.
  ///
  /// In en, this message translates to:
  /// **'Keep up the streak!'**
  String get drawerStreakTagline;

  /// No description provided for @drawerFooter.
  ///
  /// In en, this message translates to:
  /// **'ShikkhaAI · v1.0.0'**
  String get drawerFooter;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'AI-powered study companion'**
  String get splashTagline;

  /// No description provided for @appVersionShort.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get appVersionShort;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @onboardGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardGetStarted;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Study Companion'**
  String get onboard1Title;

  /// No description provided for @onboard1Desc.
  ///
  /// In en, this message translates to:
  /// **'Upload your textbooks and notes. ShikkhaAI reads, understands, and creates personalized study materials just for you.'**
  String get onboard1Desc;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Exams'**
  String get onboard2Title;

  /// No description provided for @onboard2Desc.
  ///
  /// In en, this message translates to:
  /// **'Generate custom exam questions from any chapter. Practice with instant feedback and detailed explanations.'**
  String get onboard2Desc;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Track Your Progress'**
  String get onboard3Title;

  /// No description provided for @onboard3Desc.
  ///
  /// In en, this message translates to:
  /// **'Visual dashboards, study plans, and performance analytics to help you improve consistently.'**
  String get onboard3Desc;

  /// No description provided for @authValidateName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authValidateName;

  /// No description provided for @authValidateNameShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get authValidateNameShort;

  /// No description provided for @authValidateNameLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be less than 120 characters'**
  String get authValidateNameLong;

  /// No description provided for @authValidateEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authValidateEmail;

  /// No description provided for @authValidateEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authValidateEmailInvalid;

  /// No description provided for @authValidatePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get authValidatePassword;

  /// No description provided for @authValidatePasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authValidatePasswordShort;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authWelcomeBack;

  /// No description provided for @authCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your Profile'**
  String get authCreateProfile;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your learning journey.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about yourself so we can personalize your study experience.'**
  String get authRegisterSubtitle;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authFullNameHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authToggleToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authToggleToRegister;

  /// No description provided for @authToggleToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authToggleToLogin;

  /// No description provided for @authSelectClass.
  ///
  /// In en, this message translates to:
  /// **'Select Your Class'**
  String get authSelectClass;

  /// No description provided for @authSelectClassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your current class so we can tailor content to your curriculum.'**
  String get authSelectClassSubtitle;

  /// No description provided for @authSubjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} subjects available'**
  String authSubjectsAvailable(int count);

  /// No description provided for @authCompleteRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get authCompleteRegistration;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, Student 👋'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn something new today?'**
  String get homeSubtitle;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeActionStudySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI explanations'**
  String get homeActionStudySubtitle;

  /// No description provided for @homeActionExamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive quiz'**
  String get homeActionExamSubtitle;

  /// No description provided for @homeActionAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track weaknesses'**
  String get homeActionAnalyticsSubtitle;

  /// No description provided for @homeActionPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your week'**
  String get homeActionPlanSubtitle;

  /// No description provided for @homeContinueWithAi.
  ///
  /// In en, this message translates to:
  /// **'Continue with AI'**
  String get homeContinueWithAi;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything · get instant clarity'**
  String get homeHeroSubtitle;

  /// No description provided for @homeTodaysFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Focus'**
  String get homeTodaysFocus;

  /// No description provided for @homePracticeNow.
  ///
  /// In en, this message translates to:
  /// **'Practice Now'**
  String get homePracticeNow;

  /// No description provided for @homeAccuracyPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% accuracy'**
  String homeAccuracyPercent(String percent);

  /// No description provided for @homeAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All Caught Up!'**
  String get homeAllCaughtUp;

  /// No description provided for @homeAllCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No weak topics right now. Keep up the great work!'**
  String get homeAllCaughtUpSubtitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get dashboardTitle;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get dashboardLoadFailed;

  /// No description provided for @dashReadinessScore.
  ///
  /// In en, this message translates to:
  /// **'Readiness Score'**
  String get dashReadinessScore;

  /// No description provided for @dashOutOf100.
  ///
  /// In en, this message translates to:
  /// **'OUT OF 100'**
  String get dashOutOf100;

  /// No description provided for @dashDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String dashDayStreak(int count);

  /// No description provided for @dashLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest: {count} days'**
  String dashLongestStreak(int count);

  /// No description provided for @dashWeekdayInitials.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get dashWeekdayInitials;

  /// No description provided for @dashAiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get dashAiRecommendations;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'MED'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get priorityLow;

  /// No description provided for @dashImprovementOverTime.
  ///
  /// In en, this message translates to:
  /// **'Improvement Over Time'**
  String get dashImprovementOverTime;

  /// No description provided for @dashTopicAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Topic Accuracy'**
  String get dashTopicAccuracy;

  /// No description provided for @dashRecentQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Recent Quizzes'**
  String get dashRecentQuizzes;

  /// No description provided for @dashViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashViewAll;

  /// No description provided for @dashWeakSubjects.
  ///
  /// In en, this message translates to:
  /// **'Weak Subjects'**
  String get dashWeakSubjects;

  /// No description provided for @dashQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} Qs)'**
  String dashQuestionsCount(int count);

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weakness Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsAvgAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Avg Accuracy'**
  String get analyticsAvgAccuracy;

  /// No description provided for @analyticsWeakChapters.
  ///
  /// In en, this message translates to:
  /// **'Weak Chapters'**
  String get analyticsWeakChapters;

  /// No description provided for @analyticsDayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get analyticsDayStreakLabel;

  /// No description provided for @analyticsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading analytics...'**
  String get analyticsLoading;

  /// No description provided for @analyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get analyticsLoadFailed;

  /// No description provided for @analyticsReadyToImprove.
  ///
  /// In en, this message translates to:
  /// **'Ready to improve?'**
  String get analyticsReadyToImprove;

  /// No description provided for @analyticsWeakTopicsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 weak topic waiting in the Exam tab.} other{{count} weak topics waiting in the Exam tab.}}'**
  String analyticsWeakTopicsWaiting(int count);

  /// No description provided for @analyticsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get analyticsLast7Days;

  /// No description provided for @analyticsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get analyticsLast30Days;

  /// No description provided for @analyticsLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get analyticsLast90Days;

  /// No description provided for @heatmapTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Heatmap'**
  String get heatmapTitle;

  /// No description provided for @heatmapNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No Activity Yet'**
  String get heatmapNoActivity;

  /// No description provided for @heatmapNoActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first quiz to start tracking daily performance.'**
  String get heatmapNoActivityDesc;

  /// No description provided for @heatmapNoActivityDay.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get heatmapNoActivityDay;

  /// No description provided for @legendHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get legendHigh;

  /// No description provided for @legendMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get legendMid;

  /// No description provided for @legendLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get legendLow;

  /// No description provided for @legendNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get legendNone;

  /// No description provided for @analyticsWeekdayInitialsSun.
  ///
  /// In en, this message translates to:
  /// **'S,M,T,W,T,F,S'**
  String get analyticsWeekdayInitialsSun;

  /// No description provided for @streakDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get streakDailyStreak;

  /// No description provided for @streakDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakDaysShort(int count);

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get streakCurrent;

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get streakBest;

  /// No description provided for @streakActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get streakActive;

  /// No description provided for @radarTitle.
  ///
  /// In en, this message translates to:
  /// **'Topic Accuracy Radar'**
  String get radarTitle;

  /// No description provided for @radarYourScore.
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get radarYourScore;

  /// No description provided for @radarBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get radarBenchmark;

  /// No description provided for @radarNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Data'**
  String get radarNotEnough;

  /// No description provided for @radarNotEnoughDesc.
  ///
  /// In en, this message translates to:
  /// **'Attempt questions in at least 3 different topics to see your accuracy radar.'**
  String get radarNotEnoughDesc;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized Practice'**
  String get practiceTitle;

  /// No description provided for @practiceNoteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Study note not available yet'**
  String get practiceNoteUnavailable;

  /// No description provided for @practiceSavedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to Library'**
  String get practiceSavedToLibrary;

  /// No description provided for @practiceSaveAsNote.
  ///
  /// In en, this message translates to:
  /// **'Save as note'**
  String get practiceSaveAsNote;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @impactPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% impact'**
  String impactPercent(String percent);

  /// No description provided for @weakChaptersDetected.
  ///
  /// In en, this message translates to:
  /// **'Weak Chapters Detected'**
  String get weakChaptersDetected;

  /// No description provided for @minutesSpent.
  ///
  /// In en, this message translates to:
  /// **'{count} min spent'**
  String minutesSpent(int count);

  /// No description provided for @diffEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get diffHard;

  /// No description provided for @examTypePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get examTypePractice;

  /// No description provided for @examTypeSsc.
  ///
  /// In en, this message translates to:
  /// **'SSC'**
  String get examTypeSsc;

  /// No description provided for @examTypeHsc.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get examTypeHsc;

  /// No description provided for @examTypePracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customizable quick exam'**
  String get examTypePracticeSubtitle;

  /// No description provided for @examTypeSscSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SSC Board Exam Style'**
  String get examTypeSscSubtitle;

  /// No description provided for @examTypeHscSubtitle.
  ///
  /// In en, this message translates to:
  /// **'HSC Board Exam Style'**
  String get examTypeHscSubtitle;

  /// No description provided for @qTypeMcq.
  ///
  /// In en, this message translates to:
  /// **'MCQ'**
  String get qTypeMcq;

  /// No description provided for @qTypeShortAnswer.
  ///
  /// In en, this message translates to:
  /// **'Short Answer'**
  String get qTypeShortAnswer;

  /// No description provided for @qTypeCq.
  ///
  /// In en, this message translates to:
  /// **'CQ'**
  String get qTypeCq;

  /// No description provided for @examConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Exam'**
  String get examConfigTitle;

  /// No description provided for @examSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get examSubject;

  /// No description provided for @examTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get examTopic;

  /// No description provided for @examTopicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Photosynthesis, Newton\'s Laws'**
  String get examTopicHint;

  /// No description provided for @examClassLevel.
  ///
  /// In en, this message translates to:
  /// **'Class Level'**
  String get examClassLevel;

  /// No description provided for @examClassN.
  ///
  /// In en, this message translates to:
  /// **'Class {level}'**
  String examClassN(String level);

  /// No description provided for @examDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get examDifficulty;

  /// No description provided for @examExamType.
  ///
  /// In en, this message translates to:
  /// **'Exam Type'**
  String get examExamType;

  /// No description provided for @examNumQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get examNumQuestions;

  /// No description provided for @examTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get examTimeLimit;

  /// No description provided for @examPreview.
  ///
  /// In en, this message translates to:
  /// **'Exam Preview'**
  String get examPreview;

  /// No description provided for @examRowClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get examRowClass;

  /// No description provided for @examRowType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get examRowType;

  /// No description provided for @examRowQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get examRowQuestions;

  /// No description provided for @examRowTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get examRowTime;

  /// No description provided for @examTotalMarks.
  ///
  /// In en, this message translates to:
  /// **'Total Marks'**
  String get examTotalMarks;

  /// No description provided for @examGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get examGenerating;

  /// No description provided for @examStart.
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get examStart;

  /// No description provided for @examStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start exam: {error}'**
  String examStartFailed(String error);

  /// No description provided for @examFocusWeakTopics.
  ///
  /// In en, this message translates to:
  /// **'Focus on Weak Topics'**
  String get examFocusWeakTopics;

  /// No description provided for @examRecentExams.
  ///
  /// In en, this message translates to:
  /// **'Recent Exams'**
  String get examRecentExams;

  /// No description provided for @examNoExamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Exams Yet'**
  String get examNoExamsTitle;

  /// No description provided for @examNoExamsMsg.
  ///
  /// In en, this message translates to:
  /// **'Generate your first AI-powered exam and start practicing.'**
  String get examNoExamsMsg;

  /// No description provided for @examNewExam.
  ///
  /// In en, this message translates to:
  /// **'New Exam'**
  String get examNewExam;

  /// No description provided for @examPracticeChip.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get examPracticeChip;

  /// No description provided for @examStatExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get examStatExams;

  /// No description provided for @examStatAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg Score'**
  String get examStatAvgScore;

  /// No description provided for @examStatBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get examStatBest;

  /// No description provided for @examStartNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a New Exam'**
  String get examStartNewTitle;

  /// No description provided for @examStartNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice with MCQ, CQ, and Short Answer questions tailored to your level.'**
  String get examStartNewSubtitle;

  /// No description provided for @examSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Exam?'**
  String get examSubmitTitle;

  /// No description provided for @examSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'You have answered {answered} out of {total} questions. Are you sure you want to submit?'**
  String examSubmitBody(int answered, int total);

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @examNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get examNoQuestions;

  /// No description provided for @examPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get examPrevious;

  /// No description provided for @examHideAnswer.
  ///
  /// In en, this message translates to:
  /// **'Hide Answer'**
  String get examHideAnswer;

  /// No description provided for @examCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get examCheckAnswer;

  /// No description provided for @examExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get examExplanation;

  /// No description provided for @examCorrectAnswerInline.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer: {answer}'**
  String examCorrectAnswerInline(String answer);

  /// No description provided for @examSubmissionFailedNoResult.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: no result received'**
  String get examSubmissionFailedNoResult;

  /// No description provided for @examSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String examSubmissionFailed(String error);

  /// No description provided for @examHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam History'**
  String get examHistoryTitle;

  /// No description provided for @examNoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No History'**
  String get examNoHistoryTitle;

  /// No description provided for @examNoHistoryMsg.
  ///
  /// In en, this message translates to:
  /// **'Your completed exams will appear here.'**
  String get examNoHistoryMsg;

  /// No description provided for @examClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All History?'**
  String get examClearHistoryTitle;

  /// No description provided for @examClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all exam results. This action cannot be undone.'**
  String get examClearHistoryBody;

  /// No description provided for @examClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get examClearAll;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeDaysAgo(int count);

  /// No description provided for @examResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Result'**
  String get examResultTitle;

  /// No description provided for @examResultNotFound.
  ///
  /// In en, this message translates to:
  /// **'Result not found'**
  String get examResultNotFound;

  /// No description provided for @examGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get examGoHome;

  /// No description provided for @examHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get examHome;

  /// No description provided for @examStudyNotesGenerated.
  ///
  /// In en, this message translates to:
  /// **'Study Notes Generated'**
  String get examStudyNotesGenerated;

  /// No description provided for @examStudyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a topic below to review your personalised study notes.'**
  String get examStudyNotesSubtitle;

  /// No description provided for @examAnswerReviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Answer review not available for this attempt.'**
  String get examAnswerReviewUnavailable;

  /// No description provided for @examSomeAnswersMissing.
  ///
  /// In en, this message translates to:
  /// **'Some answers may not be displayed ({answered}/{total} saved locally).'**
  String examSomeAnswersMissing(int answered, int total);

  /// No description provided for @qCardQuestionXofY.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}'**
  String qCardQuestionXofY(int number, int total);

  /// No description provided for @qCardMarks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Mark} other{{count} Marks}}'**
  String qCardMarks(int count);

  /// No description provided for @progressAnswered.
  ///
  /// In en, this message translates to:
  /// **'{count} Answered'**
  String progressAnswered(int count);

  /// No description provided for @progressMarked.
  ///
  /// In en, this message translates to:
  /// **'{count} Marked'**
  String progressMarked(int count);

  /// No description provided for @progressLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} Left'**
  String progressLeft(int count);

  /// No description provided for @badgeAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive'**
  String get badgeAdaptive;

  /// No description provided for @shortAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get shortAnswerHint;

  /// No description provided for @cqAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Answer for {part}'**
  String cqAnswerHint(String part);

  /// No description provided for @answerReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer Review'**
  String get answerReviewTitle;

  /// No description provided for @answerYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer:'**
  String get answerYourAnswer;

  /// No description provided for @answerNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get answerNotAnswered;

  /// No description provided for @answerCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer:'**
  String get answerCorrectAnswer;

  /// No description provided for @answerMarks.
  ///
  /// In en, this message translates to:
  /// **'Marks:'**
  String get answerMarks;

  /// No description provided for @qPrefix.
  ///
  /// In en, this message translates to:
  /// **'Q{index}: {prompt}'**
  String qPrefix(int index, String prompt);

  /// No description provided for @marksPrediction.
  ///
  /// In en, this message translates to:
  /// **'Marks Prediction'**
  String get marksPrediction;

  /// No description provided for @examConfidenceBadge.
  ///
  /// In en, this message translates to:
  /// **'{level} Confidence'**
  String examConfidenceBadge(String level);

  /// No description provided for @examReadinessBadge.
  ///
  /// In en, this message translates to:
  /// **'Readiness: {value}%'**
  String examReadinessBadge(String value);

  /// No description provided for @marksPredictionDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on your current performance and consistency across topics.'**
  String get marksPredictionDesc;

  /// No description provided for @summaryMarksObtained.
  ///
  /// In en, this message translates to:
  /// **'Marks Obtained'**
  String get summaryMarksObtained;

  /// No description provided for @summaryMcq.
  ///
  /// In en, this message translates to:
  /// **'MCQ'**
  String get summaryMcq;

  /// No description provided for @summaryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get summaryTime;

  /// No description provided for @summaryGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get summaryGrade;

  /// No description provided for @weakGreatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get weakGreatJob;

  /// No description provided for @weakNoWeakTopics.
  ///
  /// In en, this message translates to:
  /// **'No weak topics detected. Keep up the good work!'**
  String get weakNoWeakTopics;

  /// No description provided for @weakTopicsToReview.
  ///
  /// In en, this message translates to:
  /// **'Topics to Review'**
  String get weakTopicsToReview;

  /// No description provided for @scModeEasyBengaliLabel.
  ///
  /// In en, this message translates to:
  /// **'Easy Bengali'**
  String get scModeEasyBengaliLabel;

  /// No description provided for @scModeEasyBengaliSubtitle.
  ///
  /// In en, this message translates to:
  /// **'সহজ বাংলায় বুঝুন'**
  String get scModeEasyBengaliSubtitle;

  /// No description provided for @scModeEasyEnglishLabel.
  ///
  /// In en, this message translates to:
  /// **'Easy English'**
  String get scModeEasyEnglishLabel;

  /// No description provided for @scModeEasyEnglishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple English'**
  String get scModeEasyEnglishSubtitle;

  /// No description provided for @scModeExplain10Label.
  ///
  /// In en, this message translates to:
  /// **'Explain Like I\'m 10'**
  String get scModeExplain10Label;

  /// No description provided for @scModeExplain10Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Super simple!'**
  String get scModeExplain10Subtitle;

  /// No description provided for @scModeSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get scModeSummaryLabel;

  /// No description provided for @scModeSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick overview'**
  String get scModeSummarySubtitle;

  /// No description provided for @scModeImportantQLabel.
  ///
  /// In en, this message translates to:
  /// **'Important Questions'**
  String get scModeImportantQLabel;

  /// No description provided for @scModeImportantQSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Key exam questions'**
  String get scModeImportantQSubtitle;

  /// No description provided for @scModeCommonMistakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Common Mistakes'**
  String get scModeCommonMistakesLabel;

  /// No description provided for @scModeCommonMistakesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid errors'**
  String get scModeCommonMistakesSubtitle;

  /// No description provided for @scModeExamTipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam Tips'**
  String get scModeExamTipsLabel;

  /// No description provided for @scModeExamTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score higher'**
  String get scModeExamTipsSubtitle;

  /// No description provided for @scTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Study Companion'**
  String get scTitle;

  /// No description provided for @scNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get scNewChat;

  /// No description provided for @scStudyMode.
  ///
  /// In en, this message translates to:
  /// **'Study Mode'**
  String get scStudyMode;

  /// No description provided for @scWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Your personal tutor, always ready'**
  String get scWelcomeTagline;

  /// No description provided for @scWelcomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What would you like to learn?'**
  String get scWelcomeQuestion;

  /// No description provided for @scWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a chapter or ask a question. Choose an explanation mode below.'**
  String get scWelcomeSubtitle;

  /// No description provided for @scQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get scQuickStart;

  /// No description provided for @scSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Explain Photosynthesis'**
  String get scSuggestion1;

  /// No description provided for @scSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Important questions from Chapter 3'**
  String get scSuggestion2;

  /// No description provided for @scSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Common mistakes in algebra'**
  String get scSuggestion3;

  /// No description provided for @scSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Exam tips for Biology'**
  String get scSuggestion4;

  /// No description provided for @scSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Summary of Newton\'s Laws'**
  String get scSuggestion5;

  /// No description provided for @scChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get scChatHistory;

  /// No description provided for @scConversationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}}'**
  String scConversationsCount(int count);

  /// No description provided for @scClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get scClearHistoryTitle;

  /// No description provided for @scClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your chat sessions.'**
  String get scClearHistoryBody;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @scNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get scNoConversations;

  /// No description provided for @scStartNewChat.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat to begin learning!'**
  String get scStartNewChat;

  /// No description provided for @scMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String scMessagesCount(int count);

  /// No description provided for @scInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your studies...'**
  String get scInputHint;

  /// No description provided for @scFilePickError.
  ///
  /// In en, this message translates to:
  /// **'Could not pick file: {error}'**
  String scFilePickError(String error);

  /// No description provided for @scAiExplanation.
  ///
  /// In en, this message translates to:
  /// **'AI Explanation'**
  String get scAiExplanation;

  /// No description provided for @scAiNote.
  ///
  /// In en, this message translates to:
  /// **'AI Note'**
  String get scAiNote;

  /// No description provided for @scCrossReferenced.
  ///
  /// In en, this message translates to:
  /// **'Cross-referenced with Class 8 Science'**
  String get scCrossReferenced;

  /// No description provided for @scSourceDefault.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get scSourceDefault;

  /// No description provided for @scSourcePage.
  ///
  /// In en, this message translates to:
  /// **'{source} — Page {page}'**
  String scSourcePage(String source, String page);

  /// No description provided for @taskReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get taskReading;

  /// No description provided for @taskPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get taskPractice;

  /// No description provided for @taskRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get taskRevision;

  /// No description provided for @taskMockTest.
  ///
  /// In en, this message translates to:
  /// **'Mock Test'**
  String get taskMockTest;

  /// No description provided for @taskRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get taskRest;

  /// No description provided for @planDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get planDefaultTitle;

  /// No description provided for @planOtherPlans.
  ///
  /// In en, this message translates to:
  /// **'Other Plans'**
  String get planOtherPlans;

  /// No description provided for @planCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Plan'**
  String get planCreateNew;

  /// No description provided for @planNoPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'No Study Plan Yet'**
  String get planNoPlansTitle;

  /// No description provided for @planNoPlansMsg.
  ///
  /// In en, this message translates to:
  /// **'Create a personalized study plan to track your progress and stay on schedule.'**
  String get planNoPlansMsg;

  /// No description provided for @planCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create Study Plan'**
  String get planCreatePlan;

  /// No description provided for @planTodaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get planTodaysSchedule;

  /// No description provided for @planTasksMinutes.
  ///
  /// In en, this message translates to:
  /// **'{tasks} tasks · {minutes} minutes'**
  String planTasksMinutes(int tasks, int minutes);

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planToday;

  /// No description provided for @planCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Study Plan'**
  String get planCreateTitle;

  /// No description provided for @planGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate Plan'**
  String get planGenerate;

  /// No description provided for @planWhenExam.
  ///
  /// In en, this message translates to:
  /// **'When is your exam?'**
  String get planWhenExam;

  /// No description provided for @planWhenExamDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll create a schedule that leads up to your exam date.'**
  String get planWhenExamDesc;

  /// No description provided for @planDaysLeftStacked.
  ///
  /// In en, this message translates to:
  /// **'days\nleft'**
  String get planDaysLeftStacked;

  /// No description provided for @planChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get planChangeDate;

  /// No description provided for @planDailyTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much time can you\nstudy daily?'**
  String get planDailyTimeQuestion;

  /// No description provided for @planDailyTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll distribute your subjects across available time.'**
  String get planDailyTimeDesc;

  /// No description provided for @planMinutesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes per day'**
  String planMinutesPerDay(int minutes);

  /// No description provided for @planStudyDuration.
  ///
  /// In en, this message translates to:
  /// **'Study Duration'**
  String get planStudyDuration;

  /// No description provided for @planDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String planDaysValue(int days);

  /// No description provided for @planDailyStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Study Time'**
  String get planDailyStudyTime;

  /// No description provided for @planTotalStudyHours.
  ///
  /// In en, this message translates to:
  /// **'Total Study Hours'**
  String get planTotalStudyHours;

  /// No description provided for @planHoursValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String planHoursValue(String hours);

  /// No description provided for @planSubjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get planSubjectsLabel;

  /// No description provided for @planGeneralStudy.
  ///
  /// In en, this message translates to:
  /// **'General Study'**
  String get planGeneralStudy;

  /// No description provided for @planDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Detail'**
  String get planDetailTitle;

  /// No description provided for @planNoScheduleDay.
  ///
  /// In en, this message translates to:
  /// **'No schedule for this day.'**
  String get planNoScheduleDay;

  /// No description provided for @planDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Plan?'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your study plan and all progress.'**
  String get planDeleteBody;

  /// No description provided for @planDaysUntilExam.
  ///
  /// In en, this message translates to:
  /// **'{days} days until exam'**
  String planDaysUntilExam(int days);

  /// No description provided for @planExamDay.
  ///
  /// In en, this message translates to:
  /// **'Exam day!'**
  String get planExamDay;

  /// No description provided for @planTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} tasks'**
  String planTasksCount(int completed, int total);

  /// No description provided for @planHoursTotal.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours total'**
  String planHoursTotal(String hours);

  /// No description provided for @planMinPerDay.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min/day'**
  String planMinPerDay(int minutes);

  /// No description provided for @planMoreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String planMoreCount(int count);

  /// No description provided for @planExamDate.
  ///
  /// In en, this message translates to:
  /// **'Exam: {date}'**
  String planExamDate(String date);

  /// No description provided for @taskResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get taskResume;

  /// No description provided for @taskStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get taskStart;

  /// No description provided for @taskMinShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String taskMinShort(int minutes);

  /// No description provided for @planRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get planRestDay;

  /// No description provided for @planRestDayMsg.
  ///
  /// In en, this message translates to:
  /// **'Take a break and recharge for tomorrow!'**
  String get planRestDayMsg;

  /// No description provided for @planNoTasksDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for this day.'**
  String get planNoTasksDay;

  /// No description provided for @planTasksMinShort.
  ///
  /// In en, this message translates to:
  /// **'{tasks} Tasks · {minutes} min'**
  String planTasksMinShort(int tasks, int minutes);

  /// No description provided for @planTasksDone.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String planTasksDone(int completed, int total);

  /// No description provided for @timerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPause;

  /// No description provided for @timerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get timerResume;

  /// No description provided for @timerFinishEarly.
  ///
  /// In en, this message translates to:
  /// **'Finish Early'**
  String get timerFinishEarly;

  /// No description provided for @timerElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed: {time}'**
  String timerElapsed(String time);

  /// No description provided for @completionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get completionTitle;

  /// No description provided for @completionBody.
  ///
  /// In en, this message translates to:
  /// **'You studied {subject} — {topic} for {minutes} minutes.'**
  String completionBody(String subject, String topic, int minutes);

  /// No description provided for @completionPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned: {minutes} min'**
  String completionPlanned(int minutes);

  /// No description provided for @completionActual.
  ///
  /// In en, this message translates to:
  /// **'Actual: {minutes} min'**
  String completionActual(int minutes);

  /// No description provided for @completionAddTen.
  ///
  /// In en, this message translates to:
  /// **'+10 Minutes'**
  String get completionAddTen;

  /// No description provided for @completionMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get completionMarkDone;

  /// No description provided for @practiceExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Exam?'**
  String get practiceExamTitle;

  /// No description provided for @practiceExamBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to take a practice exam on {topic}?'**
  String practiceExamBody(String topic);

  /// No description provided for @practiceMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get practiceMaybeLater;

  /// No description provided for @practiceYesGo.
  ///
  /// In en, this message translates to:
  /// **'Yes, Let\'s Go!'**
  String get practiceYesGo;

  /// No description provided for @pickerSelectWeak.
  ///
  /// In en, this message translates to:
  /// **'Select Weak Subjects'**
  String get pickerSelectWeak;

  /// No description provided for @pickerSelectWeakDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose subjects you want to focus on. You can also add your own.'**
  String get pickerSelectWeakDesc;

  /// No description provided for @pickerAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom subject...'**
  String get pickerAddCustom;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
