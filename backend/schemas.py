"""
Pydantic 'schemas' describe the SHAPE of data going in and out of each route.
FastAPI uses these to automatically validate incoming requests (e.g. reject
a request missing a required field) and to control exactly what gets sent
back out - this replaces the manual to_dict() methods from the Flask version.
"""
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


# ---------- Past submissions (examples of previously supervised projects) ----------

class PastSubmissionCreate(BaseModel):
    title: str
    student_name: Optional[str] = ""
    year_completed: Optional[int] = None
    description: Optional[str] = ""
    link: Optional[str] = ""


class PastSubmissionOut(BaseModel):
    submission_id: int
    project_id: int
    title: str
    student_name: str
    year_completed: Optional[int] = None
    description: str
    link: str

    class Config:
        from_attributes = True


class ProjectIdeaOut(BaseModel):
    project_id: int
    staff_id: int
    title: str
    description: str
    required_skills: str
    status_flag: str
    past_submissions: List[PastSubmissionOut] = []

    class Config:
        from_attributes = True  # lets this be built directly from an ORM object


class ProjectIdeaWithStaffOut(ProjectIdeaOut):
    staff_name: str
    staff_accepting_students: bool
    staff_spots_remaining: int


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

class InterestRequestWithDetailsOut(InterestRequestOut):
    student_name: str
    project_title: str


# ---------- Messages (available once a request is Accepted) ----------

class MessageCreate(BaseModel):
    other_user_id: int  # the staff_id (if sender is student) or student_id (if sender is staff)
    content: str = Field(min_length=1)


class MessageOut(BaseModel):
    message_id: int
    staff_id: int
    student_id: int
    sender_role: str
    content: str
    timestamp: datetime

    class Config:
        from_attributes = True
