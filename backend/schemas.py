from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


# ---------- Auth ----------

class StaffRegister(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=6)


class StudentRegister(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=6)


class LoginRequest(BaseModel):
    role: str  # "staff" or "student"
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    role: str


# ---------- Project ideas ----------

class ProjectIdeaCreate(BaseModel):
    title: str
    description: str
    required_skills: Optional[str] = ""


class ProjectIdeaUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    required_skills: Optional[str] = None


class ProjectIdeaOut(BaseModel):
    project_id: int
    staff_id: int
    title: str
    description: str
    required_skills: str
    status_flag: str

    class Config:
        from_attributes = True  # lets this be built directly from an ORM object


# ---------- Staff ----------

class StaffOut(BaseModel):
    staff_id: int
    name: str
    email: str
    bio: str
    area_of_interest: str
    accepting_students: bool
    max_capacity: int
    spots_remaining: int
    project_ideas: List[ProjectIdeaOut] = []


class AvailabilityUpdate(BaseModel):
    accepting_students: Optional[bool] = None
    max_capacity: Optional[int] = None


# ---------- Student ----------

class StudentOut(BaseModel):
    student_id: int
    name: str
    email: str

    class Config:
        from_attributes = True


# ---------- Interest requests ----------

class ExpressInterestRequest(BaseModel):
    project_id: int


class RespondRequest(BaseModel):
    decision: str  # "accept" or "decline"


class InterestRequestOut(BaseModel):
    request_id: int
    staff_id: int
    student_id: int
    project_id: int
    request_status: str
    timestamp: datetime

    class Config:
        from_attributes = True
