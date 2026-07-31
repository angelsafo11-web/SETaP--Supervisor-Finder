"""
Shared test setup. Every test file uses the 'client' fixture below.

Key idea: tests must NEVER touch your real database (app.db). Instead,
this creates a completely separate, temporary in-memory database just
for running tests, and swaps it in using FastAPI's dependency_overrides -
your actual app.py code is untouched.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import app
from database import Base, get_db

SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,  # keeps the same in-memory db across connections
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture()
def client():
    """A fresh, empty database for every single test function."""
    Base.metadata.create_all(bind=engine)
    yield TestClient(app)
    Base.metadata.drop_all(bind=engine)


# ---------- Reusable helpers for setting up test data quickly ----------

def register_and_login_staff(client, name="Dr Smith", email="staff@port.ac.uk", password="test123"):
    client.post("/auth/register/staff", json={"name": name, "email": email, "password": password})
    response = client.post("/auth/login", json={"role": "staff", "email": email, "password": password})
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def register_and_login_student(client, name="Alex Smith", email="student@myport.ac.uk", password="test123"):
    client.post("/auth/register/student", json={"name": name, "email": email, "password": password})
    response = client.post("/auth/login", json={"role": "student", "email": email, "password": password})
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
