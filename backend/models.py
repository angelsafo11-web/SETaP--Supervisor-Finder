from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


class Staff(Base):
    __tablename__ = "staff"

    staff_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    email = Column(String(120), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    bio = Column(Text, default="")
    area_of_interest = Column(String(255), default="")

    accepting_students = Column(Boolean, default=True)
    max_capacity = Column(Integer, default=3)

    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    project_ideas = relationship("ProjectIdea", back_populates="staff")


class Student(Base):
    __tablename__ = "student"

    student_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    email = Column(String(120), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)


class ProjectIdea(Base):
    __tablename__ = "project_idea"

    project_id = Column(Integer, primary_key=True, index=True)
    staff_id = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    required_skills = Column(String(255), default="")
    status_flag = Column(String(20), default="Open")  # "Open" or "Taken"
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    staff = relationship("Staff", back_populates="project_ideas")


class InterestRequest(Base):
    __tablename__ = "interest_request"

    request_id = Column(Integer, primary_key=True, index=True)
    staff_id = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    student_id = Column(Integer, ForeignKey("student.student_id"), nullable=False)
    project_id = Column(Integer, ForeignKey("project_idea.project_id"), nullable=False)
    request_status = Column(String(20), default="Pending")  # Pending / Accepted / Declined
    timestamp = Column(DateTime, default=datetime.utcnow)
