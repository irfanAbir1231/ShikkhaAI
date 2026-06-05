import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../backend")))

from dotenv import load_dotenv
load_dotenv("rag/.env")
load_dotenv("backend/.env")

# Enable RAG integration in-process for this test
os.environ["MOCK_MODE"] = "false"
os.environ["RAG_INPROCESS"] = "true"

from app.db.session import SessionLocal, init_db
from app.db.models import Student
from app.services.analytics_service import AnalyticsService

def test_backend_topics_merge():
    db = SessionLocal()
    # Let's find or create a dummy student with grade_level = "8"
    student = db.query(Student).filter(Student.grade_level == "8").first()
    if not student:
        student = Student(
            name="Test Student",
            email="test_student_merge@shikkhaai.com",
            grade_level="8",
        )
        db.add(student)
        db.commit()
        db.refresh(student)
        
    print(f"Testing merge for student {student.id} (grade {student.grade_level})...")
    service = AnalyticsService()
    res = service.get_topics(db, student)
    
    print(f"Total topics returned by backend service: {res['total_topics']}")
    print(f"Subjects in overview: {[s['subject'] for s in res['subjects']]}")
    
    for subject_data in res['subjects']:
        print(f"\nSubject: {subject_data['subject']} has {len(subject_data['topics'])} topics:")
        for t in subject_data['topics'][:5]:
            print(f"  - ID: {t['id']}, Name: {t['name']}, Completed: {t['is_completed']}")
            
    db.close()

if __name__ == "__main__":
    init_db()
    test_backend_topics_merge()
