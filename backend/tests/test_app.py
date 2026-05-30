"""Startup, health, and core API smoke tests against the real app (mock mode)."""


def test_health_endpoint(client):
    res = client.get("/health")
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert body["data"]["status"] == "ok"


def test_openapi_loads(client):
    # Proves every router imported and registered without error.
    res = client.get("/openapi.json")
    assert res.status_code == 200
    paths = res.json()["paths"]
    for expected in ("/student/register", "/student/login", "/exam/generate", "/health"):
        assert expected in paths


def test_register_login_and_generate_exam_flow(client):
    import uuid

    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post(
        "/student/register",
        json={
            "name": "Test Student",
            "email": email,
            "grade_level": "8",
            "password": "secret123",
        },
    )
    assert reg.status_code in (200, 201), reg.text
    login = client.post("/student/login", json={"email": email, "password": "secret123"})
    assert login.status_code == 200, login.text
    token = login.json()["data"]["access_token"]
    student_id = login.json()["data"]["student"]["id"]

    headers = {"Authorization": f"Bearer {token}"}
    exam = client.post(
        "/exam/generate",
        headers=headers,
        json={
            "student_id": student_id,
            "subject": "math",
            "class_level": "8",
            "topic": "Algebra",
            "difficulty": "easy",
            "num_questions": 3,
        },
    )
    assert exam.status_code == 200, exam.text
    questions = exam.json()["data"]["questions"]
    assert len(questions) >= 1


def test_unauthorized_request_rejected(client):
    res = client.post(
        "/exam/generate",
        json={"student_id": 1, "subject": "math", "class_level": "8"},
    )
    assert res.status_code in (401, 403)
