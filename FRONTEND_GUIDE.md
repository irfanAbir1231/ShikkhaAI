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
| **Auth (Onboarding → Registration)** | ✅ Yes | Calls `POST /student/register`, persists to Hive |
| **Exam (Config → Session → Result → History)** | ✅ Yes | Full lifecycle with timer, navigation grid, review. Calls `POST /exam/generate` and `POST /exam/submit` |
| **Settings** | ❌ No (local only) | Theme toggle, reset onboarding, logout. Persists to Hive |
| **Splash / Onboarding** | ❌ No (local only) | Animated splash, 3-page onboarding with `PageView` |

### 🎨 UI-Complete But Mock-Data Features

| Feature | Backend API? | Notes |
|---------|-------------|-------|
| **Dashboard** | ❌ No | Rich UI with charts, skeleton loaders. Uses `MockDashboardService` with hardcoded data |
| **Analytics (Weakness)** | ❌ No | Heatmaps, radar charts, streak calendar. Uses `MockAnalyticsService` |
| **Study Companion (Chat)** | ❌ No | Full chat UI with 7 explanation modes. Returns **same photosynthesis text** for every query |
| **Study Plan** | ❌ No | Calendar view, task completion. Uses `MockStudyPlanService` for local generation |

### ⚠️ Partial / Shell Features

| Feature | Status | Notes |
|---------|--------|-------|
| **Upload (Handwritten)** | ⚠️ Partial | Image picker → preview → mock OCR evaluation. Works end-to-end but with fake scoring |
| **Upload (PDF)** | 🚧 Shell | CTA card has `onTap: () {}` — completely non-functional |
| **Library** | 🚧 Shell | Only has `TabBarView` with two `EmptyState` placeholders |

### ❌ Missing / Broken

| Issue | Impact |
|-------|--------|
| Dashboard, Analytics, Study Companion, Study Plan use mock services | These features do not reflect real student data |
| HomeScreen quick-action cards mostly inactive | Study Companion, Smart Exam, Handwritten Eval cards have no `onTap` |
| `AuthInterceptor` reads non-existent JWT token | Backend has no auth, so this is harmless but will break once auth is added |
| SnackBar string interpolation bug | `'Failed to start exam: \$e'` shows literal backslash instead of error |
| Dashboard refresh is a no-op | `RefreshIndicator.onRefresh` is empty |
| No offline sync queue | `syncQueueBox` is defined but never used |
| No tests | Only default `widget_test.dart` exists |

---

## Step-by-Step Completion Plan

### Phase 1: Fix Bugs & Polish Existing Features

#### 1.1 Fix SnackBar String Interpolation Bug

**Files:** `frontend/lib/features/exam/presentation/screens/exam_config_screen.dart` and `exam_session_screen.dart`

Find lines like:

```dart
SnackBar(content: Text('Failed to start exam: \$e'))
```

Change to:

```dart
SnackBar(content: Text('Failed to start exam: $e'))
```

Remove the backslash before `$e`.

#### 1.2 Wire Up HomeScreen Quick Actions

**File:** `frontend/lib/features/home/presentation/screens/home_screen.dart`

Add `onTap` handlers to the quick-action cards:

```dart
// Study Companion card
onTap: () => context.push('/study'),

// Smart Exam card
onTap: () => context.push('/exam/config'),

// Handwritten Eval card
onTap: () => context.push('/upload/handwritten'),
```

#### 1.3 Make Dashboard Refresh Actually Work

**File:** `frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Implement `RefreshIndicator.onRefresh` to re-fetch dashboard data:

```dart
RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(dashboardDataProvider);
    await ref.read(dashboardDataProvider.future);
  },
  child: ...
)
```

---

### Phase 2: Replace Mock Services with Real API Calls

This is the **largest phase**. For each mock feature, you need to:

1. Define API contract models with `toJson()` / `fromJson()`
2. Create a remote data source that calls the backend
3. Update the repository to use the remote data source
4. Update providers to handle loading / error states

#### 2.1 Dashboard → Real Backend Integration

**Backend dependency:** The backend needs `GET /student/{id}/dashboard` or `GET /student/{id}/weak-topics` + `GET /student/{id}/attempts`.

**Frontend tasks:**

1. **Add serialization to dashboard models:**

**File:** `frontend/lib/features/dashboard/domain/models/dashboard_data.dart`

Add `toJson()` and `fromJson()` to all dashboard model classes.

2. **Create remote data source:**

**New file:** `frontend/lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart`

```dart
class DashboardRemoteDataSource {
  final Dio _dio;
  DashboardRemoteDataSource(this._dio);

  Future<DashboardData> fetchDashboard(int studentId) async {
    final response = await _dio.get('/student/$studentId/dashboard');
    return DashboardData.fromJson(response.data['data']);
  }
}
```

3. **Update repository:**

**File:** `frontend/lib/features/dashboard/data/repositories/dashboard_repository.dart`

Replace `MockDashboardService` with `DashboardRemoteDataSource`.

4. **Update provider:**

**File:** `frontend/lib/features/dashboard/presentation/providers/dashboard_provider.dart`

```dart
final dashboardDataProvider = FutureProvider.family<DashboardData, int>(
  (ref, studentId) async {
    final repo = ref.watch(dashboardRepositoryProvider);
    return await repo.fetchDashboard(studentId);
  },
);
```

#### 2.2 Analytics → Real Backend Integration

Same pattern as Dashboard. Backend needs to expose topic-accuracy data.

**New backend endpoint needed:** `GET /student/{id}/analytics`

**Frontend:**
- Add `toJson`/`fromJson` to analytics models
- Create `AnalyticsRemoteDataSource`
- Update `AnalyticsRepository` to use the remote source

#### 2.3 Study Companion → Real LLM Chat

This requires a **new backend endpoint** because the frontend should not call Gemini directly (API key exposure).

**Backend dependency:** Add `POST /chat` or `POST /study-companion/ask`:

```json
// Request
{
  "student_id": 1,
  "message": "Explain photosynthesis simply",
  "mode": "easyEnglish",
  "subject": "science",
  "class_level": "8"
}

// Response (streaming or full)
{
  "success": true,
  "data": {
    "response": "Photosynthesis is the process..."
  }
}
```

**Frontend tasks:**

1. Create `StudyCompanionRemoteDataSource` that calls the new endpoint.
2. Update `StudyCompanionRepository` to use it.
3. If implementing streaming: update `CurrentChatNotifier` to handle `ResponseBody` streams from Dio.
4. **Important:** The file-attachment feature currently stores metadata but does nothing. Decide whether to:
   - Upload images to backend for vision-model analysis, or
   - Remove the feature for MVP.

#### 2.4 Study Plan → Real Backend Integration

**Backend dependency:** Add `POST /study-plan/generate`:

```json
// Request
{
  "student_id": 1,
  "exam_date": "2026-06-15",
  "daily_minutes": 60,
  "weak_subjects": ["Algebra", "Photosynthesis"],
  "class_level": "8"
}
```

The backend can call Gemini to generate a personalized study schedule.

**Frontend tasks:**
- Create `StudyPlanRemoteDataSource`
- Update `StudyPlanRepository`
- Keep Hive as a local cache for offline viewing

---

### Phase 3: Build Missing Features

#### 3.1 PDF Upload Flow

**Backend dependency:** Add `POST /upload/pdf` that:
1. Accepts a multipart file upload
2. Saves to `uploads/`
3. Triggers `rag.ingest.ingest_pdf()` to embed into ChromaDB
4. Returns a job ID for tracking ingestion status

**Frontend tasks:**

1. **Create PDF upload screen:**

**New file:** `frontend/lib/features/upload/presentation/screens/pdf_upload_screen.dart`

Use `file_picker` package to select PDFs:

```yaml
# pubspec.yaml
dependencies:
  file_picker: ^10.0.0
```

2. **Implement upload repository:**

```dart
class UploadRemoteDataSource {
  final Dio _dio;
  UploadRemoteDataSource(this._dio);

  Future<String> uploadPdf(File file, String subject, String classLevel) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'subject': subject,
      'class_level': classLevel,
    });
    final response = await _dio.post('/upload/pdf', data: formData);
    return response.data['data']['job_id'];
  }
}
```

3. **Add route:**

```dart
GoRoute(
  path: '/upload/pdf',
  builder: (context, state) => const PdfUploadScreen(),
),
```

4. **Wire up the CTA card** in `UploadShellScreen`.

#### 3.2 Library Feature

**Backend dependency:** Add endpoints for saved content:
- `GET /library/notes`
- `GET /library/quizzes`
- `POST /library/notes` (save a note)
- `POST /library/quizzes` (save a quiz)

**Frontend tasks:**

1. Create models: `Note`, `SavedQuiz`
2. Create repository + remote data source
3. Build screens:
   - `NotesTab` — list of saved notes with search
   - `QuizzesTab` — list of saved quizzes
4. Add "Save to Library" buttons on:
   - Exam result screen (save quiz)
   - Study companion chat (save explanation as note)

---

### Phase 4: Authentication & Security

#### 4.1 JWT Token Handling

Once the backend implements JWT auth (see `BACKEND_GUIDE.md`):

1. **Update `AuthRemoteDataSource`:**

Add `login` method:

```dart
Future<AuthToken> login(String email, String password) async {
  final response = await _dio.post('/student/login', data: {
    'email': email,
    'password': password,
  });
  return AuthToken.fromJson(response.data['data']);
}
```

2. **Store token after login:**

```dart
await Hive.box<String>(StorageKeys.authBox).put(StorageKeys.authToken, token.accessToken);
```

3. **Update `AuthInterceptor`:**

The interceptor already reads `auth_token` from Hive. Verify it attaches the header correctly:

```dart
options.headers['Authorization'] = 'Bearer $token';
```

4. **Add login screen:**

Create `LoginScreen` and add it to the auth flow before or alongside registration.

#### 4.2 Token Refresh

If implementing refresh tokens:

1. Add `POST /student/refresh` to backend
2. Create a Dio interceptor that catches 401 errors, refreshes the token, and retries the request

---

### Phase 5: Offline Support

#### 5.1 Implement Sync Queue

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

### Phase 6: Testing

#### 6.1 Unit Tests

```bash
cd frontend
flutter test test/unit/
```

Test:
- Model serialization (`toJson` / `fromJson`)
- Repository logic
- Provider state transitions

#### 6.2 Widget Tests

```bash
flutter test test/widget/
```

Test:
- `ExamSessionScreen` — timer counts down, submit button works
- `DashboardScreen` — shows loading, then data, then error
- `RegistrationScreen` — form validation

#### 6.3 Integration Tests

```bash
flutter test test/integration/
```

Test:
- Full flow: register → generate exam → answer questions → submit → view result

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
    auth/                   # ✅ Fully implemented
    exam/                   # ✅ Fully implemented
    dashboard/              # 🎨 UI done, needs API
    analytics/              # 🎨 UI done, needs API
    study_companion/        # 🎨 UI done, needs API
    study_plan/             # 🎨 UI done, needs API
    upload/                 # ⚠️ Partial
    library/                # 🚧 Shell
    settings/               # ✅ Functional
    onboarding/             # ✅ Functional
    splash/                 # ✅ Functional
    home/                   # ⚠️ Needs wiring
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
- [ ] Fix `\$e` string interpolation in exam screens
- [ ] Wire up HomeScreen quick-action `onTap`s
- [ ] Implement dashboard refresh indicator

### Backend Integration
- [ ] Add `toJson`/`fromJson` to dashboard models
- [ ] Add `toJson`/`fromJson` to analytics models
- [ ] Create `DashboardRemoteDataSource` + wire to backend
- [ ] Create `AnalyticsRemoteDataSource` + wire to backend
- [ ] Create `StudyCompanionRemoteDataSource` + wire to backend
- [ ] Create `StudyPlanRemoteDataSource` + wire to backend

### New Backend Endpoints Needed
- [ ] `GET /student/{id}/dashboard`
- [ ] `GET /student/{id}/analytics`
- [ ] `POST /study-companion/ask`
- [ ] `POST /study-plan/generate`
- [ ] `POST /upload/pdf`
- [ ] `GET /library/notes`
- [ ] `GET /library/quizzes`

### Missing Features
- [ ] Implement PDF upload screen + repository
- [ ] Build Library notes tab
- [ ] Build Library quizzes tab
- [ ] Add "Save to Library" actions

### Auth
- [ ] Add `LoginScreen`
- [ ] Store JWT token after login
- [ ] Verify `AuthInterceptor` attaches Bearer token

### Offline
- [ ] Implement `SyncService` with queue processing
- [ ] Queue exam submissions when offline
- [ ] Auto-sync on connectivity restore

### Testing
- [ ] Unit tests for model serialization
- [ ] Widget tests for exam session + dashboard
- [ ] Integration test for full exam flow
