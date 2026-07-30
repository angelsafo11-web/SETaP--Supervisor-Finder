from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Staff, ProjectIdea, InterestRequest
from schemas import StaffOut, ExpressInterestRequest, InterestRequestOut
from auth_util import require_student
from helper import staff_to_schema

router = APIRouter(prefix="/students", tags=["students"])



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
    return [staff_to_schema(staff, db) for staff in results]


@router.get("/staff/{staff_id}", response_model=StaffOut)

def view_staff_profile(staff_id: int, db: Session = Depends(get_db)):
    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    return staff_to_schema(staff, db)


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

    return new_request
