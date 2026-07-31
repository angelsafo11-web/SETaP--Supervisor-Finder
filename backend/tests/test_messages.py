"""
Tests for routers/messages.py - in-app messaging, only allowed once a
supervision match has been Accepted.
"""
from .conftest import register_and_login_staff, register_and_login_student


def _make_accepted_match(client):
    """Helper: registers a staff+student, creates an idea, and accepts the request."""
    staff_headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    student_headers = register_and_login_student(client)
    req = client.post("/students/express-interest", headers=student_headers,
                       json={"project_id": idea["project_id"]}).json()
    client.post(f"/staff/requests/{req['request_id']}/respond", headers=staff_headers,
                json={"decision": "accept"})
    return staff_headers, student_headers


def test_message_blocked_before_match_accepted(client):
    staff_headers = register_and_login_staff(client)
    student_headers = register_and_login_student(client)

    response = client.post("/messages/send", headers=student_headers,
                            json={"other_user_id": 1, "content": "Hi!"})
    assert response.status_code == 403


def test_student_can_message_after_acceptance(client):
    staff_headers, student_headers = _make_accepted_match(client)

    response = client.post("/messages/send", headers=student_headers,
                            json={"other_user_id": 1, "content": "Hi Dr Smith!"})
    assert response.status_code == 201
    assert response.json()["sender_role"] == "student"
    assert response.json()["content"] == "Hi Dr Smith!"


def test_staff_can_message_after_acceptance(client):
    staff_headers, student_headers = _make_accepted_match(client)

    response = client.post("/messages/send", headers=staff_headers,
                            json={"other_user_id": 1, "content": "Welcome aboard!"})
    assert response.status_code == 201
    assert response.json()["sender_role"] == "staff"


def test_conversation_shows_both_directions_in_order(client):
    staff_headers, student_headers = _make_accepted_match(client)

    client.post("/messages/send", headers=student_headers, json={"other_user_id": 1, "content": "Hi!"})
    client.post("/messages/send", headers=staff_headers, json={"other_user_id": 1, "content": "Hello!"})

    student_view = client.get("/messages/conversation/1", headers=student_headers)
    assert student_view.status_code == 200
    assert len(student_view.json()) == 2
    assert student_view.json()[0]["content"] == "Hi!"
    assert student_view.json()[1]["content"] == "Hello!"

    staff_view = client.get("/messages/conversation/1", headers=staff_headers)
    assert len(staff_view.json()) == 2


def test_empty_message_rejected(client):
    staff_headers, student_headers = _make_accepted_match(client)
    response = client.post("/messages/send", headers=student_headers,
                            json={"other_user_id": 1, "content": ""})
    assert response.status_code == 422
