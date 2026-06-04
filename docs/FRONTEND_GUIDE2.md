# Frontend Guide 2 — Planned Features Implementation

## 1. Curriculum Autocomplete in Exam Config

### New Providers
- `chaptersProvider` — fetches chapters for selected subject+class
- `topicsProvider` — fetches topics for selected subject+class+chapter

### ExamConfigScreen Changes
Replace the free-text topic TextField with:
1. Chapter dropdown (enabled after subject+class selected)
2. Topic Autocomplete (enabled after chapter selected)

### Key Widget
```dart
Autocomplete<String>(
  optionsBuilder: (value) => _filteredTopics(value.text),
  onSelected: (selection) => _topicController.text = selection,
)
```

## 2. Topics Tab Chapter-wise Grouping

### Model Changes
- `SubjectTopics` now contains `List<ChapterTopics>` instead of `List<TopicItem>`
- `ChapterTopics` contains chapter metadata + topic list

### UI Changes
- `SubjectTopicsCard` uses nested `ExpansionTile`s:
  - Level 1: Subject header
  - Level 2: Chapter tiles (with progress bar)
  - Level 3: Topic list tiles

### Visual Status Indicators
- Green checkmark: completed (>=60%)
- Orange pending: attempted but not completed
- Grey circle: unattempted
- "Practice" button on unattempted topics

## 3. Focus Garden Gamification

### State Management
- `gamificationProvider` — fetches `/gamification/me`
- `focusSessionProvider` — manages active focus session state

### FocusSessionScreen
- Full-screen timer with `WidgetsBindingObserver` for app lifecycle
- Animated plant that grows with timer progress
- Auto-cancel after 3 tab switches
- Completion reward: points + coins + plant growth

## 4. Exam Anti-Cheat

### Tab Switch Detection
- `ExamSessionScreen` implements `WidgetsBindingObserver`
- `didChangeAppLifecycleState` tracks `AppLifecycleState.paused`
- Warning dialog on 1st/2nd switch
- Auto-submit on 3rd switch
- Tab switch count sent with exam submission

## 5. Study Spaces

### Feature Structure
```
lib/features/spaces/
├── data/models/space_model.dart
├── presentation/providers/spaces_provider.dart
├── presentation/screens/
│   ├── spaces_list_screen.dart
│   ├── space_detail_screen.dart
│   └── create_space_screen.dart
```

### Key Flows
1. Create space → POST /spaces
2. Upload PDF → POST /spaces/{id}/upload (multipart)
3. Chat with space → Study companion sends `space_id`

## 6. Teacher Dashboard

### Feature Structure
```
lib/features/teacher/
├── presentation/screens/
│   ├── teacher_login_screen.dart
│   ├── teacher_dashboard_screen.dart
│   └── classroom_detail_screen.dart
```

### Weak-Topic Heatmap
- `Wrap` of colored containers
- Color intensity = (weak_students / total_students)
- Green → Yellow → Red gradient

## 7. Build Runner

After adding any new models with `freezed`/`json_serializable`:
```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Working with Mocks (Parallel Development)

During Phase 1, all data is mocked. Each provider should have a `mock` flag:

```dart
final chaptersProvider = FutureProvider.family<List<Chapter>, ...>((ref, params) async {
  const useMock = true; // Flip to false during Phase 3
  if (useMock) {
    return _mockChapters[params.subject] ?? [];
  }
  final api = ref.read(apiServiceProvider);
  final data = await api.get('/curriculum/${params.classLevel}/${params.subject}/chapters');
  return (data['data'] as List).map((e) => Chapter.fromJson(e)).toList();
});
```

## Exam Config Screen Architecture

```
ExamConfigScreen (StatefulWidget)
├── SubjectSelector (ChoiceChips)
├── ClassSelector (ChoiceChips)
├── ChapterDropdown (DropdownButtonFormField)
│   └── watches chaptersProvider
├── TopicAutocomplete (Autocomplete<String>)
│   └── watches topicsProvider
├── DifficultySelector
├── ExamTypeSelector
└── StartExamButton
```

## Topics Tab Architecture

```
TopicsShellScreen
├── TopicsOverallProgressCard
├── SubjectFilterChips
└── SubjectTopicsCard (per subject)
    └── ExpansionTile (per chapter)
        └── TopicListTile (per topic)
```

## Focus Session Lifecycle

```
User taps "Start Focus Session"
→ POST /gamification/focus-session/start
→ Navigate to FocusSessionScreen
→ Start countdown timer
→ WidgetsBindingObserver tracks app pauses
→ Timer completes OR user cancels
→ POST /gamification/focus-session/{id}/complete
→ Show reward animation
→ Navigate back
```

## Study Spaces Architecture

```
SpacesListScreen
├── SpaceCard (grid)
└── FAB → CreateSpaceScreen

SpaceDetailScreen
├── SpaceInfoHeader
├── DocumentList
├── UploadButton → FilePicker → POST /spaces/{id}/upload
└── ChatButton → StudyCompanionScreen (with space_id)
```
