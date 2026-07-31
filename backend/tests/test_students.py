"""
Tests for routers/students.py - UC3 (browse/filter), UC4 (express interest),
own profile, and request history.
"""
from .conftest import register_and_login_staff, register_and_login_student


def test_view_own_profile(client):
    headers = register_and_login_student(client)
    response = client.get("/students/me", headers=headers)
    assert response.status_code == 200
    assert response.json()["name"] == "Alex Smith"


# ---------- UC3: Browse and Filter ----------

def test_browse_staff_returns_all_by_default(client):
    register_and_login_staff(client)
    headers = register_and_login_student(client)
    response = client.get("/students/browse", headers=headers)
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_browse_staff_filters_by_interest(client):
    staff_headers = register_and_login_staff(client)
    client.put("/staff/availability", headers=staff_headers, json={"accepting_students": True})
    # area_of_interest isn't set via a route in this version, so filter should return empty
    student_headers = register_and_login_student(client)
    response = client.get("/students/browse?interest=Quantum", headers=student_headers)
    assert response.status_code == 200
    assert len(response.json()) == 0


def test_browse_projects_returns_flattened_ideas_with_staff_info(client):
    staff_headers = register_and_login_staff(client)
    client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    })
    student_headers = register_and_login_student(client)

    response = client.get("/students/browse-projects", headers=student_headers)
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["title"] == "AI Matching"
    assert response.json()[0]["staff_name"] == "Dr Smith"


def test_browse_projects_search_by_title(client):
    staff_headers = register_and_login_staff(client)
    client.post("/staff/projects", headers=staff_headers, json={
        "title": "Quantum Computing", "description": "desc"
    })
    client.post("/staff/projects", headers=staff_headers, json={
        "title": "Web Development", "description": "desc"
    })
    student_headers = register_and_login_student(client)

    response = client.get("/students/browse-projects?interest=Quantum", headers=student_headers)
    assert len(response.json()) == 1
    assert response.json()[0]["title"] == "Quantum Computing"


def test_view_staff_profile_by_id(client):
    register_and_login_staff(client)
    student_headers = register_and_login_student(client)
    response = client.get("/students/staff/1", headers=student_headers)
    assert response.status_code == 200
    assert response.json()["name"] == "Dr Smith"


def test_view_staff_profile_not_found(client):
    student_headers = register_and_login_student(client)
    response = client.get("/students/staff/999", headers=student_headers)
    assert response.status_code == 404


# ---------- UC4: Express Interest ----------

def test_express_interest_success(client):
    staff_headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    student_headers = register_and_login_student(client)

    response = client.post("/students/express-interest", headers=student_headers,
                            json={"project_id": idea["project_id"]})
    assert response.status_code == 201
    assert response.json()["request_status"] == "Pending"


def test_express_interest_blocked_when_staff_not_accepting(client):
    staff_headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    client.put("/staff/availability", headers=staff_headers, json={"accepting_students": False})
    student_headers = register_and_login_student(client)

    response = client.post("/students/express-interest", headers=student_headers,
                            json={"project_id": idea["project_id"]})
    assert response.status_code == 400


def test_express_interest_blocked_when_idea_taken(client):
    staff_headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()

    student1 = register_and_login_student(client, name="S1", email="s1@myport.ac.uk")
    req = client.post("/students/express-interest", headers=student1,
                       json={"project_id": idea["project_id"]}).json()
    client.post(f"/staff/requests/{req['request_id']}/respond", headers=staff_headers,
                json={"decision": "accept"})

    student2 = register_and_login_student(client, name="S2", email="s2@myport.ac.uk")
    response = client.post("/students/express-interest", headers=student2,
                            json={"project_id": idea["project_id"]})
    assert response.status_code == 400


def test_express_interest_nonexistent_project(client):
    headers = register_and_login_student(client)
    response = client.post("/students/express-interest", headers=headers, json={"project_id": 999})
    assert response.status_code == 404


# ---------- My requests ----------

def test_my_requests_shows_expressed_interest(client):
    staff_headers = register_and_login_staff(client)
    idea = client.post("/staff/projects", headers=staff_headers, json={
        "title": "AI Matching", "description": "desc"
    }).json()
    student_headers = register_and_login_student(client)
    client.post("/students/express-interest", headers=student_headers,
                json={"project_id": idea["project_id"]})

    response = client.get("/students/my-requests", headers=student_headers)
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["request_status"] == "Pending"


def test_my_requests_empty_when_none_made(client):
    headers = register_and_login_student(client)
    response = client.get("/students/my-requests", headers=headers)
    assert response.status_code == 200
    assert response.json() == []
