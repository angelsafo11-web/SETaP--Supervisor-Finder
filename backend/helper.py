from sqlalchemy.orm import Session

from models import Staff, InterestRequest
from schemas import StaffOut


def staff_to_schema(staff: Staff, db: Session) -> StaffOut:
    accepted_count = (
        db.query(InterestRequest)
        .filter(
            InterestRequest.staff_id == staff.staff_id,
            InterestRequest.request_status == "Accepted",
        )
        .count()
    )
    return StaffOut(
        staff_id=staff.staff_id,
        name=staff.name,
        email=staff.email,
        bio=staff.bio or "",
        area_of_interest=staff.area_of_interest or "",
        accepting_students=staff.accepting_students,
        max_capacity=staff.max_capacity,
        spots_remaining=max(staff.max_capacity - accepted_count, 0),
        project_ideas=staff.project_ideas,
    )
