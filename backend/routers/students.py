"""
Routes only a logged-in STUDENT should use.
Maps to: UC3 (Browse and Filter Staff Profiles), UC4 (Express Interest in an Idea).
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Staff, ProjectIdea, InterestRequest, Student
from schemas import StaffOut, ExpressInterestRequest, InterestRequestOut, StudentOut, ProjectIdeaWithStaffOut
from auth_util import require_student
from helper import staff_to_schema

router = APIRouter(prefix="/students", tags=["students"])


# ---------- Student's own profile ----------

@router.get("/me", response_model=StudentOut)
def view_own_profile(
    student_id: int = Depends(require_student),
    db: Session = Depends(get_db),
):
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


@router.get("/my-requests", response_model=List[InterestRequestOut])
def view_my_requests(
    student_id: int = Depends(require_student),
    db: Session = Depends(get_db),
):
    # Shows every idea this student has expressed interest in, and its
    # current stage: Pending (awaiting response), Accepted, or Declined.
    return (
        db.query(InterestRequest)
        .filter(InterestRequest.student_id == student_id)
        .all()
    )


# ---------- UC3: Browse and Filter Staff Profiles ----------

@router.get("/browse", response_model=List[StaffOut])
def browse_staff(
    interest: Optional[str] = None,
    accepting_only: Optional[bool] = None,
    student_id: int = Depends(require_student),
    db: Session = Depends(get_db),
):
    query = db.query(Staff)
    if interest:
        query = query.filter(Staff.area_of_interest.ilike(f"%{interest}%"))
    if accepting_only:
        query = query.filter(Staff.accepting_students.is_(True))

    results = query.all()
    # Note: if 'results' is empty, this correctly returns an empty list [],
    # matching your "no results" alternative flow - the frontend decides
    # how to display that (e.g. a "no staff match your filters" message).
    return [staff_to_schema(staff, db) for staff in results]


@router.get("/staff/{staff_id}", response_model=StaffOut)
def view_staff_profile(staff_id: int, db: Session = Depends(get_db)):
    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    return staff_to_schema(staff, db)


@router.get("/browse-projects", response_model=List[ProjectIdeaWithStaffOut])
def browse_project_ideas(
    interest: Optional[str] = None,
    accepting_only: Optional[bool] = None,
    student_id: int = Depends(require_student),
    db: Session = Depends(get_db),
):
    # Lists individual project ideas (with their owning staff member's info
    # flattened in) rather than staff profiles - lets students browse by
    # idea title directly, per UR3.
    query = db.query(ProjectIdea).join(Staff)
    if interest:
        query = query.filter(
            (ProjectIdea.title.ilike(f"%{interest}%"))
            | (ProjectIdea.description.ilike(f"%{interest}%"))
            | (Staff.area_of_interest.ilike(f"%{interest}%"))
        )
    if accepting_only:
        query = query.filter(Staff.accepting_students.is_(True))

    results = []
    for idea in query.all():
        staff = idea.staff
        accepted_count = (
            db.query(InterestRequest)
            .filter(InterestRequest.staff_id == staff.staff_id, InterestRequest.request_status == "Accepted")
            .count()
        )
        results.append(ProjectIdeaWithStaffOut(
            project_id=idea.project_id,
            staff_id=idea.staff_id,
            title=idea.title,
            description=idea.description,
            required_skills=idea.required_skills,
            status_flag=idea.status_flag,
            past_submissions=idea.past_submissions,
            staff_name=staff.name,
            staff_accepting_students=staff.accepting_students,
            staff_spots_remaining=max(staff.max_capacity - accepted_count, 0),
        ))
    return results


# ---------- UC4: Express Interest in an Idea ----------

@router.post("/express-interest", response_model=InterestRequestOut, status_code=201)
def express_interest(
    payload: ExpressInterestRequest,
    student_id: int = Depends(require_student),
    db: Session = Depends(get_db),
):
    idea = db.query(ProjectIdea).filter(ProjectIdea.project_id == payload.project_id).first()
    if not idea:
        raise HTTPException(status_code=404, detail="Project idea not found")

    staff = db.query(Staff).filter(Staff.staff_id == idea.staff_id).first()

    # Alternative flow: staff no longer accepting students
    if not staff.accepting_students:
        raise HTTPException(status_code=400, detail="This staff member is no longer accepting students")

    if idea.status_flag == "Taken":
        raise HTTPException(status_code=400, detail="This project idea has already been taken")

    new_request = InterestRequest(
        staff_id=staff.staff_id,
        student_id=student_id,
        project_id=idea.project_id,
        request_status="Pending",
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    # NOTE: this is where the Notification Service would alert the staff member
    return new_request
