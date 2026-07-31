
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Staff, ProjectIdea, InterestRequest, PastSubmission, Student
from schemas import (
    ProjectIdeaCreate, ProjectIdeaUpdate, ProjectIdeaOut,
    AvailabilityUpdate, StaffOut, RespondRequest, InterestRequestOut,
    PastSubmissionCreate, PastSubmissionOut, InterestRequestWithDetailsOut
)
from auth_util import require_staff
from helper import staff_to_schema

router = APIRouter(prefix="/staff", tags=["staff"])


# ---------- Staff's own profile ----------

@router.get("/me", response_model=StaffOut)
def view_own_profile(
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    return staff_to_schema(staff, db)


# ---------- UC1: Manage Project Ideas ----------

@router.post("/projects", response_model=ProjectIdeaOut, status_code=201)
def add_project_idea(
    payload: ProjectIdeaCreate,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    # Note: FastAPI + Pydantic already reject the request before reaching here
    # if title/description are missing - that's the built-in validation.
    idea = ProjectIdea(
        staff_id=staff_id,
        title=payload.title,
        description=payload.description,
        required_skills=payload.required_skills or "",
    )
    db.add(idea)
    db.commit()
    db.refresh(idea)
    return idea


@router.put("/projects/{project_id}", response_model=ProjectIdeaOut)
def edit_project_idea(
    project_id: int,
    payload: ProjectIdeaUpdate,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == project_id).first()
    if not idea:
        raise HTTPException(status_code=404, detail="Project idea not found")
    if idea.staff_id != staff_id:
        raise HTTPException(status_code=403, detail="You can only edit your own project ideas")

    if payload.title is not None:
        idea.title = payload.title
    if payload.description is not None:
        idea.description = payload.description
    if payload.required_skills is not None:
        idea.required_skills = payload.required_skills

    db.commit()
    db.refresh(idea)
    return idea


@router.delete("/projects/{project_id}")
def delete_project_idea(
    project_id: int,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == project_id).first()
    if not idea:
        raise HTTPException(status_code=404, detail="Project idea not found")
    if idea.staff_id != staff_id:
        raise HTTPException(status_code=403, detail="You can only delete your own project ideas")

    db.delete(idea)
    db.commit()
    return {"message": "Project idea deleted"}


# ---------- Past submissions (examples of previously supervised projects) ----------

@router.post("/projects/{project_id}/submissions", response_model=PastSubmissionOut, status_code=201)
def add_past_submission(
    project_id: int,
    payload: PastSubmissionCreate,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == project_id).first()
    if not idea:
        raise HTTPException(status_code=404, detail="Project idea not found")
    if idea.staff_id != staff_id:
        raise HTTPException(status_code=403, detail="You can only add submissions to your own project ideas")

    submission = PastSubmission(
        project_id=project_id,
        title=payload.title,
        student_name=payload.student_name or "",
        year_completed=payload.year_completed,
        description=payload.description or "",
        link=payload.link or "",
    )
    db.add(submission)
    db.commit()
    db.refresh(submission)
    return submission


@router.delete("/submissions/{submission_id}")
def delete_past_submission(
    submission_id: int,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    submission = db.query(PastSubmission).filter(PastSubmission.submission_id == submission_id).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")

    idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == submission.project_id).first()
    if not idea or idea.staff_id != staff_id:
        raise HTTPException(status_code=403, detail="You can only delete submissions on your own project ideas")

    db.delete(submission)
    db.commit()
    return {"message": "Submission deleted"}


# ---------- UC2: Update Availability Status ----------

@router.put("/availability", response_model=StaffOut)
def update_availability(
    payload: AvailabilityUpdate,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()

    if payload.accepting_students is not None:
        staff.accepting_students = payload.accepting_students

    if payload.max_capacity is not None:
        accepted_count = (
            db.query(InterestRequest)
            .filter(
                InterestRequest.staff_id == staff_id,
                InterestRequest.request_status == "Accepted",
            )
            .count()
        )
        # Alternative flow: warn if new max is below current confirmed students
        if payload.max_capacity < accepted_count:
            raise HTTPException(
                status_code=400,
                detail=f"You already have {accepted_count} confirmed students. "
                       f"Max capacity cannot be set lower than that.",
            )
        staff.max_capacity = payload.max_capacity

    db.commit()
    db.refresh(staff)
    return staff_to_schema(staff, db)


# ---------- UC5: Respond to Student Interest ----------

@router.get("/requests", response_model=List[InterestRequestWithDetailsOut])
def view_pending_requests(
    status: Optional[str] = "Pending",
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    query = db.query(InterestRequest).filter(InterestRequest.staff_id == staff_id)
    if status:
        query = query.filter(InterestRequest.request_status == status)

    results = []
    for request in query.all():
        student = db.query(Student).filter(Student.student_id == request.student_id).first()
        idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == request.project_id).first()
        results.append(InterestRequestWithDetailsOut(
            request_id=request.request_id,
            staff_id=request.staff_id,
            student_id=request.student_id,
            project_id=request.project_id,
            request_status=request.request_status,
            timestamp=request.timestamp,
            student_name=student.name if student else "Unknown student",
            project_title=idea.title if idea else "Unknown project",
        ))
    return results

@router.post("/requests/{request_id}/respond", response_model=InterestRequestOut)
def respond_to_request(
    request_id: int,
    payload: RespondRequest,
    staff_id: int = Depends(require_staff),
    db: Session = Depends(get_db),
):
    interest_request = (
        db.query(InterestRequest).filter(InterestRequest.request_id == request_id).first()
    )
    if not interest_request:
        raise HTTPException(status_code=404, detail="Request not found")
    if interest_request.staff_id != staff_id:
        raise HTTPException(status_code=403, detail="This request does not belong to you")

    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()

    if payload.decision == "accept":
        accepted_count = (
            db.query(InterestRequest)
            .filter(InterestRequest.staff_id == staff_id, InterestRequest.request_status == "Accepted")
            .count()
        )
        # Alternative flow: block if already full
        if accepted_count >= staff.max_capacity:
            raise HTTPException(status_code=400, detail="You are already at full capacity")

        interest_request.request_status = "Accepted"
        idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == interest_request.project_id).first()
        idea.status_flag = "Taken"

    elif payload.decision == "decline":
        interest_request.request_status = "Declined"
    else:
        raise HTTPException(status_code=400, detail="decision must be 'accept' or 'decline'")

    db.commit()
    db.refresh(interest_request)
    # NOTE: this is where you'd trigger the Notification & Reminder Service
    return interest_request
