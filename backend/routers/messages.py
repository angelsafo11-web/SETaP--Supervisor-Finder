"""
Simple in-app messaging, only usable between a staff member and a student
who have a CONFIRMED (Accepted) supervision match between them.
Works for both roles - unlike routers/staff.py or routers/students.py,
this one checks role manually per-request rather than locking the whole
router to one role.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Message, InterestRequest
from schemas import MessageCreate, MessageOut
from auth_util import get_current_claims

router = APIRouter(prefix="/messages", tags=["messages"])


def _current_user(claims: dict = Depends(get_current_claims)):
    return int(claims["sub"]), claims["role"]


def _verify_accepted_match(db: Session, staff_id: int, student_id: int):
    match = (
        db.query(InterestRequest)
        .filter(
            InterestRequest.staff_id == staff_id,
            InterestRequest.student_id == student_id,
            InterestRequest.request_status == "Accepted",
        )
        .first()
    )
    if not match:
        raise HTTPException(
            status_code=403,
            detail="Messaging is only available once a supervision match has been confirmed",
        )


@router.post("/send", response_model=MessageOut, status_code=201)
def send_message(
    payload: MessageCreate,
    user: tuple = Depends(_current_user),
    db: Session = Depends(get_db),
):
    user_id, role = user

    if role == "staff":
        staff_id, student_id = user_id, payload.other_user_id
    elif role == "student":
        staff_id, student_id = payload.other_user_id, user_id
    else:
        raise HTTPException(status_code=403, detail="Unknown role")

    _verify_accepted_match(db, staff_id, student_id)

    message = Message(
        staff_id=staff_id,
        student_id=student_id,
        sender_role=role,
        content=payload.content,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


@router.get("/conversation/{other_user_id}", response_model=List[MessageOut])
def get_conversation(
    other_user_id: int,
    user: tuple = Depends(_current_user),
    db: Session = Depends(get_db),
):
    user_id, role = user

    if role == "staff":
        staff_id, student_id = user_id, other_user_id
    elif role == "student":
        staff_id, student_id = other_user_id, user_id
    else:
        raise HTTPException(status_code=403, detail="Unknown role")

    _verify_accepted_match(db, staff_id, student_id)

    return (
        db.query(Message)
        .filter(Message.staff_id == staff_id, Message.student_id == student_id)
        .order_by(Message.timestamp.asc())
        .all()
    )
