from pydantic import BaseModel, ConfigDict


class ReadinessData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    overall: float
    trend: float
    breakdown: dict[str, float]


class WeakSubject(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str
    accuracy: float
    color: str
    icon: str


class StreakData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    current_streak: int
    longest_streak: int
    weekly_activity: list[bool]
    last_study_date: str | None


class ImprovementPoint(BaseModel):
    model_config = ConfigDict(extra="forbid")
    week: str
    score: float


class TopicAccuracy(BaseModel):
    model_config = ConfigDict(extra="forbid")
    topic: str
    accuracy: float
    total_questions: int


class RecentQuiz(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str
    title: str
    subject: str
    score: int
    total: int
    date: str
    time_taken: str


class Recommendation(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str
    title: str
    description: str
    type: str
    priority: str


class DashboardData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    readiness: ReadinessData
    weak_subjects: list[WeakSubject]
    streak: StreakData
    improvement: list[ImprovementPoint]
    topic_accuracy: list[TopicAccuracy]
    recent_quizzes: list[RecentQuiz]
    recommendations: list[Recommendation]


# ─── Analytics ───────────────────────────────────────────────────────────────

class TopicAccuracyDetail(BaseModel):
    model_config = ConfigDict(extra="forbid")
    topic: str
    chapter: str
    subject: str
    accuracy: float
    total_questions: int
    correct_answers: int
    trend: float
    last_attempted: str | None


class WeakChapter(BaseModel):
    model_config = ConfigDict(extra="forbid")
    chapter_name: str
    subject: str
    accuracy: float
    weakness_rank: int
    related_topics: list[str]
    suggested_action: str
    trend: float
    time_spent_minutes: int


class ImprovementHistoryPoint(BaseModel):
    model_config = ConfigDict(extra="forbid")
    date: str
    overall_score: float
    topic_scores: dict[str, float]
    exam_id: str


class DailyActivity(BaseModel):
    model_config = ConfigDict(extra="forbid")
    date: str
    is_active: bool
    performance_score: float | None
    questions_answered: int
    study_minutes: int


class AnalyticsStreakData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    current_streak: int
    longest_streak: int
    last_30_days: list[DailyActivity]


class PracticeSuggestion(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str
    title: str
    description: str
    topic: str
    type: str
    difficulty: str
    estimated_minutes: int
    potential_impact: float
    subject: str


class SubtopicAccuracyDetail(BaseModel):
    model_config = ConfigDict(extra="forbid")
    subtopic_id: int
    name: str
    topic: str
    chapter: str
    subject: str
    accuracy: float
    total_questions: int
    correct_answers: int
    trend: float
    last_attempted: str | None
    is_mastered: bool


class AnalyticsData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    topic_accuracy: list[TopicAccuracyDetail]
    weak_chapters: list[WeakChapter]
    improvement_history: list[ImprovementHistoryPoint]
    streak_data: AnalyticsStreakData
    practice_suggestions: list[PracticeSuggestion]
    average_accuracy: float
    total_questions_attempted: int
    total_study_minutes: int
    subtopic_accuracy: list[SubtopicAccuracyDetail] = []
    weak_subtopics: list[SubtopicAccuracyDetail] = []
    mastered_subtopics: list[SubtopicAccuracyDetail] = []


# ─── Topics ──────────────────────────────────────────────────────────────────

class TopicItem(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: str
    name: str
    completion_percentage: float
    attempts_count: int
    last_score: float | None
    last_attempted: str | None
    is_completed: bool


class SubjectTopics(BaseModel):
    model_config = ConfigDict(extra="forbid")
    subject: str
    icon_name: str
    total_topics: int
    completed_topics: int
    overall_completion_percentage: float
    topics: list[TopicItem]


class TopicsData(BaseModel):
    model_config = ConfigDict(extra="forbid")
    subjects: list[SubjectTopics]
    total_topics: int
    completed_topics: int
