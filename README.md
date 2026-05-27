# 📚 ShikkhaAI Backend

ShikkhaAI is a backend system for a Bangladeshi student exam preparation platform powered by AI (Gemini + optional RAG). It provides adaptive learning, automated evaluation, and personalized study support.

---

##  What the App Does Now

### 👤 User Journey

---

### 1. Register & Login

Students register with:
- Name  
- Email  
- Grade level  
- Password  

They receive a **JWT token**, which is used for all authenticated requests.

---

### 2. Generate an Exam

Students select:
- Subject  
- Topic  
- Difficulty  
- Number of questions  

The system generates:
- MCQs  
- Short-answer questions  

Generation is powered by:
- Gemini API (primary)
- Optional RAG service (curriculum-based)

---

### 3. Submit the Exam

After submission, the system automatically:

- Grades all MCQs  
- Grades short answers via Gemini (supports partial credit)  
- Updates topic performance history  
- Detects weak topics (score < 60% or inconsistent performance)  
- Computes a readiness score  
- Generates personalized study notes for weak topics using Gemini  
- Saves notes to the library  

---

### 4. Check Dashboard

Students can view:

- Overall readiness score  
- Performance trend  
- Weak subjects  
- Study streak  
- Weekly activity  
- Recent quiz results  
- AI recommendations  

---

### 5. Deep Analytics

Provides detailed insights:

- Per-topic accuracy trends  
- Weak chapters ranked by severity  
- Suggested improvement actions  
- Full performance history  
- 30-day activity calendar  
- Practice recommendations  

---

### 6. Topics Tab

Displays curriculum structure:

- Subjects grouped by class level  
- Topic completion percentage  

Behavior:
- If curriculum seed exists → full catalog shown  
- Otherwise → fallback to attempt history  

---

### 7. Notes / Library

Students can:

- View AI-generated notes  
- Create manual notes  
- Filter by topic/source  
- Delete notes  

---

##  What Changed From Before

| Feature | Before | After |
|----------|--------|--------|
| Dashboard | No endpoint | `GET /student/{id}/dashboard` added |
| Analytics | Not available | `GET /student/{id}/analytics` added |
| Topics | Not available | `GET /student/{id}/topics` added |
| Notes system | Not present | Full CRUD at `/notes` |
| Exam submission | Only returns score | Now generates study notes automatically |
| Learning memory | None | Performance tracking added |
| Database schema | Basic tables | Added Note / StudyPlan / CurriculumTopic |

---

##  Summary

ShikkhaAI is now a full AI-powered adaptive learning system:

- Exam generation ✔  
- Auto grading ✔  
- Weakness detection ✔  
- Personalized notes ✔  
- Learning analytics ✔  
- Curriculum-aware topics ✔  