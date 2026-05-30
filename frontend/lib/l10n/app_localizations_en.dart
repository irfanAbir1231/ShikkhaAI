// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ShikkhaAI';

  @override
  String get navHome => 'Home';

  @override
  String get navStudy => 'Study';

  @override
  String get navExam => 'Exam';

  @override
  String get navTopics => 'Topics';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlan => 'Plan';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSeeAll => 'See All';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSystemDefault => 'System Default';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBangla => 'বাংলা';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsLogOutSubtitle => 'Sign out and return to login';

  @override
  String get settingsLogOutConfirmTitle => 'Log Out?';

  @override
  String get settingsLogOutConfirmBody => 'Are you sure you want to log out?';

  @override
  String get settingsResetOnboarding => 'Reset Onboarding';

  @override
  String get settingsResetOnboardingSubtitle =>
      'Clear all local data and restart setup';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version 1.0.0';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerStudyCompanion => 'Study Companion';

  @override
  String get drawerSmartExam => 'Smart Exam';

  @override
  String get drawerStudyPlan => 'Study Plan';

  @override
  String get drawerAnalytics => 'Analytics';

  @override
  String get drawerHelpFeedback => 'Help & Feedback';

  @override
  String get drawerGreeting => 'Hi, Student';

  @override
  String get drawerStreakTagline => 'Keep up the streak!';

  @override
  String get drawerFooter => 'ShikkhaAI · v1.0.0';

  @override
  String get splashTagline => 'AI-powered study companion';

  @override
  String get appVersionShort => 'v1.0.0';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardGetStarted => 'Get Started';

  @override
  String get onboard1Title => 'Smart Study Companion';

  @override
  String get onboard1Desc =>
      'Upload your textbooks and notes. ShikkhaAI reads, understands, and creates personalized study materials just for you.';

  @override
  String get onboard2Title => 'AI-Powered Exams';

  @override
  String get onboard2Desc =>
      'Generate custom exam questions from any chapter. Practice with instant feedback and detailed explanations.';

  @override
  String get onboard3Title => 'Track Your Progress';

  @override
  String get onboard3Desc =>
      'Visual dashboards, study plans, and performance analytics to help you improve consistently.';

  @override
  String get authValidateName => 'Please enter your name';

  @override
  String get authValidateNameShort => 'Name must be at least 2 characters';

  @override
  String get authValidateNameLong => 'Name must be less than 120 characters';

  @override
  String get authValidateEmail => 'Please enter your email';

  @override
  String get authValidateEmailInvalid => 'Please enter a valid email address';

  @override
  String get authValidatePassword => 'Please enter a password';

  @override
  String get authValidatePasswordShort =>
      'Password must be at least 6 characters';

  @override
  String get authWelcomeBack => 'Welcome Back';

  @override
  String get authCreateProfile => 'Create Your Profile';

  @override
  String get authLoginSubtitle => 'Sign in to continue your learning journey.';

  @override
  String get authRegisterSubtitle =>
      'Tell us a little about yourself so we can personalize your study experience.';

  @override
  String get authFullName => 'Full Name';

  @override
  String get authFullNameHint => 'Enter your full name';

  @override
  String get authEmailLabel => 'Email Address';

  @override
  String get authEmailHint => 'your.email@example.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authToggleToRegister => 'Don\'t have an account? Register';

  @override
  String get authToggleToLogin => 'Already have an account? Sign In';

  @override
  String get authSelectClass => 'Select Your Class';

  @override
  String get authSelectClassSubtitle =>
      'Choose your current class so we can tailor content to your curriculum.';

  @override
  String authSubjectsAvailable(int count) {
    return '$count subjects available';
  }

  @override
  String get authCompleteRegistration => 'Complete Registration';

  @override
  String get homeGreeting => 'Hello, Student 👋';

  @override
  String get homeSubtitle => 'Ready to learn something new today?';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeActionStudySubtitle => 'AI explanations';

  @override
  String get homeActionExamSubtitle => 'Adaptive quiz';

  @override
  String get homeActionAnalyticsSubtitle => 'Track weaknesses';

  @override
  String get homeActionPlanSubtitle => 'Plan your week';

  @override
  String get homeContinueWithAi => 'Continue with AI';

  @override
  String get homeHeroSubtitle => 'Ask anything · get instant clarity';

  @override
  String get homeTodaysFocus => 'Today\'s Focus';

  @override
  String get homePracticeNow => 'Practice Now';

  @override
  String homeAccuracyPercent(String percent) {
    return '$percent% accuracy';
  }

  @override
  String get homeAllCaughtUp => 'All Caught Up!';

  @override
  String get homeAllCaughtUpSubtitle =>
      'No weak topics right now. Keep up the great work!';

  @override
  String get dashboardTitle => 'Analytics';

  @override
  String get dashboardLoadFailed => 'Failed to load dashboard';

  @override
  String get dashReadinessScore => 'Readiness Score';

  @override
  String get dashOutOf100 => 'OUT OF 100';

  @override
  String dashDayStreak(int count) {
    return '$count Day Streak';
  }

  @override
  String dashLongestStreak(int count) {
    return 'Longest: $count days';
  }

  @override
  String get dashWeekdayInitials => 'M,T,W,T,F,S,S';

  @override
  String get dashAiRecommendations => 'AI Recommendations';

  @override
  String get priorityHigh => 'HIGH';

  @override
  String get priorityMedium => 'MED';

  @override
  String get priorityLow => 'LOW';

  @override
  String get dashImprovementOverTime => 'Improvement Over Time';

  @override
  String get dashTopicAccuracy => 'Topic Accuracy';

  @override
  String get dashRecentQuizzes => 'Recent Quizzes';

  @override
  String get dashViewAll => 'View All';

  @override
  String get dashWeakSubjects => 'Weak Subjects';

  @override
  String dashQuestionsCount(int count) {
    return '($count Qs)';
  }

  @override
  String get analyticsTitle => 'Weakness Analytics';

  @override
  String get analyticsAvgAccuracy => 'Avg Accuracy';

  @override
  String get analyticsWeakChapters => 'Weak Chapters';

  @override
  String get analyticsDayStreakLabel => 'Day Streak';

  @override
  String get analyticsLoading => 'Loading analytics...';

  @override
  String get analyticsLoadFailed => 'Failed to load analytics';

  @override
  String get analyticsReadyToImprove => 'Ready to improve?';

  @override
  String analyticsWeakTopicsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weak topics waiting in the Exam tab.',
      one: '1 weak topic waiting in the Exam tab.',
    );
    return '$_temp0';
  }

  @override
  String get analyticsLast7Days => 'Last 7 Days';

  @override
  String get analyticsLast30Days => 'Last 30 Days';

  @override
  String get analyticsLast90Days => 'Last 90 Days';

  @override
  String get heatmapTitle => 'Performance Heatmap';

  @override
  String get heatmapNoActivity => 'No Activity Yet';

  @override
  String get heatmapNoActivityDesc =>
      'Complete your first quiz to start tracking daily performance.';

  @override
  String get heatmapNoActivityDay => 'No activity';

  @override
  String get legendHigh => 'High';

  @override
  String get legendMid => 'Mid';

  @override
  String get legendLow => 'Low';

  @override
  String get legendNone => 'None';

  @override
  String get analyticsWeekdayInitialsSun => 'S,M,T,W,T,F,S';

  @override
  String get streakDailyStreak => 'Daily Streak';

  @override
  String streakDaysShort(int count) {
    return '$count days';
  }

  @override
  String get streakCurrent => 'Current';

  @override
  String get streakBest => 'Best';

  @override
  String get streakActive => 'Active';

  @override
  String get radarTitle => 'Topic Accuracy Radar';

  @override
  String get radarYourScore => 'Your Score';

  @override
  String get radarBenchmark => 'Benchmark';

  @override
  String get radarNotEnough => 'Not Enough Data';

  @override
  String get radarNotEnoughDesc =>
      'Attempt questions in at least 3 different topics to see your accuracy radar.';

  @override
  String get practiceTitle => 'Personalized Practice';

  @override
  String get practiceNoteUnavailable => 'Study note not available yet';

  @override
  String get practiceSavedToLibrary => 'Saved to Library';

  @override
  String get practiceSaveAsNote => 'Save as note';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String impactPercent(String percent) {
    return '$percent% impact';
  }

  @override
  String get weakChaptersDetected => 'Weak Chapters Detected';

  @override
  String minutesSpent(int count) {
    return '$count min spent';
  }

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffMedium => 'Medium';

  @override
  String get diffHard => 'Hard';

  @override
  String get examTypePractice => 'Practice';

  @override
  String get examTypeSsc => 'SSC';

  @override
  String get examTypeHsc => 'HSC';

  @override
  String get examTypePracticeSubtitle => 'Customizable quick exam';

  @override
  String get examTypeSscSubtitle => 'SSC Board Exam Style';

  @override
  String get examTypeHscSubtitle => 'HSC Board Exam Style';

  @override
  String get qTypeMcq => 'MCQ';

  @override
  String get qTypeShortAnswer => 'Short Answer';

  @override
  String get qTypeCq => 'CQ';

  @override
  String get examConfigTitle => 'Configure Exam';

  @override
  String get examSubject => 'Subject';

  @override
  String get examTopic => 'Topic';

  @override
  String get examTopicHint => 'e.g., Photosynthesis, Newton\'s Laws';

  @override
  String get examClassLevel => 'Class Level';

  @override
  String examClassN(String level) {
    return 'Class $level';
  }

  @override
  String get examDifficulty => 'Difficulty';

  @override
  String get examExamType => 'Exam Type';

  @override
  String get examNumQuestions => 'Number of Questions';

  @override
  String get examTimeLimit => 'Time Limit';

  @override
  String get examPreview => 'Exam Preview';

  @override
  String get examRowClass => 'Class';

  @override
  String get examRowType => 'Type';

  @override
  String get examRowQuestions => 'Questions';

  @override
  String get examRowTime => 'Time';

  @override
  String get examTotalMarks => 'Total Marks';

  @override
  String get examGenerating => 'Generating...';

  @override
  String get examStart => 'Start Exam';

  @override
  String examStartFailed(String error) {
    return 'Failed to start exam: $error';
  }

  @override
  String get examFocusWeakTopics => 'Focus on Weak Topics';

  @override
  String get examRecentExams => 'Recent Exams';

  @override
  String get examNoExamsTitle => 'No Exams Yet';

  @override
  String get examNoExamsMsg =>
      'Generate your first AI-powered exam and start practicing.';

  @override
  String get examNewExam => 'New Exam';

  @override
  String get examPracticeChip => 'Practice';

  @override
  String get examStatExams => 'Exams';

  @override
  String get examStatAvgScore => 'Avg Score';

  @override
  String get examStatBest => 'Best';

  @override
  String get examStartNewTitle => 'Start a New Exam';

  @override
  String get examStartNewSubtitle =>
      'Practice with MCQ, CQ, and Short Answer questions tailored to your level.';

  @override
  String get examSubmitTitle => 'Submit Exam?';

  @override
  String examSubmitBody(int answered, int total) {
    return 'You have answered $answered out of $total questions. Are you sure you want to submit?';
  }

  @override
  String get commonSubmit => 'Submit';

  @override
  String get examNoQuestions => 'No questions available';

  @override
  String get examPrevious => 'Previous';

  @override
  String get examHideAnswer => 'Hide Answer';

  @override
  String get examCheckAnswer => 'Check Answer';

  @override
  String get examExplanation => 'Explanation';

  @override
  String examCorrectAnswerInline(String answer) {
    return 'Correct Answer: $answer';
  }

  @override
  String get examSubmissionFailedNoResult =>
      'Submission failed: no result received';

  @override
  String examSubmissionFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get examHistoryTitle => 'Exam History';

  @override
  String get examNoHistoryTitle => 'No History';

  @override
  String get examNoHistoryMsg => 'Your completed exams will appear here.';

  @override
  String get examClearHistoryTitle => 'Clear All History?';

  @override
  String get examClearHistoryBody =>
      'This will permanently delete all exam results. This action cannot be undone.';

  @override
  String get examClearAll => 'Clear All';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get examResultTitle => 'Exam Result';

  @override
  String get examResultNotFound => 'Result not found';

  @override
  String get examGoHome => 'Go Home';

  @override
  String get examHome => 'Home';

  @override
  String get examStudyNotesGenerated => 'Study Notes Generated';

  @override
  String get examStudyNotesSubtitle =>
      'Tap a topic below to review your personalised study notes.';

  @override
  String get examAnswerReviewUnavailable =>
      'Answer review not available for this attempt.';

  @override
  String examSomeAnswersMissing(int answered, int total) {
    return 'Some answers may not be displayed ($answered/$total saved locally).';
  }

  @override
  String qCardQuestionXofY(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String qCardMarks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Marks',
      one: '1 Mark',
    );
    return '$_temp0';
  }

  @override
  String progressAnswered(int count) {
    return '$count Answered';
  }

  @override
  String progressMarked(int count) {
    return '$count Marked';
  }

  @override
  String progressLeft(int count) {
    return '$count Left';
  }

  @override
  String get badgeAdaptive => 'Adaptive';

  @override
  String get shortAnswerHint => 'Type your answer here...';

  @override
  String cqAnswerHint(String part) {
    return 'Answer for $part';
  }

  @override
  String get answerReviewTitle => 'Answer Review';

  @override
  String get answerYourAnswer => 'Your Answer:';

  @override
  String get answerNotAnswered => 'Not answered';

  @override
  String get answerCorrectAnswer => 'Correct Answer:';

  @override
  String get answerMarks => 'Marks:';

  @override
  String qPrefix(int index, String prompt) {
    return 'Q$index: $prompt';
  }

  @override
  String get marksPrediction => 'Marks Prediction';

  @override
  String examConfidenceBadge(String level) {
    return '$level Confidence';
  }

  @override
  String examReadinessBadge(String value) {
    return 'Readiness: $value%';
  }

  @override
  String get marksPredictionDesc =>
      'Based on your current performance and consistency across topics.';

  @override
  String get summaryMarksObtained => 'Marks Obtained';

  @override
  String get summaryMcq => 'MCQ';

  @override
  String get summaryTime => 'Time';

  @override
  String get summaryGrade => 'Grade';

  @override
  String get weakGreatJob => 'Great job!';

  @override
  String get weakNoWeakTopics =>
      'No weak topics detected. Keep up the good work!';

  @override
  String get weakTopicsToReview => 'Topics to Review';

  @override
  String get scModeEasyBengaliLabel => 'Easy Bengali';

  @override
  String get scModeEasyBengaliSubtitle => 'সহজ বাংলায় বুঝুন';

  @override
  String get scModeEasyEnglishLabel => 'Easy English';

  @override
  String get scModeEasyEnglishSubtitle => 'Simple English';

  @override
  String get scModeExplain10Label => 'Explain Like I\'m 10';

  @override
  String get scModeExplain10Subtitle => 'Super simple!';

  @override
  String get scModeSummaryLabel => 'Summary';

  @override
  String get scModeSummarySubtitle => 'Quick overview';

  @override
  String get scModeImportantQLabel => 'Important Questions';

  @override
  String get scModeImportantQSubtitle => 'Key exam questions';

  @override
  String get scModeCommonMistakesLabel => 'Common Mistakes';

  @override
  String get scModeCommonMistakesSubtitle => 'Avoid errors';

  @override
  String get scModeExamTipsLabel => 'Exam Tips';

  @override
  String get scModeExamTipsSubtitle => 'Score higher';

  @override
  String get scTitle => 'AI Study Companion';

  @override
  String get scNewChat => 'New Chat';

  @override
  String get scStudyMode => 'Study Mode';

  @override
  String get scWelcomeTagline => 'Your personal tutor, always ready';

  @override
  String get scWelcomeQuestion => 'What would you like to learn?';

  @override
  String get scWelcomeSubtitle =>
      'Upload a chapter or ask a question. Choose an explanation mode below.';

  @override
  String get scQuickStart => 'Quick Start';

  @override
  String get scSuggestion1 => 'Explain Photosynthesis';

  @override
  String get scSuggestion2 => 'Important questions from Chapter 3';

  @override
  String get scSuggestion3 => 'Common mistakes in algebra';

  @override
  String get scSuggestion4 => 'Exam tips for Biology';

  @override
  String get scSuggestion5 => 'Summary of Newton\'s Laws';

  @override
  String get scChatHistory => 'Chat History';

  @override
  String scConversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations',
      one: '1 conversation',
    );
    return '$_temp0';
  }

  @override
  String get scClearHistoryTitle => 'Clear all history?';

  @override
  String get scClearHistoryBody =>
      'This will permanently delete all your chat sessions.';

  @override
  String get commonClear => 'Clear';

  @override
  String get scNoConversations => 'No conversations yet';

  @override
  String get scStartNewChat => 'Start a new chat to begin learning!';

  @override
  String scMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get scInputHint => 'Ask anything about your studies...';

  @override
  String scFilePickError(String error) {
    return 'Could not pick file: $error';
  }

  @override
  String get scAiExplanation => 'AI Explanation';

  @override
  String get scAiNote => 'AI Note';

  @override
  String get scCrossReferenced => 'Cross-referenced with Class 8 Science';

  @override
  String get scSourceDefault => 'Source';

  @override
  String scSourcePage(String source, String page) {
    return '$source — Page $page';
  }

  @override
  String get taskReading => 'Reading';

  @override
  String get taskPractice => 'Practice';

  @override
  String get taskRevision => 'Revision';

  @override
  String get taskMockTest => 'Mock Test';

  @override
  String get taskRest => 'Rest';

  @override
  String get planDefaultTitle => 'Study Plan';

  @override
  String get planOtherPlans => 'Other Plans';

  @override
  String get planCreateNew => 'Create New Plan';

  @override
  String get planNoPlansTitle => 'No Study Plan Yet';

  @override
  String get planNoPlansMsg =>
      'Create a personalized study plan to track your progress and stay on schedule.';

  @override
  String get planCreatePlan => 'Create Study Plan';

  @override
  String get planTodaysSchedule => 'Today\'s Schedule';

  @override
  String planTasksMinutes(int tasks, int minutes) {
    return '$tasks tasks · $minutes minutes';
  }

  @override
  String get planToday => 'Today';

  @override
  String get planCreateTitle => 'Create Study Plan';

  @override
  String get planGenerate => 'Generate Plan';

  @override
  String get planWhenExam => 'When is your exam?';

  @override
  String get planWhenExamDesc =>
      'We\'ll create a schedule that leads up to your exam date.';

  @override
  String get planDaysLeftStacked => 'days\nleft';

  @override
  String get planChangeDate => 'Change Date';

  @override
  String get planDailyTimeQuestion => 'How much time can you\nstudy daily?';

  @override
  String get planDailyTimeDesc =>
      'We\'ll distribute your subjects across available time.';

  @override
  String planMinutesPerDay(int minutes) {
    return '$minutes minutes per day';
  }

  @override
  String get planStudyDuration => 'Study Duration';

  @override
  String planDaysValue(int days) {
    return '$days days';
  }

  @override
  String get planDailyStudyTime => 'Daily Study Time';

  @override
  String get planTotalStudyHours => 'Total Study Hours';

  @override
  String planHoursValue(String hours) {
    return '$hours hours';
  }

  @override
  String get planSubjectsLabel => 'Subjects';

  @override
  String get planGeneralStudy => 'General Study';

  @override
  String get planDetailTitle => 'Plan Detail';

  @override
  String get planNoScheduleDay => 'No schedule for this day.';

  @override
  String get planDeleteTitle => 'Delete Plan?';

  @override
  String get planDeleteBody =>
      'This will permanently delete your study plan and all progress.';

  @override
  String planDaysUntilExam(int days) {
    return '$days days until exam';
  }

  @override
  String get planExamDay => 'Exam day!';

  @override
  String planTasksCount(int completed, int total) {
    return '$completed/$total tasks';
  }

  @override
  String planHoursTotal(String hours) {
    return '$hours hours total';
  }

  @override
  String planMinPerDay(int minutes) {
    return '$minutes min/day';
  }

  @override
  String planMoreCount(int count) {
    return '+$count more';
  }

  @override
  String planExamDate(String date) {
    return 'Exam: $date';
  }

  @override
  String get taskResume => 'Resume';

  @override
  String get taskStart => 'Start';

  @override
  String taskMinShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String get planRestDay => 'Rest Day';

  @override
  String get planRestDayMsg => 'Take a break and recharge for tomorrow!';

  @override
  String get planNoTasksDay => 'No tasks scheduled for this day.';

  @override
  String planTasksMinShort(int tasks, int minutes) {
    return '$tasks Tasks · $minutes min';
  }

  @override
  String planTasksDone(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String get timerPause => 'Pause';

  @override
  String get timerResume => 'Resume';

  @override
  String get timerFinishEarly => 'Finish Early';

  @override
  String timerElapsed(String time) {
    return 'Elapsed: $time';
  }

  @override
  String get completionTitle => 'Session Complete!';

  @override
  String completionBody(String subject, String topic, int minutes) {
    return 'You studied $subject — $topic for $minutes minutes.';
  }

  @override
  String completionPlanned(int minutes) {
    return 'Planned: $minutes min';
  }

  @override
  String completionActual(int minutes) {
    return 'Actual: $minutes min';
  }

  @override
  String get completionAddTen => '+10 Minutes';

  @override
  String get completionMarkDone => 'Mark as Done';

  @override
  String get practiceExamTitle => 'Practice Exam?';

  @override
  String practiceExamBody(String topic) {
    return 'Would you like to take a practice exam on $topic?';
  }

  @override
  String get practiceMaybeLater => 'Maybe Later';

  @override
  String get practiceYesGo => 'Yes, Let\'s Go!';

  @override
  String get pickerSelectWeak => 'Select Weak Subjects';

  @override
  String get pickerSelectWeakDesc =>
      'Choose subjects you want to focus on. You can also add your own.';

  @override
  String get pickerAddCustom => 'Add custom subject...';
}
