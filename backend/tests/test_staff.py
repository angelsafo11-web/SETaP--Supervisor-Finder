"""
Tests for routers/staff.py - UC1 (manage project ideas), UC2 (availability),
UC5 (respond to requests), and past submissions.
"""
from .conftest import register_and_login_staff, register_and_login_student


def test_view_own_profile(client):
    headers = register_and_login_staff(client)
    response = client.get("/staff/me", headers=headers)
    assert response.status_code == 200
    assert response.json()["name"] == "Dr Smith"
    assert response.json()["accepting_students"] is True
    assert response.json()["max_capacity"] == 3


# ---------- UC1: Manage Project Ideas ----------

def test_add_project_idea(client):
    headers = register_and_login_staff(client)
    response = client.post("/staff/projects", headers=headers, json={
        "title": "AI Matching", "description": "desc", "required_skills": "Python"
    })
    assert response.status_code == 201
    assert response.json()["title"] == "AI Matching"
    assert response.json()["status_flag"] == "Open"


def test_add_project_idea_missing_title_rejected(client):
    headers = register_and_login_staff(client)
    response = client.post("/staff/projects", headers=headers, json={"description": "desc"})
    assert response.status_code == 422


def test_edit_project_idea(client):
    headers = register_and_login_staff(client)
    add_response = client.post("/staff/projects", headers=headers, json={
        "title": "Old Title", "description": "desc"
    })
    project_id = add_response.json()["project_id"]

    response = client.put(f"/staff/projects/{project_id}", headers=headers, json={"title": "New Title"})
    assert response.status_code == 200
    assert response.json()["title"] == "New Title"


def test_cannot_edit_someone_elses_project_idea(client):
    headers_a = register_and_login_staff(client, email="a@port.ac.uk")
    headers_b = register_and_login_staff(client, name="Dr Jones", email="b@port.ac.uk")

    add_response = client.post("/staff/projects", headers=headers_a, json={
        "title": "A's idea", "description": "desc"
    })
    project_id = add_response.json()["project_id"]

    response = client.put(f"/staff/projects/{project_id}", headers=headers_b, json={"title": "Hijacked"})
    assert response.status_code == 403


def test_delete_project_idea(client):
    headers = register_and_login_staff(client)
    add_response = client.post("/staff/projects", headers=headers, json={
        "title": "Temp idea", "description": "desc"
    })
    project_id = add_response.json()["project_id"]

    response = client.delete(f"/staff/projects/{project_id}", headers=headers)
    assert response.status_code == 200

    profile = client.get("/staff/me", headers=headers)
    assert len(profile.json()["project_ideas"]) == 0


# ---------- Past submissions ----------

def test_add_and_delete_past_submission(client):
    headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()

    add_response = client.post(f"/staff/projects/{idea['project_id']}/submissions", headers=headers, json={
        "title": "Past project", "student_name": "Jamie Lee", "year_completed": 2025
    })
    assert add_response.status_code == 201
    submission_id = add_response.json()["submission_id"]

    profile = client.get("/staff/me", headers=headers)
    assert len(profile.json()["project_ideas"][0]["past_submissions"]) == 1

    delete_response = client.delete(f"/staff/submissions/{submission_id}", headers=headers)
    assert delete_response.status_code == 200

    profile = client.get("/staff/me", headers=headers)
    assert len(profile.json()["project_ideas"][0]["past_submissions"]) == 0


# ---------- UC2: Update Availability ----------

def test_update_availability(client):
    headers = register_and_login_staff(client)
    response = client.put("/staff/availability", headers=headers, json={
        "accepting_students": False, "max_capacity": 5
    })
    assert response.status_code == 200
    assert response.json()["accepting_students"] is False
    assert response.json()["max_capacity"] == 5


def test_cannot_lower_capacity_below_confirmed_students(client):
    staff_headers = register_and_login_staff(client)
    student_headers = register_and_login_student(client)

    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    request = client.post("/students/express-interest", headers=student_headers,
                           json={"project_id": idea["project_id"]}).json()
    client.post(f"/staff/requests/{request['request_id']}/respond", headers=staff_headers,
                json={"decision": "accept"})

    # Now 1 confirmed student exists - trying to set max_capacity to 0 should fail
    response = client.put("/staff/availability", headers=staff_headers, json={"max_capacity": 0})
    assert response.status_code == 400


# ---------- UC5: Respond to Student Interest ----------

def test_accept_request(client):
    staff_headers = register_and_login_staff(client)
    student_headers = register_and_login_student(client)

    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    request = client.post("/students/express-interest", headers=student_headers,
                           json={"project_id": idea["project_id"]}).json()

    response = client.post(f"/staff/requests/{request['request_id']}/respond",
                            headers=staff_headers, json={"decision": "accept"})
    assert response.status_code == 200
    assert response.json()["request_status"] == "Accepted"

    # The project idea should now be marked Taken
    profile = client.get("/staff/me", headers=staff_headers)
    assert profile.json()["project_ideas"][0]["status_flag"] == "Taken"


def test_decline_request(client):
    staff_headers = register_and_login_staff(client)
    student_headers = register_and_login_student(client)

    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    request = client.post("/students/express-interest", headers=student_headers,
                           json={"project_id": idea["project_id"]}).json()

    response = client.post(f"/staff/requests/{request['request_id']}/respond",
                            headers=staff_headers, json={"decision": "decline"})
    assert response.status_code == 200
    assert response.json()["request_status"] == "Declined"


def test_cannot_accept_when_at_full_capacity(client):
    staff_headers = register_and_login_staff(client)
    client.put("/staff/availability", headers=staff_headers, json={"max_capacity": 1})

    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "Idea 1", "description": "desc"
    }).json()
    idea2 = client.post("/staff/projects", headers=staff_headers, json={
        "title": "Idea 2", "description": "desc"
    }).json()

    student1 = register_and_login_student(client, name="S1", email="s1@myport.ac.uk")
    student2 = register_and_login_student(client, name="S2", email="s2@myport.ac.uk")

    req1 = client.post("/students/express-interest", headers=student1,
                        json={"project_id": idea["project_id"]}).json()
    req2 = client.post("/students/express-interest", headers=student2,
                        json={"project_id": idea2["project_id"]}).json()

    accept1 = client.post(f"/staff/requests/{req1['request_id']}/respond",
                           headers=staff_headers, json={"decision": "accept"})
    assert accept1.status_code == 200

    accept2 = client.post(f"/staff/requests/{req2['request_id']}/respond",
                           headers=staff_headers, json={"decision": "accept"})
    assert accept2.status_code == 400


def test_view_requests_filtered_by_status(client):
    staff_headers = register_and_login_staff(client)
    student_headers = register_and_login_student(client)

    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    client.post("/students/express-interest", headers=student_headers,
                json={"project_id": idea["project_id"]})

    pending = client.get("/staff/requests", headers=staff_headers)
    assert len(pending.json()) == 1
    assert pending.json()[0]["student_name"] == "Alex Smith"
    assert pending.json()[0]["project_title"] == "AI Matching"

    accepted = client.get("/staff/requests?status=Accepted", headers=staff_headers)
    assert len(accepted.json()) == 0
