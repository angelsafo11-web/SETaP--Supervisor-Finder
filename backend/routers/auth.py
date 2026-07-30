from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Staff, Student
from schemas import StaffRegister, StudentRegister, LoginRequest, TokenResponse
from auth_util import hash_password, verify_password, create_access_token


router = APIRouter(prefix="/auth", tags=["auth"])


# ---------- Auth Endpoints ----------
# This file contains endpoints for user registration and login for both staff and students.

@router.post("/register/staff", status_code=201)

def register_staff(payload: StaffRegister, db: Session = Depends(get_db)):
    if db.query(Staff).filter(Staff.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    staff = Staff(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
    )
    db.add(staff)
    db.commit()
    db.refresh(staff)
    return {"staff_id": staff.staff_id, "name": staff.name, "email": staff.email}


# ---------- Student Registration and Login Endpoints ----------

@router.post("/register/student", status_code=201)

def register_student(payload: StudentRegister, db: Session = Depends(get_db)):
    if db.query(Student).filter(Student.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    student = Student(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    return {"student_id": student.student_id, "name": student.name, "email": student.email}


# ---------- Login Endpoint ----------
# This handles login for both student and staff users. it checks their role then verifies credentials

@router.post("/login", response_model=TokenResponse)

def login(payload: LoginRequest, db: Session = Depends(get_db)):
    if payload.role == "staff":
        user = db.query(Staff).filter(Staff.email == payload.email).first()
        user_id = user.staff_id if user else None
    else:
        user = db.query(Student).filter(Student.email == payload.email).first()
        user_id = user.student_id if user else None

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token(user_id=user_id, role=payload.role)
    return TokenResponse(access_token=token, role=payload.role)
