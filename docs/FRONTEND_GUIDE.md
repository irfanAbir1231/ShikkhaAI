# Frontend Completion Guide

## Overview

The ShikkhaAI frontend is a **cross-platform Flutter application** built with:

- **Flutter** (Dart SDK ^3.9.2)
- **Riverpod** for state management
- **GoRouter** for navigation
- **Dio** for HTTP networking
- **Hive** for local persistence
- **fl_chart** for data visualization

The app follows a **feature-first clean architecture** with atomic-design widgets.

---

## Current State

### ✅ Fully Implemented Features

| Feature | Backend API? | Notes |
|---------|-------------|-------|
| **Auth (Onboarding → Registration → Login)** | ✅ Yes | Calls `POST /student/register` and `POST /student/login`, persists student + JWT token to Hive. Dual-mode login/register screen. |
| **Exam (Config → Session → Result → History)** | ✅ Yes | Full lifecycle with timer, navigation grid, review. Calls `POST /exam/generate` and `POST /exam/submit` with Bearer token auth |
| **Dashboard** | ✅ Yes | Calls `GET /student/{id}/dashboard`. Shows readiness, weak subjects, streak, recent quizzes, recommendations from real attempt data |
| **Analytics (Weakness)** | ✅ Yes | Calls `GET /student/{id}/analytics`. Shows topic accuracy, weak chapters, improvement history, streak calendar, practice suggestions |
| **Topics** | ✅ Yes | Calls `GET /student/{id}/topics`. Shows curriculum topics grouped by subject with completion percentages (falls back to attempt history if no curriculum seeded) |
| **Library / Notes** | ✅ Yes | Calls `POST /notes`, `GET /notes`, `DELETE /notes/{id}`. Offline-first with Hive local cache. Auto-populated with AI-generated notes after exam submission |
| **Settings** | ❌ No (local only) | Theme toggle, reset onboarding, logout. Persists to Hive |
| **Splash / Onboarding** | ❌ No (local only) | Animated splash, 3-page onboarding with `PageView` |
| **HomeScreen Quick Actions** | ✅ Wired | Study Companion, Smart Exam, Handwritten Eval, Analytics cards all have working `onTap` handlers |

### 🎨 UI-Complete But Mock-Data Features

| Feature | Backend API? | Notes |
|---------|-------------|-------|
| **Study Companion (Chat)** | ❌ No | Full chat UI with 7 explanation modes + file attachment (PDF picker). Returns **same photosynthesis text** for every query. File content is never sent anywhere. |
| **Study Plan** | ❌ No | Calendar view, task completion, per-task timer with '+10 min' extension, practice exam integration. Weak topics auto-suggested from analytics. Uses `MockStudyPlanService` for local generation. **Models already have `toJson`/`fromJson`.** |

### ⚠️ Partial / Shell Features

| Feature | Status | Notes |
|---------|--------|-------|
| **Upload (Handwritten)** | ⚠️ Partial | Image picker → preview → mock OCR evaluation. Works end-to-end but with fake scoring |
| **Upload (PDF)** | 🚧 Shell | CTA card has `onTap: () {}` — completely non-functional |
| **Library (Quizzes tab)** | 🚧 Shell | Quizzes tab is still an `EmptyState` placeholder. Saved quizzes feature not yet built |

### ❌ Missing / Broken

| Issue | Impact |
|-------|--------|
| Study Companion, Study Plan use mock services | These features do not reflect real student data |
| No offline sync queue | `syncQueueBox` is defined but never used |
| No tests | Only default `widget_test.dart` exists |

---

## Testing the Frontend — Complete User Flow

Use this guide to verify the frontend is working correctly end-to-end.

### Prerequisites

1. **Backend is running** on `http://127.0.0.1:8000` (or your configured `API_BASE_URL`)
2. **Frontend compiles** without errors:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
3. **Backend `.env`**: Set `MOCK_MODE=true` for zero-setup testing (no RAG service needed)

---

### Test Flow 1: Fresh Install → Onboarding → Registration → Exam

This simulates a brand-new user installing the app for the first time.

| Step | Screen | What to Do | Expected Result |
|------|--------|-----------|-----------------|
| 1 | **Splash** | Wait 2 seconds | App shows animated ShikkhaAI logo, then auto-navigates |
| 2 | **Onboarding** | Swipe through 3 pages | Pages show "Personalized Learning", "AI Exam Generator", "Track Progress". Tap **Get Started** on page 3 |
| 3 | **Registration** | Fill the form: Name, Email, Password (min 6 chars). Tap **Continue** | No validation errors. Navigates to Class Selection |
| 4 | **Class Selection** | Pick a class (e.g., "Class 8"). Tap **Complete Profile** | Shows loading spinner. On success, navigates to **Home** |
| 5 | **Home** | Verify bottom nav has 5 tabs: Home, Study, Exam, Upload, Library | Home tab shows greeting with student's name, quick-action cards |
| 6 | **Exam Config** | Tap **Smart Exam** card (or bottom nav → Exam → tap "Start New Exam"). Configure: Subject=Science, Topic=Photosynthesis, Difficulty=Medium, Questions=5. Tap **Start Exam** | Navigates to Exam Session with loading, then questions appear |
| 7 | **Exam Session** | Answer MCQs (tap options). Use bottom grid to jump between questions. Tap **Submit** when done | Shows confirmation dialog. On confirm, submits to backend |
| 8 | **Exam Result** | View score, weak topics, readiness score, per-question breakdown | Data loads from backend attempt response |
| 9 | **Exam History** | Tap bottom nav → Exam → History tab | Lists past attempts with scores and dates |
| 10 | **Settings** | Tap bottom nav → More (Settings). Tap **Logout** | Returns to Login screen. Token and student data cleared from Hive |

**Verification checklist:**
- [ ] Onboarding only shows on first launch (after that, splash goes straight to login/home)
- [ ] Registration form validates email format and password length
- [ ] Class Selection sends `POST /student/register` with Bearer token returned
- [ ] Home screen greeting shows the registered student's name
- [ ] Exam generation calls `POST /exam/generate` with `Authorization: Bearer <token>` header
- [ ] Exam submission calls `POST /exam/submit` with the same auth header
- [ ] Exam history calls `GET /student/{id}/attempts` with auth header
- [ ] Dashboard calls `GET /student/{id}/dashboard` and loads real data after at least one exam
- [ ] Analytics calls `GET /student/{id}/analytics` and shows real weak topics
- [ ] Topics tab calls `GET /student/{id}/topics` and shows curriculum or fallback
- [ ] Library shows AI-generated notes after exam submission (auto-created for weak topics)
- [ ] Logout clears token from Hive; subsequent app restarts go to login screen

---

### Test Flow 2: Returning User → Login → Exam

This simulates a user who already has an account.

| Step | Screen | What to Do | Expected Result |
|------|--------|-----------|-----------------|
| 1 | **Splash** | Wait | Navigates to **Login** (because onboarding was already completed) |
| 2 | **Login/Register** | Tap **"Already have an account? Sign In"** toggle | Form switches to login mode (Name field hidden, title changes to "Welcome Back") |
| 3 | **Login** | Enter email and password from previous registration. Tap **Sign In** | Shows loading. On success, navigates to **Home** |
| 4 | **Home** | Verify name appears in greeting | Same account data loaded |
| 5 | **Exam** | Start and complete another exam | New attempt appears in History |

**Verification checklist:**
- [ ] Login mode toggle works correctly
- [ ] `POST /student/login` returns `access_token`
- [ ] Token is saved to Hive `settings` box under `auth_token` key
- [ ] All subsequent API calls include `Authorization: Bearer <token>`
- [ ] Wrong password shows error SnackBar
- [ ] Non-existent email shows error SnackBar

---

### Test Flow 3: Auth Guard & Route Protection

Verify unauthenticated users cannot access protected screens.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Kill app, clear data (or use "Reset Onboarding" in Settings) | Hive data wiped |
| 2 | Restart app | Splash → Onboarding → Login |
| 3 | Try to manually navigate to `/home` (deep link or hot restart) | Redirected back to Login screen |
| 4 | Try to navigate to `/exam/config` | Redirected back to Login screen |
| 5 | Complete login | All routes now accessible |

---

### Test Flow 4: Settings & Data Reset

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Settings | Shows "Reset Onboarding" and "Logout" options |
| 2 | Tap **Logout** | Student data + auth token cleared. App navigates to Login |
| 3 | Restart app | Goes to Login (onboarding was already done) |
| 4 | Log back in | All previous exam history still visible (stored in backend DB) |
| 5 | Tap **Reset Onboarding** | Onboarding flag + student + token all cleared. Restart shows onboarding again |

---

### Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| `Connection refused` on Android emulator | Emulator localhost is `10.0.2.2`, not `127.0.0.1` | Check `API_BASE_URL` is `http://10.0.2.2:8000` in `dio_client.dart` |
| `401 AUTH_REQUIRED` | Token missing or expired | Log out and log back in to get a fresh token |
| `403 FORBIDDEN` | Token belongs to a different student | Each student can only access their own data. Use the correct account |
| Exam questions don't load | Backend not running or `MOCK_MODE` issue | Verify backend is up at `http://127.0.0.1:8000/health` |
| Registration fails with `STUDENT_EMAIL_EXISTS` | Email already registered | Use a different email, or delete `backend/shikkhaai.db` to reset |

---

## Step-by-Step Completion Plan

### Phase 1: Fix Bugs & Polish Existing Features ✅ Done

#### 1.1 Make Dashboard Refresh Actually Work ✅

The `RefreshIndicator.onRefresh` and Retry button in `_DashboardError` are now wired to invalidate and refetch `dashboardDataProvider`.

---

### Phase 2: Replace Mock Services with Real API Calls ✅ Partially Done

The following features are now wired to real backend APIs:

- ✅ **Dashboard** → `GET /student/{id}/dashboard`
- ✅ **Analytics** → `GET /student/{id}/analytics`
- ✅ **Topics** → `GET /student/{id}/topics`
- ✅ **Notes / Library** → `POST /notes`, `GET /notes`, `DELETE /notes/{id}`

The following features still use mock services and need future integration:

- 🎨 **Study Companion** → needs `POST /study-companion/ask` (RAG-powered)
- 🎨 **Study Plan** → needs `POST /study-plan/generate`

#### 2.1 Dashboard → Real Backend Integration ✅ Done

**File:** `frontend/lib/features/dashboard/presentation/providers/dashboard_provider.dart`

Now uses `DashboardRemoteDataSource().fetchDashboard(student.id)` instead of `MockDashboardService`.

#### 2.2 Analytics → Real Backend Integration ✅ Done

**File:** `frontend/lib/features/analytics/domain/repositories/analytics_repository.dart`

Now uses `AnalyticsRemoteDataSource().fetchAnalytics(studentId)` instead of `MockAnalyticsService`.

#### 2.3 Topics → Real Backend Integration ✅ Done

**File:** `frontend/lib/features/topics/presentation/providers/topics_provider.dart`

Now injects `TopicsRemoteDataSource` into `TopicsRepository`, enabling real API calls with local cache fallback.

#### 2.3 Analytics — Wire Up "Practice Now" Buttons

**User requirement:** When a student sees a weak chapter, tapping "Practice Now" should generate a quiz on that topic.

**File:** `frontend/lib/features/analytics/presentation/widgets/weak_chapters_list.dart`

In `_WeakChapterCard`, replace the empty `onPressed`:

```dart
SizedBox(
  width: double.infinity,
  height: 40,
  child: OutlinedButton.icon(
    onPressed: () {
      // Navigate to exam config pre-filled with this weak chapter
      context.push('/exam/config', extra: {
        'subject': chapter.subject,
        'topic': chapter.chapterName,
        'difficulty': 'easy', // start easy for weak topics
      });
    },
    icon: const Icon(Icons.play_arrow_rounded, size: 18),
    label: const Text('Practice Now'),
    ...
  ),
)
```

**File:** `frontend/lib/features/exam/presentation/screens/exam_config_screen.dart`

Accept optional pre-filled values from navigation `extra` and populate the form fields.

**Backend:** The existing `POST /exam/generate` already supports topic-specific generation. If you want a dedicated practice endpoint, use `POST /practice/generate` (see Backend Guide).

#### 2.4 Analytics — Wire Up Practice Suggestions

**User requirement:** The "Personalized Practice" cards should show real AI-generated notes/suggestions for weak topics.

**Backend dependency:** Either:
- Include `practice_suggestions` inside `GET /student/{id}/analytics`, OR
- Add a dedicated `POST /study-companion/topic-notes` endpoint

**Frontend tasks:**

If using a dedicated endpoint, create:

**New file:** `frontend/lib/features/analytics/data/datasources/topic_notes_remote_datasource.dart`

```dart
class TopicNotesRemoteDataSource {
  final Dio _dio;
  TopicNotesRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> fetchTopicNotes({
    required int studentId,
    required String topic,
    required String subject,
    required String classLevel,
  }) async {
    final response = await _dio.post('/study-companion/topic-notes', data: {
      'student_id': studentId,
      'topic': topic,
      'subject': subject,
      'class_level': classLevel,
    });
    return response.data['data'];
  }
}
```

If suggestions are returned as part of analytics, no extra frontend work is needed beyond switching to the real `AnalyticsRemoteDataSource`.

**5. Add "Save as Note" button to Practice Suggestion cards:**

**File:** `frontend/lib/features/analytics/presentation/widgets/practice_suggestions_card.dart`

Add a bookmark icon button to each `_SuggestionCard` (top-right, next to the type chip):

```dart
IconButton(
  icon: const Icon(Icons.bookmark_border, size: 18),
  onPressed: () {
    // Save this suggestion as a note
    ref.read(noteRepositoryProvider).saveNote(
      NoteModel(
        title: suggestion.title,
        content: '${suggestion.description}\n\n---\n**Topic:** ${suggestion.topic}\n**Estimated time:** ${suggestion.estimatedMinutes} min\n**Potential impact:** ${suggestion.potentialImpact.toStringAsFixed(0)}%',
        topic: suggestion.topic,
        subject: suggestion.subject,
        source: 'practice',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to Library')),
    );
  },
),
```

**Also:** When a user taps a suggestion card, navigate to a **Topic Notes** detail screen that calls `POST /study-companion/topic-notes` and displays the generated notes. That screen should ALSO have a "Save as Note" button for the full generated content.

#### 2.5 Study Companion → RAG-Powered Chat with PDF Cross-Reference

**Backend dependencies:**
- `POST /study-companion/ask` — RAG-powered Q&A (returns `response` + `sources`)
- `POST /upload/pdf` — Temporary PDF text extraction

**Goal:** Students can ask questions about the Class 8 Science book (already in RAG). They can also upload a PDF and ask questions that cross-reference the PDF with the book. Example: "solve the maths of this PDF" → answer uses formulas from the RAG book.

**Frontend tasks:**

**1. Update `ChatMessage` model to store sources:**

**File:** `frontend/lib/features/study_companion/data/models/chat_message_model.dart`

Add `sources` and `pdfContext` fields:

```dart
class ChatMessage {
  // ... existing fields ...
  final List<Map<String, dynamic>>? sources;  // RAG source citations
  final String? pdfContext;                    // Extracted text from uploaded PDF

  // Update toJson / fromJson / copyWith
}
```

**2. Create remote data sources:**

**New file:** `frontend/lib/features/study_companion/data/datasources/study_companion_remote_datasource.dart`

```dart
class StudyCompanionRemoteDataSource {
  final Dio _dio;
  StudyCompanionRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> sendMessage({
    required int studentId,
    required String message,
    required String mode,
    required String subject,
    required String classLevel,
    String? pdfContext,
  }) async {
    final response = await _dio.post('/study-companion/ask', data: {
      'student_id': studentId,
      'message': message,
      'mode': mode,
      'subject': subject,
      'class_level': classLevel,
      if (pdfContext != null) 'pdf_context': pdfContext,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}
```

**New file:** `frontend/lib/features/study_companion/data/datasources/pdf_upload_remote_datasource.dart`

```dart
class PdfUploadRemoteDataSource {
  final Dio _dio;
  PdfUploadRemoteDataSource(this._dio);

  Future<String> uploadAndExtractText(File file, String subject, String classLevel) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, contentType: MediaType('application', 'pdf')),
      'subject': subject,
      'class_level': classLevel,
    });
    final response = await _dio.post('/upload/pdf', data: formData);
    return response.data['data']['text'] as String;
  }
}
```

**3. Update repository:**

**File:** `frontend/lib/features/study_companion/data/repositories/study_companion_repository.dart`

- Replace `MockStudyCompanionService` with `StudyCompanionRemoteDataSource`.
- The repository currently returns `Stream<String>` for a typing effect. **Keep the stream** by splitting the full response into words client-side:

```dart
Stream<String> sendMessage({...}) async* {
  final result = await _remoteDataSource.sendMessage(...);
  final responseText = result['response'] as String;
  final words = responseText.split(' ');
  var buffer = '';
  for (final word in words) {
    buffer += '$word ';
    yield buffer.trim();
    await Future.delayed(const Duration(milliseconds: 30));
  }
}
```

**4. Wire PDF upload in the provider:**

**File:** `frontend/lib/features/study_companion/presentation/providers/study_companion_provider.dart`

When a user attaches a PDF via the existing file picker:

```dart
// Add a new provider for extracted PDF text
final pdfContextProvider = StateProvider<String?>((ref) => null);

// In CurrentChatNotifier, when file is attached:
Future<void> onPdfAttached(File file) async {
  // Show loading on the attachment chip
  // Call PdfUploadRemoteDataSource.uploadAndExtractText()
  // Store result in pdfContextProvider
  // On error: show SnackBar, clear attachment
}

// In sendMessage(), include pdfContext:
final pdfContext = ref.read(pdfContextProvider);
final result = await repository.sendMessage(
  ...,
  pdfContext: pdfContext,
);
// Clear pdfContextProvider after send (same as file attachment clear)
```

**5. Add source citations to AI bubbles:**

**File:** `frontend/lib/features/study_companion/presentation/widgets/chat_message_bubble.dart`

When `message.sources` is non-empty, show a row of small chips below the AI response:

```dart
if (message.sources != null && message.sources!.isNotEmpty)
  Wrap(
    spacing: 8,
    children: message.sources!.map((source) {
      return Chip(
        avatar: const Icon(Icons.menu_book, size: 16),
        label: Text('${source['source']} — Page ${source['page']}'),
        backgroundColor: AppColors.primary.withOpacity(0.1),
      );
    }).toList(),
  ),
```

Also show a "Cross-referenced with Class 8 Science" badge when `pdfContext` was used.

**6. Explanation mode is already wired — just send it:**

The `explanationModeProvider` already tracks the selected mode. Pass `mode.name` to the API:

```dart
final mode = ref.read(explanationModeProvider).name; // "easyEnglish", "easyBengali", etc.
```

No UI changes needed for the mode selector.

**7. Add "Save as Note" button to AI message bubbles:**

**File:** `frontend/lib/features/study_companion/presentation/widgets/chat_message_bubble.dart`

Add a bookmark icon at the bottom-right of `_AiBubble`, below the `MarkdownMessageCard`:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    if (message.sources != null && message.sources!.isNotEmpty)
      // Source chips (see step 5 above)
      ...
    const Spacer(),
    IconButton(
      icon: Icon(
        message.isSaved ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: AppColors.primary,
      ),
      onPressed: () {
        // Open a bottom sheet to confirm/edit title before saving
        showModalBottomSheet(
          context: context,
          builder: (_) => SaveNoteBottomSheet(
            defaultTitle: _generateTitleFromChat(message),
            content: message.content,
            topic: _inferTopicFromChat(message),
            onSave: (title, topic) {
              ref.read(noteRepositoryProvider).saveNote(
                NoteModel(
                  title: title,
                  content: message.content,
                  topic: topic,
                  subject: currentSubject, // from provider
                  classLevel: currentClassLevel,
                  source: 'study_companion',
                ),
              );
            },
          ),
        );
      },
    ),
  ],
),
```

**New file:** `frontend/lib/features/library/presentation/widgets/save_note_bottom_sheet.dart`

A simple bottom sheet with:
- `TextField` for title (pre-filled with auto-generated title)
- `TextField` for topic (pre-filled, editable)
- "Save" button → calls `noteRepository.saveNote()`
- "Cancel" button

Auto-title generation logic (heuristic):
- If `message.explanationMode` is set → `"${modeLabel} — ${firstUserMessageTopic}"`
- Otherwise → `"Note from ${firstUserMessageTopic}"`

#### 2.6 Study Plan → Real Backend Integration + Timer + Practice Exam Flow

**Backend dependency:** `POST /study-plan/generate`, `PUT /study-plan/tasks/{id}/progress` (optional)

This is a major feature expansion. The Study Plan already has beautiful UI (`PlanShellScreen`, `PlanDetailScreen`, `DailyScheduleTimeline`, `StudyCalendar`) but uses `MockStudyPlanService` for generation and lacks any timer or exam integration.

---

##### A. Weak Topic Suggestions (Already Implemented)

The `WeakSubjectPicker` widget (step 2 of `PlanCreateScreen`) already:
- Watches `analyticsSummaryProvider` for `weakChapters`
- Displays weak topics as selectable `FilterChip`s
- Falls back to hardcoded subjects (`Trigonometry`, `Chemical Bonding`, etc.) if analytics is empty
- Supports custom subject input via text field

**No changes needed** — this flow works end-to-end once Analytics is wired to the real backend.

---

##### B. Model Updates — Add Timer Fields to `StudyTask`

**File:** `frontend/lib/features/study_plan/data/models/study_plan_models.dart`

Extend `StudyTask` with timer tracking fields:

```dart
class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.type,
    this.isCompleted = false,
    required this.scheduledDate,
    this.actualMinutesSpent = 0,     // ← NEW
    this.startedAt,                   // ← NEW
    this.completedAt,                 // ← NEW
  });

  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final int durationMinutes;
  final TaskType type;
  final bool isCompleted;
  final DateTime scheduledDate;
  final int actualMinutesSpent;      // ← NEW: time recorded by timer
  final DateTime? startedAt;          // ← NEW: when user pressed Start
  final DateTime? completedAt;        // ← NEW: when user marked done

  // Update copyWith, toJson, fromJson with the new fields
  // Use defaults for backward compatibility:
  // actualMinutesSpent: json['actualMinutesSpent'] as int? ?? 0,
  // startedAt: json['startedAt'] != null ? DateTime.parse(...) : null,
  // completedAt: json['completedAt'] != null ? DateTime.parse(...) : null,
}
```

---

##### C. Timer Feature — New Widgets

**1. `StudyTimerWidget`** *(new file)*

**File:** `frontend/lib/features/study_plan/presentation/widgets/study_timer_widget.dart`

Adapted from `ExamTimer` but designed for study sessions. Full-screen or bottom-sheet modal.

```dart
class StudyTimerWidget extends ConsumerStatefulWidget {
  const StudyTimerWidget({
    super.key,
    required this.task,
    required this.onFinish,
    required.onAddTenMinutes,
  });

  final StudyTask task;
  final VoidCallback onFinish;
  final VoidCallback onAddTenMinutes;

  @override
  ConsumerState<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}
```

**Features:**
- Large countdown display (`MM:SS`) centered on screen
- Circular progress indicator around the timer
- Background color shifts: green → yellow → orange → red as time runs low
- Pause / Resume button (floating action button style)
- "Finish Early" button (always available)
- When timer reaches 0: auto-show `TaskCompletionDialog`
- Keeps screen awake using `wakelock_plus` package (optional)

**State:** Managed by `studyTimerProvider` (see Section E below).

---

**2. `TaskCompletionDialog`** *(new file)*

**File:** `frontend/lib/features/study_plan/presentation/widgets/task_completion_dialog.dart`

Shown when timer reaches 0 OR user taps "Finish Early".

```dart
class TaskCompletionDialog extends StatelessWidget {
  const TaskCompletionDialog({
    super.key,
    required this.task,
    required this.elapsedMinutes,
  });

  final StudyTask task;
  final int elapsedMinutes;
}
```

**UI:**
- Title: "Session Complete! 🎉"
- Body: "You studied **{subject} — {topic}** for **{elapsedMinutes} minutes**."
- Planned duration chip: "Planned: {durationMinutes} min"
- Three action buttons:
  - **"+10 Minutes"** (outlined) → extends timer, dialog dismisses, returns to timer
  - **"Mark as Done"** (elevated, primary) → marks complete, shows `PracticeExamPromptDialog`
  - **"Cancel"** (text) → dismisses, records partial time but does NOT mark complete

---

**3. `PracticeExamPromptDialog`** *(new file)*

**File:** `frontend/lib/features/study_plan/presentation/widgets/practice_exam_prompt_dialog.dart`

Shown after user taps "Mark as Done" in `TaskCompletionDialog`.

```dart
class PracticeExamPromptDialog extends StatelessWidget {
  const PracticeExamPromptDialog({
    super.key,
    required this.topic,
    required this.subject,
    required this.onYes,
    required this.onNo,
  });
}
```

**UI:**
- Title: "Practice Exam? 📚"
- Body: "Would you like to take a practice exam on **{topic}**?"
- Two action buttons:
  - **"Yes, Let's Go!"** (elevated, primary) → pre-fills exam config and navigates
  - **"Maybe Later"** (text) → dismisses

**Navigation handler:**
```dart
void _navigateToExamConfig(WidgetRef ref, StudyTask task, BuildContext context) {
  // Pre-fill the exam config provider with task's subject and topic
  ref.read(examConfigProvider.notifier).state =
      ref.read(examConfigProvider).copyWith(
        subject: task.subject,
        topic: task.topic,
        // Optional: set difficulty based on weakness level
      );
  context.push('${RouteNames.exam}/${RouteNames.examConfig}');
}
```

---

##### D. Task Card Update — Add "Start" Button

**Files to update:**
- `frontend/lib/features/study_plan/presentation/widgets/daily_schedule_timeline.dart` — `_TimelineItem`
- `frontend/lib/features/study_plan/presentation/widgets/study_task_card.dart` — `StudyTaskCard`

Replace the simple checkbox with a state-aware action widget:

```dart
// In _TimelineItem / StudyTaskCard:
Widget _buildTaskAction(StudyTask task, WidgetRef ref) {
  if (task.isCompleted) {
    // Show completion badge with actual time
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          '${task.actualMinutesSpent} min',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  if (task.startedAt != null) {
    // Task was started but not finished — show "Resume" or timer status
    return TextButton.icon(
      icon: const Icon(Icons.play_arrow, size: 16),
      label: const Text('Resume'),
      onPressed: () => _resumeTimer(context, ref, task),
    );
  }

  // Not started — show Start button
  return ElevatedButton.icon(
    icon: const Icon(Icons.play_arrow, size: 18),
    label: const Text('Start'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    onPressed: () => _startTimer(context, ref, task),
  );
}
```

Keep the checkbox as a **secondary manual override** (e.g., a small `IconButton` with `Icons.check_box_outline_blank` → `Icons.check_box` for quick marking without timer).

---

##### E. Timer State Management — `studyTimerProvider`

**New file:** `frontend/lib/features/study_plan/presentation/providers/study_timer_provider.dart`

```dart
@freezed
class StudyTimerState with _$StudyTimerState {
  const factory StudyTimerState.idle() = _Idle;
  const factory StudyTimerState.running({
    required StudyTask task,
    required int remainingSeconds,
    required int elapsedSeconds,
    required DateTime startedAt,
  }) = _Running;
  const factory StudyTimerState.paused({
    required StudyTask task,
    required int remainingSeconds,
    required int elapsedSeconds,
  }) = _Paused;
  const factory StudyTimerState.finished({
    required StudyTask task,
    required int totalElapsedSeconds,
  }) = _Finished;
}

class StudyTimerNotifier extends StateNotifier<StudyTimerState> {
  StudyTimerNotifier(this._ref) : super(const StudyTimerState.idle());

  final Ref _ref;
  Timer? _timer;

  void startTask(StudyTask task) {
    _timer?.cancel();
    state = StudyTimerState.running(
      task: task,
      remainingSeconds: task.durationMinutes * 60,
      elapsedSeconds: 0,
      startedAt: DateTime.now(),
    );
    _startTicking();
  }

  void pause() { /* transition to Paused, cancel timer */ }
  void resume() { /* transition to Running, resume timer */ }

  void addTenMinutes() {
    state.whenOrNull(
      running: (task, remaining, elapsed, startedAt) {
        state = StudyTimerState.running(
          task: task,
          remainingSeconds: remaining + 600, // +10 min
          elapsedSeconds: elapsed,
          startedAt: startedAt,
        );
      },
      paused: (task, remaining, elapsed) {
        state = StudyTimerState.paused(
          task: task,
          remainingSeconds: remaining + 600,
          elapsedSeconds: elapsed,
        );
      },
    );
  }

  void finish() {
    _timer?.cancel();
    state.whenOrNull(
      running: (task, remaining, elapsed, startedAt) {
        state = StudyTimerState.finished(
          task: task,
          totalElapsedSeconds: elapsed,
        );
        _updateTaskInRepository(task, elapsed ~/ 60, markComplete: true);
      },
      paused: (task, remaining, elapsed) {
        state = StudyTimerState.finished(
          task: task,
          totalElapsedSeconds: elapsed,
        );
        _updateTaskInRepository(task, elapsed ~/ 60, markComplete: true);
      },
    );
  }

  void discard() {
    _timer?.cancel();
    state = const StudyTimerState.idle();
  }

  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state.whenOrNull(
        running: (task, remaining, elapsed, startedAt) {
          if (remaining <= 1) {
            _timer?.cancel();
            state = StudyTimerState.finished(
              task: task,
              totalElapsedSeconds: elapsed + 1,
            );
            // Auto-show completion dialog via listener
          } else {
            state = StudyTimerState.running(
              task: task,
              remainingSeconds: remaining - 1,
              elapsedSeconds: elapsed + 1,
              startedAt: startedAt,
            );
          }
        },
      );
    });
  }

  Future<void> _updateTaskInRepository(
    StudyTask task,
    int actualMinutes, {
    required bool markComplete,
  }) async {
    final updatedTask = task.copyWith(
      actualMinutesSpent: actualMinutes,
      startedAt: task.startedAt ?? DateTime.now(),
      completedAt: markComplete ? DateTime.now() : null,
      isCompleted: markComplete,
    );

    // Update in the active plan
    final plan = _ref.read(activePlanProvider);
    if (plan == null) return;

    await _ref.read(studyPlansProvider.notifier).updateTaskCompletion(
      plan.id,
      task.scheduledDate.toIso8601String(),
      task.id,
      markComplete,
    );

    // Also update the actual_minutes_spent field
    // This requires extending StudyPlansNotifier with an updateTask() method
    // that updates all fields, not just isCompleted
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final studyTimerProvider =
    StateNotifierProvider<StudyTimerNotifier, StudyTimerState>(
  (ref) => StudyTimerNotifier(ref),
);
```

**Note:** `StudyPlansNotifier` currently only has `updateTaskCompletion(planId, dayDate, taskId, isCompleted)`. You need to add an `updateTask()` method that replaces the entire task object (to persist `actualMinutesSpent`, `startedAt`, `completedAt`).

---

##### F. Remote Data Source + Repository Update

**New file:** `frontend/lib/features/study_plan/data/datasources/study_plan_remote_datasource.dart`

```dart
class StudyPlanRemoteDataSource {
  final Dio _dio;
  StudyPlanRemoteDataSource(this._dio);

  Future<StudyPlan> generatePlan({
    required int studentId,
    required DateTime examDate,
    required int dailyMinutes,
    required List<String> weakSubjects,
    required String classLevel,
    String? subject,
  }) async {
    final response = await _dio.post('/study-plan/generate', data: {
      'student_id': studentId,
      'exam_date': examDate.toIso8601String(),
      'daily_minutes': dailyMinutes,
      'weak_subjects': weakSubjects,
      'class_level': classLevel,
      if (subject != null) 'subject': subject,
    });
    return StudyPlan.fromJson(response.data['data']);
  }
}
```

**Update `StudyPlanRepository`:**
- Replace `MockStudyPlanService.generatePlan()` with `StudyPlanRemoteDataSource.generatePlan()`
- Keep `StudyPlanLocalDataSource` as cache for offline viewing

---

##### G. Plan Generation Flow (End-to-End)

```
User taps "Create Study Plan"
  → PlanCreateScreen (3-step wizard)
    → Step 1: Pick exam date
    → Step 2: WeakSubjectPicker (auto-suggests weak topics from analytics)
    → Step 3: Set daily study minutes
    → Tap "Generate Plan"
      → StudyPlanRepository.createPlan() → calls backend POST /study-plan/generate
        → Backend fetches TopicPerformance + calls Gemini
        → Returns structured plan JSON
      → Frontend stores plan in Hive via StudyPlanLocalDataSource
      → Navigates to PlanDetailScreen
  → User sees calendar + today's schedule
    → Tap "Start" on a task
      → StudyTimerWidget opens (full-screen timer)
      → Timer counts down from task.durationMinutes
      → User can Pause, Resume, or "Finish Early"
      → Timer reaches 0 (or user finishes)
        → TaskCompletionDialog appears
          → "+10 Minutes" → extends timer, back to StudyTimerWidget
          → "Mark as Done" → updates task (isCompleted=true, actualMinutesSpent, completedAt)
            → PracticeExamPromptDialog appears
              → "Yes, Let's Go!" → pre-fills examConfigProvider with task.topic + task.subject
                → navigates to ExamConfigScreen
              → "Maybe Later" → dismisses
          → "Cancel" → dismisses, partial time not saved
```

---

### Phase 3: Build Missing Features

#### 3.1 PDF Upload Flow (Study Companion Cross-Reference)

**Backend dependency:** `POST /upload/pdf`

For the Study Companion use case, PDF upload is **temporary text extraction** — not permanent storage. The extracted text is sent alongside the user's question so Gemini can cross-reference the PDF with the curriculum book in RAG.

**Frontend tasks:**

1. **Wire the Upload Shell PDF CTA to Study Companion:**

**File:** `frontend/lib/features/upload/presentation/screens/upload_shell_screen.dart`

The "Upload PDF Chapter" card currently has `onTap: () {}`. Navigate to Study Companion with a flag to auto-open the file picker:

```dart
onTap: () {
  context.push('/study-companion', extra: {'autoPickPdf': true});
},
```

**File:** `frontend/lib/features/study_companion/presentation/screens/study_companion_screen.dart`

Accept the flag in `initState` or via a provider, and trigger the file picker automatically.

2. **The actual PDF upload + extraction is handled inside Study Companion** (see Phase 2.5 above). The `PdfUploadRemoteDataSource` lives in the `study_companion` feature, not the `upload` feature.

3. **For permanent curriculum ingestion** (adding new books to ChromaDB for all students), that is a server-side admin task using the existing `rag/ingest.py` CLI. No frontend work needed for MVP.

#### 3.2 Library Feature — Notes Tab (Full Implementation)

**Backend dependency:** `POST /notes`, `GET /notes`, `DELETE /notes/{id}` (see Backend Guide Section 10)

**Frontend tasks:**

**1. Create the `NoteModel`:**

**New file:** `frontend/lib/features/library/data/models/note_model.dart`

```dart
class NoteModel {
  final String id;
  final String title;
  final String content;      // markdown
  final String topic;        // primary grouping key
  final String? subject;
  final String? classLevel;
  final String source;       // 'study_companion' | 'practice' | 'topic_notes'
  final DateTime createdAt;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.topic,
    this.subject,
    this.classLevel,
    required this.source,
    required this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}
```

**2. Create local + remote data sources:**

**New file:** `frontend/lib/features/library/data/datasources/note_local_datasource.dart`

```dart
class NoteLocalDataSource {
  final Box<String> _box;
  NoteLocalDataSource(this._box);

  Future<void> saveNote(NoteModel note) async {
    await _box.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> deleteNote(String id) async => _box.delete(id);

  List<NoteModel> getAllNotes() {
    return _box.values
        .map((s) => NoteModel.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<NoteModel> getNotesByTopic(String topic) {
    return getAllNotes().where((n) => n.topic == topic).toList();
  }
}
```

**New file:** `frontend/lib/features/library/data/datasources/note_remote_datasource.dart`

```dart
class NoteRemoteDataSource {
  final Dio _dio;
  NoteRemoteDataSource(this._dio);

  Future<NoteModel> createNote(Map<String, dynamic> payload) async {
    final response = await _dio.post('/notes', data: payload);
    return NoteModel.fromJson(response.data['data']);
  }

  Future<List<NoteModel>> fetchNotes({String? topic, String? source}) async {
    final response = await _dio.get('/notes', queryParameters: {
      if (topic != null) 'topic': topic,
      if (source != null) 'source': source,
    });
    return (response.data['data'] as List)
        .map((e) => NoteModel.fromJson(e))
        .toList();
  }

  Future<void> deleteNote(String id) async {
    await _dio.delete('/notes/$id');
  }
}
```

**3. Create repository + provider:**

**New file:** `frontend/lib/features/library/domain/repositories/note_repository.dart`

```dart
class NoteRepository {
  final NoteLocalDataSource _local;
  final NoteRemoteDataSource _remote;

  NoteRepository(this._local, this._remote);

  Future<void> saveNote(NoteModel note) async {
    await _local.saveNote(note);
    try {
      final created = await _remote.createNote(note.toJson());
      // Optionally update local ID with server ID
    } catch (_) {
      // Offline — note stays in local Hive, will sync later
    }
  }

  Future<List<NoteModel>> getNotes({String? topic}) async {
    try {
      final remote = await _remote.fetchNotes(topic: topic);
      // Cache to local
      for (final n in remote) await _local.saveNote(n);
      return remote;
    } catch (_) {
      return _local.getAllNotes();
    }
  }

  Future<void> deleteNote(String id) async {
    await _local.deleteNote(id);
    try { await _remote.deleteNote(id); } catch (_) {}
  }
}
```

**4. Update `main.dart` to open the saved notes box:**

**File:** `frontend/lib/main.dart`

```dart
await Hive.openBox<String>(StorageKeys.savedNotesBox);
```

**5. Build the `NotesTab` in Library:**

**File:** `frontend/lib/features/library/presentation/screens/library_screen.dart`

Replace the `EmptyState` for Notes with a real `ConsumerWidget` that:
- Watches `notesProvider`
- Groups notes by `topic` using `ListView` with sticky headers or sectioned list
- Each note card shows: title, topic chip, relative date, source icon
- Tapping a note navigates to `NoteDetailScreen`
- Long-press or trailing icon → delete confirmation

```dart
class NotesTab extends ConsumerWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border,
            title: 'No Saved Notes',
            message: 'Notes you save from AI explanations or practice suggestions will appear here.',
          );
        }
        // Group by topic
        final grouped = groupBy(notes, (n) => n.topic);
        return ListView.builder(
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final topic = grouped.keys.elementAt(index);
            final topicNotes = grouped[topic]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(topic, style: Theme.of(context).textTheme.titleSmall),
                ),
                ...topicNotes.map((note) => NoteListTile(note: note)),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load notes')),
    );
  }
}
```

**New file:** `frontend/lib/features/library/presentation/screens/note_detail_screen.dart`

Full-screen view of a single note:
- AppBar with title + delete action
- Body: `MarkdownMessageCard` rendering `note.content`
- Footer: metadata chips (topic, subject, source, date)

**6. Quizzes Tab — keep as placeholder for now:**

The Quizzes tab remains an `EmptyState` until the exam review "save quiz" feature is built. Documented here for completeness but out of scope for this task.

---

### Phase 4: Offline Support

#### 4.1 Implement Sync Queue

The `syncQueueBox` is already defined in `StorageKeys` but unused.

**File:** `frontend/lib/core/services/sync_service.dart` (new)

```dart
class SyncService {
  final Box<Map> _syncQueue;
  final Dio _dio;

  SyncService(this._syncQueue, this._dio);

  void queueExamSubmission(Map<String, dynamic> payload) {
    _syncQueue.add({
      'type': 'exam_submit',
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> processQueue() async {
    for (final key in _syncQueue.keys.toList()) {
      final item = _syncQueue.get(key);
      try {
        await _dio.post('/exam/submit', data: item!['payload']);
        await _syncQueue.delete(key);
      } catch (e) {
        // Keep in queue for next retry
        break;
      }
    }
  }
}
```

Trigger `processQueue()`:
- On app startup
- When connectivity is restored (use `connectivity_plus`)
- After every exam submission (if online, submit directly; if offline, queue)

---

### Phase 5: Testing

#### 5.1 Unit Tests

```bash
cd frontend
flutter test test/unit/
```

Test:
- Model serialization (`toJson` / `fromJson`) — Analytics & Study Plan already have these
- Repository logic
- Provider state transitions

#### 5.2 Widget Tests

```bash
flutter test test/widget/
```

Test:
- `ExamSessionScreen` — timer counts down, submit button works
- `DashboardScreen` — shows loading, then data, then error
- `RegistrationScreen` — form validation, login/register toggle

#### 5.3 Integration Tests

```bash
flutter test test/integration/
```

Test:
- Full flow: register → generate exam → answer questions → submit → view result
- Full flow: login → view history → logout

---

## Architecture Reference

### Project Structure

```
lib/
  main.dart                 # Entry point, Hive init
  app.dart                  # MaterialApp.router, themes
  routing/
    app_router.dart         # GoRouter configuration
    route_guards.dart       # Auth redirect logic
  theme/
    app_theme.dart          # Light/dark themes
    color_tokens.dart       # Brand colors
  core/
    constants/
      storage_keys.dart     # Hive box names
    network/
      dio_client.dart       # Base URL, interceptors
    errors/
      app_error.dart        # Custom exceptions
  common_widgets/           # Atomic design widgets
    atoms/
    molecules/
    organisms/
    templates/
  features/
    auth/                   # ✅ Fully implemented (register + login + JWT)
    exam/                   # ✅ Fully implemented
    dashboard/              # ✅ Wired to real API
    analytics/              # ✅ Wired to real API
    topics/                 # ✅ Wired to real API
    library/                # ✅ Notes wired to real API (Quizzes tab still placeholder)
    study_companion/        # 🎨 UI done, file picker ready, needs RAG API + source chips
    study_plan/             # 🎨 UI done, models serialized, needs API
    upload/                 # ⚠️ Partial
    settings/               # ✅ Functional
    onboarding/             # ✅ Functional
    splash/                 # ✅ Functional
    home/                   # ✅ Wired
```

### State Management Patterns

| Pattern | Used For | Example |
|---------|----------|---------|
| `Provider` | Dependency injection | `studentProvider`, `dioProvider` |
| `StateProvider` | Ephemeral UI state | `examConfigProvider`, `themeModeProvider` |
| `StateNotifierProvider` | Complex mutable state | `ExamSessionNotifier`, `ChatSessionsNotifier` |
| `FutureProvider` | Async data fetching | `dashboardDataProvider` |

---

## Environment Configuration

The Dio base URL is configured in `frontend/lib/core/network/dio_client.dart`:

```dart
final dio = Dio(BaseOptions(
  baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000'),
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));
```

**For Android emulator:** `10.0.2.2:8000` (localhost of host machine)
**For iOS simulator:** `127.0.0.1:8000`
**For physical device:** Use your computer's LAN IP (e.g., `192.168.1.5:8000`)

To override at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
```

---

## Running the Frontend

```bash
cd frontend
flutter pub get
flutter run
```

**Build for release:**

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

---

## Completion Checklist

### Bug Fixes
- [x] Wire up HomeScreen quick-action `onTap`s (already done)
- [x] Implement dashboard refresh indicator
- [x] Wire dashboard error retry button

### Backend Integration
- [x] Add `toJson`/`fromJson` to dashboard models (snake_case compatible)
- [x] Add `toJson`/`fromJson` to analytics models (already done)
- [x] Add `toJson`/`fromJson` to study plan models (already done)
- [x] Create `DashboardRemoteDataSource` + wire to backend
- [x] Create `AnalyticsRemoteDataSource` + wire to backend
- [x] Create `TopicsRemoteDataSource` + wire to backend
- [x] Create `NoteRemoteDataSource` + wire to backend
- [ ] Create `StudyCompanionRemoteDataSource` + wire to backend (`POST /study-companion/ask` with RAG + `pdf_context`)
- [ ] Create `PdfUploadRemoteDataSource` inside Study Companion for temporary text extraction
- [ ] Add `sources` field to `ChatMessage` model + render source chips in AI bubbles
- [ ] Create `StudyPlanRemoteDataSource` + wire to backend `POST /study-plan/generate`
- [ ] Replace `MockStudyPlanService` with remote generation in `StudyPlanRepository`

### User-Suggested Features
- [ ] Wire "Practice Now" button in Weak Chapters to pre-filled exam config
- [ ] Populate Practice Suggestions from backend (via analytics or dedicated endpoint)

### New Backend Endpoints Needed
- [x] `GET /student/{id}/dashboard` ✅ Implemented
- [x] `GET /student/{id}/analytics` ✅ Implemented
- [x] `GET /student/{id}/topics` ✅ Implemented
- [ ] `POST /practice/generate` (or `practice_mode` on `/exam/generate`)
- [ ] `POST /study-companion/ask` (RAG-powered with `pdf_context` support)
- [ ] `POST /rag/ask` (RAG service retrieval + Gemini Q&A)
- [ ] `POST /study-companion/topic-notes`
- [ ] `POST /study-plan/generate` (Gemini-powered with weak topic context)
- [ ] `GET /study-plan/{id}` + `DELETE /study-plan/{id}` (optional)
- [ ] `PUT /study-plan/tasks/{task_id}/progress` (optional for MVP)
- [ ] `POST /upload/pdf`
- [x] `GET /notes` + `POST /notes` + `DELETE /notes/{id}` ✅ Implemented
- [ ] `GET /library/quizzes`

### Missing Features
- [ ] Implement PDF text extraction in Study Companion (temporary, not permanent storage)
- [ ] Wire Upload Shell PDF CTA to Study Companion with auto-pick flag
- [x] Build Library `NotesTab` with topic grouping + `NoteDetailScreen` ✅ Implemented
- [x] Create `NoteModel` + `NoteLocalDataSource` + `NoteRemoteDataSource` + `NoteRepository` ✅ Implemented
- [ ] Open `savedNotesBox` in `main.dart` (if not already opened)
- [ ] Add "Save as Note" button to Study Companion AI bubbles (`chat_message_bubble.dart`)
- [ ] Add "Save as Note" button to Practice Suggestion cards (`practice_suggestions_card.dart`)
- [ ] Build `SaveNoteBottomSheet` widget for title/topic confirmation
- [ ] Build Library quizzes tab (out of scope for now — keep placeholder)
- [ ] Add `actualMinutesSpent`, `startedAt`, `completedAt` to `StudyTask` model
- [ ] Build `StudyTimerWidget` (countdown with pause/resume/+10 min extension)
- [ ] Build `TaskCompletionDialog` ("Finished?" + "+10 mins" + "Mark as Done")
- [ ] Build `PracticeExamPromptDialog` (navigate to exam config with pre-filled topic)
- [ ] Add "Start" button to `_TimelineItem` / `StudyTaskCard`
- [ ] Create `studyTimerProvider` for timer state management
- [ ] Wire task completion to update repository with actual time spent
- [ ] Pre-fill exam config with task topic/subject on "Yes, Let's Go!"

### Auth (Done ✅)
- [x] Add `LoginScreen` (merged into RegistrationScreen)
- [x] Store JWT token after login
- [x] Verify `AuthInterceptor` attaches Bearer token

### Offline
- [ ] Implement `SyncService` with queue processing
- [ ] Queue exam submissions when offline
- [ ] Auto-sync on connectivity restore

### Testing
- [ ] Unit tests for model serialization
- [ ] Widget tests for exam session + dashboard + auth
- [ ] Integration test for full exam flow
- [ ] Integration test for login flow
