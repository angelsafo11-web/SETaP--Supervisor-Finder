"""
Tests for routers/auth.py - register (staff/student) and login.
"""
from .conftest import register_and_login_staff, register_and_login_student


def test_register_staff_success(client):
    response = client.post("/auth/register/staff", json={
        "name": "Dr Smith", "email": "smith@port.ac.uk", "password": "test123"
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Dr Smith"


def test_register_staff_duplicate_email_rejected(client):
    client.post("/auth/register/staff", json={
        "name": "Dr Smith", "email": "smith@port.ac.uk", "password": "test123"
    })
    response = client.post("/auth/register/staff", json={
        "name": "Dr Jones", "email": "smith@port.ac.uk", "password": "test123"
    })
    assert response.status_code == 400


def test_register_staff_password_too_short_rejected(client):
    response = client.post("/auth/register/staff", json={
        "name": "Dr Smith", "email": "smith@port.ac.uk", "password": "abc"
    })
    assert response.status_code == 422  # Pydantic validation error


def test_register_student_success(client):
    response = client.post("/auth/register/student", json={
        "name": "Alex Smith", "email": "alex@myport.ac.uk", "password": "test123"
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Alex Smith"


def test_login_staff_success(client):
    client.post("/auth/register/staff", json={
        "name": "Dr Smith", "email": "smith@port.ac.uk", "password": "test123"
    })
    response = client.post("/auth/login", json={
        "role": "staff", "email": "smith@port.ac.uk", "password": "test123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["role"] == "staff"


def test_login_wrong_password_rejected(client):
    client.post("/auth/register/staff", json={
        "name": "Dr Smith", "email": "smith@port.ac.uk", "password": "test123"
    })
    response = client.post("/auth/login", json={
        "role": "staff", "email": "smith@port.ac.uk", "password": "wrongpassword"
    })
    assert response.status_code == 401


def test_login_unknown_email_rejected(client):
    response = client.post("/auth/login", json={
        "role": "student", "email": "nobody@myport.ac.uk", "password": "test123"
    })
    assert response.status_code == 401


def test_protected_route_rejects_missing_token(client):
    response = client.get("/staff/me")
    assert response.status_code in (401, 403)


def test_protected_route_rejects_wrong_role(client):
    # A student token should NOT be able to access a staff-only route
    headers = register_and_login_student(client)
    response = client.get("/staff/me", headers=headers)
    assert response.status_code == 403
