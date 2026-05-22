# ShikkhaAI — Frontend Architecture & Development Guide

> **Target Platform:** Android / iOS (Bangladeshi students, Class 8–10)  
> **Backend:** FastAPI JSON API (local & remote)  
> **Flutter:** latest stable  
> **Dart:** latest stable  
> **Last Updated:** 2026-05-21

---

## Table of Contents

1. [Full Frontend Architecture](#1-full-frontend-architecture)
2. [Folder Structure](#2-folder-structure-very-detailed)
3. [State Management Decision](#3-state-management-decision)
4. [API Layer Structure](#4-api-layer-structure)
5. [Offline Caching Strategy](#5-offline-caching-strategy)
6. [Navigation Flow](#6-navigation-flow)
7. [Theme System](#7-theme-system)
8. [Reusable Widget Strategy](#8-reusable-widget-strategy)
9. [Screen Descriptions](#9-screen-descriptions)
10. [Feature-Module Mapping](#10-feature-module-mapping)
11. [Data Flow Explanation](#11-data-flow-explanation)
12. [Mock-First Development Strategy](#12-mock-first-development-strategy)
13. [Integration Strategy with FastAPI Backend](#13-integration-strategy-with-fastapi-backend)
14. [Local Storage Strategy](#14-local-storage-strategy)
15. [AI Feature Integration Architecture](#15-ai-feature-integration-architecture)
16. [OCR Flow Explanation](#16-ocr-flow-explanation)
17. [Dashboard Analytics Architecture](#17-dashboard-analytics-architecture)
18. [Feature Implementation Order](#18-feature-implementation-order)

---

## 1. Full Frontend Architecture

We use **Feature-First Clean Architecture** with three internal layers per feature:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
│  • Screens (UI pages)                                           │
│  • Widgets (local + shared)                                     │
│  • State Notifiers / Controllers (Riverpod)                     │
├─────────────────────────────────────────────────────────────────┤
│                        DOMAIN LAYER                             │
│  • Entities (pure Dart classes)                                 │
│  • Repository Interfaces (abstract contracts)                   │
│  • Use Cases (optional; kept thin for mobile)                   │
├─────────────────────────────────────────────────────────────────┤
│                        DATA LAYER                               │
│  • Repository Implementations                                   │
│  • Data Sources (Remote: Dio, Local: Hive)                      │
│  • DTOs / Models (Freezed + json_serializable)                  │
│  • Mappers (DTO ↔ Entity)                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Global Shared Layers (outside features)

- **core/** — constants, extensions, errors, network interceptors, app-wide utilities
- **routing/** — go_router configuration, route guards, deep-link handlers
- **theme/** — `AppTheme`, color tokens, text themes, widget themes
- **common_widgets/** — design-system primitives shared across all features
- **services/** — singletons that don't belong to a single feature (e.g., connectivity monitor)

### Architecture Rules

1. **Presentation** depends only on **Domain** (never on Data directly).
2. **Data** implements **Domain** interfaces.
3. **Domain** has zero external package dependencies (pure Dart).
4. Each feature is self-contained; cross-feature communication happens only through shared domain entities or Riverpod providers injected at app level.
5. **No Firebase** anywhere — all backend calls go through the FastAPI REST API.

---

## 2. Folder Structure (VERY Detailed)

```
frontend/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── test/
│   ├── unit/
│   │   ├── features/
│   │   │   ├── ai_study_companion/
│   │   │   ├── dashboard/
│   │   │   ├── smart_exam/
│   │   │   ├── handwritten_eval/
│   │   │   └── study_plan/
│   │   └── core/
│   ├── widget/
│   └── integration/
├── lib/
│   ├── main.dart                          # Entry point; initializes Hive + Riverpod
│   ├── app.dart                           # ShikkhaAIApp (MaterialApp.router)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart         # Base URLs, endpoints, timeouts
│   │   │   ├── app_constants.dart         # App name, version, default values
│   │   │   └── storage_keys.dart          # Hive box names, key constants
│   │   ├── errors/
│   │   │   ├── exceptions.dart            # ServerException, CacheException
│   │   │   └── failures.dart              # Failure sealed class (freezed)
│   │   ├── extensions/
│   │   │   ├── context_ext.dart           # Theme, mediaQuery, snackbar helpers
│   │   │   ├── string_ext.dart            # Bengali numerals, validation
│   │   │   └── date_ext.dart              # Date formatting for study plans
│   │   ├── network/
│   │   │   ├── dio_client.dart            # Configured Dio instance
│   │   │   ├── interceptors/
│   │   │   │   ├── auth_interceptor.dart  # Attach Bearer token
│   │   │   │   ├── retry_interceptor.dart # Auto-retry on 5xx / timeout
│   │   │   │   └── logging_interceptor.dart
│   │   │   └── network_info.dart          # Connectivity check wrapper
│   │   └── utils/
│   │       ├── debouncer.dart
│   │       ├── result.dart                # Result<T, Failure> type
│   │       └── file_picker_helper.dart
│   │
│   ├── routing/
│   │   ├── app_router.dart                # GoRouter definition + navigator key
│   │   ├── route_names.dart               # Centralized route path strings
│   │   ├── route_guards.dart              # Auth redirect logic
│   │   └── deep_links.dart                # Future: /exam/123, /chapter/456
│   │
│   ├── theme/
│   │   ├── app_theme.dart                 # LightTheme + DarkTheme factories
│   │   ├── color_tokens.dart              # Semantic colors (primary, surface, danger)
│   │   ├── text_theme.dart                # Inter / NotoSansBengali scales
│   │   ├── widget_themes.dart             # CardTheme, ElevatedButtonTheme, etc.
│   │   └── gradients.dart                 # Shared gradient definitions
│   │
│   ├── common_widgets/
│   │   ├── atoms/                         # Smallest building blocks
│   │   │   ├── app_button.dart
│   │   │   ├── app_icon.dart
│   │   │   ├── app_badge.dart
│   │   │   └── shimmer_box.dart
│   │   ├── molecules/
│   │   │   ├── app_card.dart              # Glassmorphism / soft shadow card
│   │   │   ├── app_text_field.dart
│   │   │   ├── app_dropdown.dart
│   │   │   ├── app_chip.dart
│   │   │   └── app_loading_indicator.dart
│   │   ├── organisms/
│   │   │   ├── app_bar.dart               # Custom branded AppBar
│   │   │   ├── bottom_nav_bar.dart        # Curved / floating nav
│   │   │   ├── empty_state.dart
│   │   │   └── error_state.dart
│   │   └── templates/
│   │       ├── scaffold_with_nav.dart     # ShellRoute wrapper
│   │       └── responsive_layout.dart     # Mobile / tablet breakpoints
│   │
│   ├── services/
│   │   ├── connectivity_service.dart      # Stream of online/offline status
│   │   ├── sync_service.dart              # Background queue for offline actions
│   │   └── analytics_service.dart         # In-app event logging (local first)
│   │
│   └── features/
│       ├── auth/                          # Student onboarding / login (local identity)
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── student.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   └── student_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── student_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── auth_remote_source.dart
│       │   │       └── auth_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── auth_provider.dart
│       │       ├── screens/
│       │       │   └── onboarding_screen.dart
│       │       └── widgets/
│       │           └── class_selector.dart
│       │
│       ├── ai_study_companion/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── chapter.dart
│       │   │   │   └── explanation.dart
│       │   │   └── repositories/
│       │   │       └── study_companion_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── chapter_model.dart
│       │   │   │   └── explanation_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── explanation_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── study_companion_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── study_companion_remote_source.dart
│       │   │       └── study_companion_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── chapter_list_provider.dart
│       │       │   ├── explanation_provider.dart
│       │       │   └── upload_provider.dart
│       │       ├── screens/
│       │       │   ├── chapter_upload_screen.dart
│       │       │   └── explanation_result_screen.dart
│       │       └── widgets/
│       │           ├── explanation_mode_chip.dart
│       │           └── pdf_thumbnail.dart
│       │
│       ├── smart_exam/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── question.dart
│       │   │   │   ├── exam_session.dart
│       │   │   │   └── exam_result.dart
│       │   │   └── repositories/
│       │   │       └── exam_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── question_model.dart
│       │   │   │   ├── exam_session_model.dart
│       │   │   │   └── exam_result_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── exam_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── exam_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── exam_remote_source.dart
│       │   │       └── exam_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── exam_generator_provider.dart
│       │       │   ├── exam_session_provider.dart
│       │       │   └── exam_history_provider.dart
│       │       ├── screens/
│       │       │   ├── exam_config_screen.dart
│       │       │   ├── exam_screen.dart
│       │       │   ├── exam_result_screen.dart
│       │       │   └── exam_history_screen.dart
│       │       └── widgets/
│       │           ├── question_card.dart
│       │           ├── timer_widget.dart
│       │           └── mcq_option.dart
│       │
│       ├── weakness_dashboard/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── topic_stat.dart
│       │   │   │   ├── weak_area.dart
│       │   │   │   └── streak.dart
│       │   │   └── repositories/
│       │   │       └── analytics_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── topic_stat_model.dart
│       │   │   │   └── weak_area_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── analytics_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── analytics_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── analytics_remote_source.dart
│       │   │       └── analytics_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── dashboard_provider.dart
│       │       │   └── streak_provider.dart
│       │       ├── screens/
│       │       │   └── dashboard_screen.dart
│       │       └── widgets/
│       │           ├── accuracy_chart.dart
│       │           ├── weak_topic_card.dart
│       │           ├── streak_flame.dart
│       │           └── improvement_graph.dart
│       │
│       ├── handwritten_eval/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── scanned_answer.dart
│       │   │   │   └── evaluation_result.dart
│       │   │   └── repositories/
│       │   │       └── handwritten_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── scanned_answer_model.dart
│       │   │   │   └── evaluation_result_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── handwritten_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── handwritten_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── handwritten_remote_source.dart
│       │   │       └── handwritten_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── image_upload_provider.dart
│       │       │   └── evaluation_provider.dart
│       │       ├── screens/
│       │       │   ├── upload_screen.dart
│       │       │   └── evaluation_result_screen.dart
│       │       └── widgets/
│       │           ├── image_preview.dart
│       │           └── score_badge.dart
│       │
│       ├── study_plan/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── study_plan.dart
│       │   │   │   ├── daily_task.dart
│       │   │   │   └── revision_slot.dart
│       │   │   └── repositories/
│       │   │       └── study_plan_repository.dart
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── study_plan_model.dart
│       │   │   │   └── daily_task_model.dart
│       │   │   ├── mappers/
│       │   │   │   └── study_plan_mapper.dart
│       │   │   ├── repositories/
│       │   │   │   └── study_plan_repository_impl.dart
│       │   │   └── data_sources/
│       │   │       ├── study_plan_remote_source.dart
│       │   │       └── study_plan_local_source.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── plan_generator_provider.dart
│       │       │   └── plan_view_provider.dart
│       │       ├── screens/
│       │       │   ├── plan_input_screen.dart
│       │       │   ├── plan_detail_screen.dart
│       │       │   └── task_checklist_screen.dart
│       │       └── widgets/
│       │           ├── timeline_view.dart
│       │           ├── task_card.dart
│       │           └── countdown_banner.dart
│       │
│       └── offline_library/
│           ├── domain/
│           │   ├── entities/
│           │   │   ├── saved_note.dart
│           │   │   └── saved_quiz.dart
│           │   └── repositories/
│           │       └── library_repository.dart
│           ├── data/
│           │   ├── models/
│           │   │   ├── saved_note_model.dart
│           │   │   └── saved_quiz_model.dart
│           │   ├── mappers/
│           │   │   └── library_mapper.dart
│           │   ├── repositories/
│           │   │   └── library_repository_impl.dart
│           │   └── data_sources/
│           │       └── library_local_source.dart
│           └── presentation/
│               ├── providers/
│               │   ├── saved_notes_provider.dart
│               │   └── saved_quizzes_provider.dart
│               ├── screens/
│               │   ├── library_screen.dart
│               │   └── note_reader_screen.dart
│               └── widgets/
│                   ├── note_tile.dart
│                   └── quiz_tile.dart
│
├── assets/
│   ├── images/
│   │   ├── logos/
│   │   ├── onboarding/
│   │   ├── illustrations/
│   │   └── subjects/
│   ├── animations/
│   │   ├── loading.json           # Lottie (optional; use Rive if preferred)
│   │   └── success.json
│   └── fonts/
│       ├── NotoSansBengali/
│       └── Inter/
│
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 3. State Management Decision

### Choice: **Riverpod** (`flutter_riverpod` + `riverpod_annotation` + code generation)

**Why not Provider / Bloc / GetX?**

| Concern | Riverpod Advantage |
|---|---|
| Compile-time safety | Providers are final globals; typos caught at compile time |
| Scoped disposal | Auto-dispose when widget leaves tree |
| Testability | Override any provider in tests with a single line |
| Async handling | `AsyncValue` gives `data/loading/error` out of the box |
| Family modifiers | `.family`, `.autoDispose`, `.future` reduce boilerplate |
| No BuildContext | Read providers anywhere (ideal for repositories) |

### State Layer Pattern

Every feature uses three provider categories:

1. **Repository Provider** — `Provider<T>` (singleton, lives whole app lifetime)
   ```dart
   @riverpod
   StudyCompanionRepository studyCompanionRepo(Ref ref) {
     return StudyCompanionRepositoryImpl(
       remote: ref.watch(studyCompanionRemoteSourceProvider),
       local: ref.watch(studyCompanionLocalSourceProvider),
     );
   }
   ```

2. **Controller / Notifier** — `AsyncNotifier<T>` or `StateNotifier<T>` for UI-driven mutations
   ```dart
   @riverpod
   class ExplanationController extends _$ExplanationController {
     @override
     Future<Explanation> build() async => ...;

     Future<void> generate({required String mode}) async {
       state = const AsyncLoading();
       final repo = ref.read(studyCompanionRepoProvider);
       state = await AsyncValue.guard(() => repo.getExplanation(mode: mode));
     }
   }
   ```

3. **Derived / Computed Providers** — `Provider` / `FutureProvider` for read-only derived state
   ```dart
   @riverpod
   Future<List<Chapter>> recentChapters(Ref ref) async {
     final repo = ref.watch(studyCompanionRepoProvider);
     return repo.getRecentChapters();
   }
   ```

### State Immutability

- All entities are **Freezed** classes with `copyWith`.
- UI only rebuilds when identity changes (Riverpod handles this via `select`).
- No manual `notifyListeners()` or `setState()` for business state.

---

## 4. API Layer Structure

### HTTP Client: **Dio**

Configured centrally in `core/network/dio_client.dart`:

```dart
class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(dio: dio, retries: 2),
      LoggingInterceptor(),
    ]);
  }
}
```

### Per-Feature Remote Source

Each feature exposes a thin **Remote Data Source** that speaks HTTP:

```dart
class StudyCompanionRemoteSource {
  StudyCompanionRemoteSource(this._dio);
  final Dio _dio;

  Future<ExplanationModel> explainChapter({
    required String chapterId,
    required String mode,
  }) async {
    final response = await _dio.post(
      '/ai/explain',
      data: {'chapter_id': chapterId, 'mode': mode},
    );
    return ExplanationModel.fromJson(response.data);
  }
}
```

### Error Handling

- Dio throws → caught in repository → mapped to `Failure`.
- `Result<T>` union used in domain to avoid throwing in UI layer.
- UI sees `AsyncError` and renders `ErrorState` widget.

### Multipart / File Upload

- `dio.post(..., data: FormData.fromMap({...}))` for PDFs and images.
- Upload progress exposed via `Stream<double>` if needed.

---

## 5. Offline Caching Strategy

### Philosophy: **Offline-First for Reads, Queue for Writes**

Students in Bangladesh often have flaky internet. The app must be usable without a connection.

### Read Path

1. UI requests data → Repository asks **Local** first.
2. If local cache is fresh (≤ configured TTL), return it immediately.
3. In background, fetch from **Remote**, update local cache, then refresh UI (if data changed).
4. If offline and cache exists → serve stale cache silently.
5. If offline and no cache → emit `CacheFailure` → UI shows cached error state with "Last synced: never".

### Write Path

1. UI mutation → Repository writes to **Local** immediately (optimistic UI update).
2. If online → sync to remote right away.
3. If offline → push operation into **Sync Queue** (Hive box).
4. `SyncService` listens to connectivity; when online, drains queue FIFO.
5. On sync success → update local record with server-assigned IDs; on failure after retries → mark record as "sync failed" and surface to user.

### Cache TTL per Feature

| Data | TTL | Strategy |
|---|---|---|
| Dashboard analytics | 5 minutes | Background refresh |
| AI explanation | Infinite | Never re-fetched automatically |
| Generated exam | Session-only | In-memory + Hive backup |
| Study plan | 1 hour | Pull to refresh |
| Saved notes / quizzes | Infinite | User-driven only |

---

## 6. Navigation Flow

### Router: **go_router** + `go_router_builder` (optional)

Declarative, deep-link friendly, works with Riverpod via `redirect` guards.

### Shell Routes (Persistent Bottom Navigation)

```
┌─────────────────────────────────────┐
│  Shell Scaffold (bottom nav)        │
│                                     │
│  [Home] [Exam] [Upload] [Profile]   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  Nested Navigator per tab   │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### Route Tree

```
/                     → Onboarding (first launch) OR /home
/auth/onboarding      → Class selection, name input
/home                 → Dashboard (default tab)
  /home/dashboard
  /home/study-plan
/exam                 → Exam tab shell
  /exam/config        → Choose subject, type, difficulty
  /exam/session/:id   → Active exam (fullscreen, no bottom nav)
  /exam/result/:id    → Result + analytics
/upload               → Upload tab shell
  /upload/chapter     → PDF / chapter upload
  /upload/handwritten → Image upload for OCR
  /upload/history     → Past uploads & explanations
/library              → Offline library (saved notes & quizzes)
/plan                 → Study plan tab shell
  /plan/create        → Input form
  /plan/detail/:id    → View generated plan
/settings             → App settings, language toggle, cache clear
```

### Navigation Rules

- **Bottom Nav** uses `StatefulShellRoute` so each tab maintains its own stack.
- **Exam session** is a full-screen route that hides bottom nav (pushed above shell).
- **Back button** on Android respects nested stack; at root of tab, back exits app.
- **Auth guard** redirect: if `student` box is empty → force `/auth/onboarding`.

---

## 7. Theme System

### Goal: Modern, Minimal, AI-First, Premium, Student-Friendly

- **No default Material 3 look.**
- Custom `ColorScheme` built from tokens, not from `seedColor`.
- Soft gradients, glassmorphism-lite cards, generous rounded corners.

### Color Tokens (`theme/color_tokens.dart`)

```dart
class AppColors {
  static const primary = Color(0xFF6366F1);      // Indigo 500
  static const primaryDark = Color(0xFF4F46E5);  // Indigo 600
  static const accent = Color(0xFF22D3EE);       // Cyan 400
  static const success = Color(0xFF34D399);      // Emerald 400
  static const warning = Color(0xFFFBBF24);      // Amber 400
  static const danger = Color(0xFFF87171);       // Red 400
  static const surface = Color(0xFFF8FAFC);      // Slate 50
  static const surfaceDark = Color(0xFF0F172A);  // Slate 900
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBgDark = Color(0xFF1E293B);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
}
```

### Typography (`theme/text_theme.dart`)

- **Primary:** Inter (English UI elements)
- **Bengali:** Noto Sans Bengali (all Bengali explanations, questions)
- Scale: displayLarge → 32, headlineMedium → 24, bodyLarge → 16, labelSmall → 11

### Gradients (`theme/gradients.dart`)

```dart
class AppGradients {
  static const hero = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardShine = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
  );
  static const success = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );
}
```

### Widget Themes

- **Cards:** `elevation: 0`, `shape: RoundedRectangleBorder(borderRadius: 16)`, soft shadow via `BoxShadow` with low opacity.
- **Buttons:** `ElevatedButton` → rounded capsule shape, gradient background via `Ink` decoration.
- **AppBar:** Transparent, `elevation: 0`, title centered, gradient background if hero section.

### Dark Mode

- Full dark theme via `ThemeData.dark()` customized with dark tokens.
- System follows OS setting; user can override in settings.
- Hive persists user preference (`isDarkMode` key).

---

## 8. Reusable Widget Strategy

### Atomic Design

We organize shared widgets in `common_widgets/` using Atomic Design:

| Level | Example | Responsibility |
|---|---|---|
| **Atom** | `AppButton`, `AppIcon`, `ShimmerBox` | Smallest indivisible UI piece; no business logic |
| **Molecule** | `AppCard`, `AppTextField`, `AppChip` | Composes 2–3 atoms; handles local interactions |
| **Organism** | `AppBar`, `BottomNavBar`, `EmptyState` | Complex reusable section; may take callbacks |
| **Template** | `ScaffoldWithNav`, `ResponsiveLayout` | Page-level layout skeletons |

### Key Reusable Widgets

1. **`AppCard`** — Glass-like container with configurable gradient, shadow, padding, and `onTap` ripple.
2. **`AppButton`** — Primary (gradient), Secondary (outlined), Ghost (text only). All support loading state.
3. **`ShimmerLoading`** — Wraps any widget; shows shimmer during `AsyncLoading`.
4. **`EmptyState`** — Illustration + headline + subtitle + CTA button.
5. **`ErrorState`** — Icon + error message + retry button. Accepts `Failure` object.
6. **`ResponsiveLayout`** — Switches between mobile (single column) and tablet (side panel) layouts.

### Feature-Local Widgets

Each feature's `presentation/widgets/` holds widgets used only within that feature. They may compose common atoms/molecules. They **never** import widgets from other features directly; shared components live in `common_widgets`.

---

## 9. Screen Descriptions

### Auth Flow

| Screen | Purpose |
|---|---|
| `OnboardingScreen` | Welcome carousel, class selection (8/9/10), student name. No email/password needed (local identity). |

### Home / Dashboard

| Screen | Purpose |
|---|---|
| `DashboardScreen` | Topic-wise accuracy ring charts, weak chapter list, daily streak flame, improvement line graph (fl_chart), quick-action FABs ("Start Exam", "Upload Chapter", "Create Plan"). |
| `StudyPlanDetailScreen` | View today's tasks, revision slots, countdown banner to exam. |

### AI Study Companion

| Screen | Purpose |
|---|---|
| `ChapterUploadScreen` | Drag-style upload area for PDF / image. Shows recent uploads list. |
| `ExplanationResultScreen` | Displays AI explanation in selected mode. Supports text-to-speech (future). Bottom bar to switch modes. |

### Smart Exam

| Screen | Purpose |
|---|---|
| `ExamConfigScreen` | Subject, chapter, question type (MCQ/CQ/Short), difficulty slider, SSC/HSC style toggle, timer setting. |
| `ExamScreen` | Full-screen exam. Shows question card, MCQ options or text field, countdown timer, progress dots. |
| `ExamResultScreen` | Score circle animation, per-question breakdown, correct answers, explanation toggles, "Practice Weak Topics" CTA. |
| `ExamHistoryScreen` | List of past exams with score badges, dates, and filters. |

### Handwritten Evaluation

| Screen | Purpose |
|---|---|
| `UploadScreen` | Camera/gallery picker, image preview crop, subject/question input. |
| `EvaluationResultScreen` | OCR-extracted text side-by-side with image, AI score badge, feedback bullet points, grammar tips. |

### Study Plan Generator

| Screen | Purpose |
|---|---|
| `PlanInputScreen` | Form: exam date picker, weak subjects multi-select, daily study hours slider, preferred study time (morning/evening). |
| `PlanDetailScreen` | Scrollable timeline of daily tasks, revision slots, mock test markers. Tapping a day opens `TaskChecklistScreen`. |
| `TaskChecklistScreen` | Checkable tasks for a single day with time slots. |

### Offline Library

| Screen | Purpose |
|---|---|
| `LibraryScreen` | Tabbed view: Saved Notes & Saved Quizzes. Swipe to delete, pull to refresh sync status. |
| `NoteReaderScreen` | Full-screen reader for saved AI explanations. |

---

## 10. Feature-Module Mapping

| App Feature | Feature Module | Domain Entities | Main Screens |
|---|---|---|---|
| AI Study Companion | `ai_study_companion` | `Chapter`, `Explanation` | Upload, Result |
| Weakness Detection Dashboard | `weakness_dashboard` | `TopicStat`, `WeakArea`, `Streak` | Dashboard |
| Smart Exam Mode | `smart_exam` | `Question`, `ExamSession`, `ExamResult` | Config, Session, Result, History |
| Offline / Low Internet | `offline_library` | `SavedNote`, `SavedQuiz` | Library, Reader |
| Handwritten Answer Evaluation | `handwritten_eval` | `ScannedAnswer`, `EvaluationResult` | Upload, Result |
| AI Study Plan Generator | `study_plan` | `StudyPlan`, `DailyTask`, `RevisionSlot` | Input, Detail, Checklist |
| Onboarding / Identity | `auth` | `Student` | Onboarding |

---

## 11. Data Flow Explanation

### Typical Feature Data Flow (e.g., Generate Explanation)

```
┌─────────────┐     trigger     ┌──────────────────┐
│   Widget    │ ──────────────► │  StateNotifier   │
│  (Button)   │                 │ (Controller)     │
└─────────────┘                 └────────┬─────────┘
                                         │
                                         │ calls
                                         ▼
┌─────────────┐                 ┌──────────────────┐
│   Widget    │ ◄────────────── │   Repository     │
│  rebuilds   │   AsyncValue    │   (Impl)         │
└─────────────┘                 └────────┬─────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
            ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
            │   Remote    │     │    Local    │     │   SyncQueue │
            │  DataSource │     │  DataSource │     │  (offline)  │
            │    (Dio)    │     │   (Hive)    │     │   (Hive)    │
            └─────────────┘     └─────────────┘     └─────────────┘
```

### Exam Session Data Flow (Real-time Critical)

1. User configures exam → `ExamConfigScreen` builds `ExamConfig` entity.
2. Controller calls `ExamRepository.generateExam(config)`.
3. Repository fetches questions from remote → maps to `Question` entities.
4. Controller stores session in Hive-backed `ExamSession` box (survives app kill).
5. `ExamScreen` listens to `examSessionProvider`; every answer selection updates local session immediately.
6. On submit: repository sends answers to `/exam/evaluate` → returns `ExamResult`.
7. Result cached locally; UI navigates to `ExamResultScreen`.

---

## 12. Mock-First Development Strategy

### Goal: Frontend can be built and demo'd before backend endpoints are fully ready.

### Mock Implementations

Every repository interface has a `Mock` implementation in `test/mocks/` that can be injected via Riverpod overrides:

```dart
class MockStudyCompanionRepository implements StudyCompanionRepository {
  @override
  Future<Explanation> getExplanation({...}) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    return Explanation(
      content: _mockBengaliExplanation,
      mode: mode,
      generatedAt: DateTime.now(),
    );
  }
}
```

### Mock Data Files

- `test/fixtures/explanation_easy_bn.json`
- `test/fixtures/explanation_eli10.json`
- `test/fixtures/mock_exam_mcq.json`
- `test/fixtures/mock_dashboard_stats.json`

### Toggle Strategy

A compile-time constant `kUseMockData` (or runtime flag in debug settings) switches all repository providers to mock implementations:

```dart
final studyCompanionRepoProvider = Provider<StudyCompanionRepository>((ref) {
  if (kUseMockData) return MockStudyCompanionRepository();
  return StudyCompanionRepositoryImpl(...);
});
```

### Benefits

- Designers and product owners can review UI without backend.
- Unit tests run deterministically with mock data.
- Integration tests can toggle mock mode per scenario.

---

## 13. Integration Strategy with FastAPI Backend

### Base URL Configuration

```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator localhost
  );
}
```

### Endpoint Mapping (assumed FastAPI contract)

| Feature | Method | Endpoint | Body / Params |
|---|---|---|---|
| Auth | POST | `/auth/register` | `{name, class}` |
| Auth | GET | `/auth/me` | — |
| Study Companion | POST | `/ai/explain` | `{chapter_id, mode}` |
| Study Companion | POST | `/ai/upload-chapter` | `multipart/form-data` (PDF) |
| Exam | POST | `/exam/generate` | `{subject, chapter, type, difficulty, count}` |
| Exam | POST | `/exam/evaluate` | `{session_id, answers[]}` |
| Dashboard | GET | `/analytics/dashboard` | `?student_id=` |
| Dashboard | GET | `/analytics/streak` | `?student_id=` |
| Handwritten | POST | `/ocr/evaluate` | `multipart/form-data` (image + meta) |
| Study Plan | POST | `/plan/generate` | `{exam_date, weak_subjects[], daily_hours}` |
| Study Plan | GET | `/plan/:id` | — |
| Library | POST | `/library/save` | `{type, content}` |
| Library | GET | `/library/list` | `?type=` |

### Contract-First Updates

- Backend OpenAPI spec (`openapi.json`) is pulled periodically.
- DTOs are generated manually (or via `openapi_generator`) from spec to stay in sync.
- Integration tests hit a local FastAPI instance (`docker-compose up` in project root).

---

## 14. Local Storage Strategy

### Database: **Hive** (lightweight, fast, no native dependencies)

- All entities stored as Hive `TypeAdapter` generated classes.
- Adapters are auto-generated via `hive_generator` + `build_runner`.

### Box Strategy

| Box Name | Content | Lazy? |
|---|---|---|
| `student` | `StudentModel` (single record) | No |
| `chapters` | `ChapterModel` list | No |
| `explanations` | `ExplanationModel` keyed by chapter+mode | No |
| `exam_sessions` | `ExamSessionModel` keyed by sessionId | No |
| `exam_results` | `ExamResultModel` list | No |
| `dashboard_stats` | `TopicStatModel` + `WeakAreaModel` | No |
| `study_plans` | `StudyPlanModel` keyed by planId | No |
| `saved_notes` | `SavedNoteModel` list | No |
| `saved_quizzes` | `SavedQuizModel` list | No |
| `sync_queue` | `SyncOperationModel` FIFO queue | Yes (lazy) |
| `settings` | `AppSettings` (theme, language, cache TTL) | No |

### Migration Strategy

- `Hive` box version numbers tracked in `storage_keys.dart`.
- On app start, `main()` runs migration callbacks if version mismatch detected.
- Migrations are additive; old data is lazy-deleted.

### Encryption

- Sensitive data (if any in future) uses Hive's built-in AES encryption with key stored in `flutter_secure_storage`.
- Current scope: no PII beyond name/class, so encryption is optional.

---

## 15. AI Feature Integration Architecture

### Unified AI Service Gateway

All AI-powered features (`ai_study_companion`, `smart_exam`, `handwritten_eval`, `study_plan`) funnel through the same remote infrastructure, but each feature has its own domain abstraction.

```
┌─────────────────────────────────────────────────────────────┐
│                      AI Features                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Explain  │ │  Exam    │ │ Handwrit.│ │  Plan    │       │
│  │ Companion│ │ Generator│ │ Evaluate │ │ Generator│       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
│       │            │            │            │              │
│       └────────────┴────────────┴────────────┘              │
│                          │                                  │
│                    Feature Repositories                      │
│                          │                                  │
│                    Dio HTTP Client                           │
│                          │                                  │
│                   FastAPI Backend                            │
│              (LLM / RAG / OCR orchestration)                 │
└─────────────────────────────────────────────────────────────┘
```

### Explanation Modes

| Mode Key | Display Name | Backend Prompt Style |
|---|---|---|
| `easy_bn` | Easy Bengali | `explain_in_easy_bengali` |
| `easy_en` | Easy English | `explain_in_easy_english` |
| `eli10` | Explain Like I'm 10 | `explain_like_im_10` |
| `summary` | Summary | `summarize_chapter` |
| `important_questions` | Important Questions | `generate_important_questions` |
| `common_mistakes` | Common Mistakes | `list_common_mistakes` |
| `exam_tips` | Exam Tips | `generate_exam_tips` |

- UI shows mode as selectable chips; tapping switches content by calling the same endpoint with different `mode`.
- Previous modes for a chapter are cached so switching is instant.

### Exam Generation

- `ExamConfig` entity sent to `/exam/generate`.
- Backend uses RAG over uploaded chapters + LLM to generate questions.
- Response includes `questions[]`, `session_id`, `total_marks`, `duration_seconds`.

### Marks Prediction

- After each exam, backend returns `predicted_ssc_score` based on historical performance curve.
- Stored in `ExamResult` entity; displayed on dashboard as trend line.

---

## 16. OCR Flow Explanation

### Purpose: Evaluate handwritten Bangladeshi student answers via image upload.

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Student   │───►│  Pick Image │───►│   Preview   │───►│  Submit to  │
│             │    │  (camera /  │    │  & Crop     │    │   Backend   │
│             │    │   gallery)  │    │   (optional)│    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └──────┬──────┘
                                                                 │
                                                                 ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Display   │◄───│  AI Grading │◄───│   FastAPI   │◄───│   Upload    │
│   Result    │    │  + Feedback │    │   (OCR +    │    │   Image     │
│             │    │             │    │   LLM eval) │    │   (multipart)
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Mobile-Side Steps

1. **Image Capture** — `image_picker` with `source: ImageSource.camera` or `.gallery`.
2. **Compression** — Compress image to ≤ 2MB using `flutter_image_compress` before upload (optional dependency).
3. **Multipart Upload** — Dio `FormData`:
   ```dart
   FormData.fromMap({
     'image': await MultipartFile.fromFile(path, filename: 'answer.jpg'),
     'subject': subject,
     'question_text': question,
   })
   ```
4. **Progress UI** — Circular progress with "AI is reading your handwriting...".
5. **Result Parsing** — Backend returns:
   ```json
   {
     "extracted_text": "...",
     "score": 7.5,
     "max_score": 10,
     "feedback": ["Good structure", "Missed key point 3"],
     "grammar_notes": ["Spelling error in paragraph 2"],
     "improvement_tips": ["Use more examples"]
   }
   ```
6. **Local Save** — Result stored in Hive for offline review later.

### UX Considerations

- Allow retake before upload.
- Show extracted text in editable text field so student can correct OCR mistakes before final evaluation (optional).
- Highlight grammar errors inline with `flutter_highlight` or custom spans.

---

## 17. Dashboard Analytics Architecture

### Data Model

```dart
@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    required List<TopicStat> topicStats,
    required List<WeakArea> weakAreas,
    required Streak streak,
    required List<ScorePoint> scoreHistory,
    required double predictedScore,
  }) = _DashboardData;
}
```

### Charts (`fl_chart`)

1. **Accuracy Ring Chart** — `PieChart` showing per-topic accuracy percentages.
   - Color-coded: Green (>80%), Yellow (50-80%), Red (<50%).
2. **Improvement Line Graph** — `LineChart` with dates on X-axis, exam scores on Y-axis.
   - Trend line + predicted score dotted projection.
3. **Weak Topic Bar Chart** — `BarChart` showing attempts vs. accuracy per weak topic.
4. **Streak Calendar Heatmap** — Custom `GridView` showing daily activity (similar to GitHub contributions graph).

### State & Refresh

- `dashboardProvider` is a `FutureProvider` that fetches from `/analytics/dashboard`.
- `streakProvider` is a lightweight `StreamProvider` that updates daily.
- Pull-to-refresh on `DashboardScreen` invalidates both providers.
- Background refresh every 5 minutes via `Workmanager` (future enhancement).

### Predicted Score Calculation

- Backend returns `predicted_score` based on linear regression over past exam scores.
- Frontend renders it as a "confidence range" (e.g., "85 ± 5") rather than a single number to avoid false precision.

---

## 18. Feature Implementation Order

We implement features in **vertical slices** (full stack per feature: domain → data → presentation → UI). This allows each feature to be demoed independently.

| Phase | Feature | Priority | Why First? |
|---|---|---|---|
| **Phase 1** | Auth / Onboarding | P0 | Required before any personalization |
| **Phase 1** | App Shell + Theme + Navigation | P0 | Foundation for all screens |
| **Phase 1** | AI Study Companion (Upload + Explain) | P0 | Core value proposition |
| **Phase 2** | Smart Exam (MCQ only first) | P0 | High student engagement |
| **Phase 2** | Exam Result + Auto Evaluation | P0 | Completes exam loop |
| **Phase 3** | Weakness Dashboard | P1 | Drives retention via feedback loops |
| **Phase 3** | Offline Library (Save notes & quizzes) | P1 | Needed for low-connectivity users |
| **Phase 4** | Handwritten Evaluation (OCR) | P1 | Differentiator feature |
| **Phase 4** | Study Plan Generator | P1 | Long-term engagement |
| **Phase 5** | Smart Exam (CQ + Short Answer) | P2 | Expand question types |
| **Phase 5** | Adaptive Difficulty + SSC/HSC Style | P2 | Exam realism |
| **Phase 5** | Deep Links + Share | P2 | Growth feature |
| **Phase 6** | Polish: Animations, Haptics, TTS | P3 | Premium feel |
| **Phase 6** | Tablet / Responsive Layout | P3 | Accessibility |

### Phase 1 Deliverable Criteria

- [ ] User can onboard, select class.
- [ ] User can upload a PDF/image.
- [ ] User can see AI explanation in at least 2 modes.
- [ ] App works offline after first load (cached explanations).

---

## Appendix: Tech Stack Versions (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Routing
  go_router: ^14.8.1

  # Networking
  dio: ^5.8.0+1

  # Serialization
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI
  cached_network_image: ^3.4.1
  fl_chart: ^0.70.2
  image_picker: ^1.1.2
  shimmer: ^3.0.0
  google_fonts: ^6.2.1

  # Utilities
  intl: ^0.20.2
  path_provider: ^2.1.5
  connectivity_plus: ^6.1.3
  equatable: ^2.0.7

  # Localization
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  freezed: ^2.5.8
  json_serializable: ^6.9.4
  hive_generator: ^2.0.1
  riverpod_generator: ^2.6.5
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.5
```

---

*End of README_FRONTEND.md. No Flutter code should be written until this document is reviewed and agreed upon.*
