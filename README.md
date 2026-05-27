1. Register & Login

Student registers with name, email, grade level, password. Gets back a JWT token. Uses that token for everything after.

2. Generate an Exam

Student picks a subject, topic, difficulty, number of questions. The system calls Gemini (or RAG service) to generate MCQ + short answer questions from the curriculum.

3. Submit the Exam

Student submits answers. The system automatically:

Grades all MCQs
Grades short answers via Gemini (partial credit supported)
Updates the student's topic performance history
Detects weak topics (score below 60% or inconsistent)
Computes a readiness score
NEW: Generates personalized study notes for every weak topic via Gemini and saves them to the library
4. Check Dashboard

Student sees:

overall readiness score
trend
weak subjects
study streak
weekly activity
recent quiz results
improvement over weeks
AI recommendations
5. Deep Analytics

Student sees:

per-topic accuracy with trends
weak chapters ranked by severity
suggested actions
full improvement history across attempts
30-day activity calendar
practice suggestions
6. Topics Tab

Shows all curriculum topics grouped by subject with completion percentage.

If curriculum seed exists → full catalog including untouched topics
Otherwise → fallback to attempt history
7. Notes / Library

Students can:

View AI-generated notes from exams
Create manual notes
Filter by topic/source
Delete notes
 What Changed From Before
Before	After
No dashboard endpoint	GET /student/{id}/dashboard works
No analytics endpoint	GET /student/{id}/analytics works
No topics endpoint	GET /student/{id}/topics works
No notes system	Full CRUD at /notes
Exam submit only returned results	Now generates study notes automatically
No learning memory	Performance history tracking added
No schema support	Note / StudyPlan / CurriculumTopic tables added
