from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Staff, Student
from schemas import StaffRegister, StudentRegister, LoginRequest, TokenResponse
from auth import hash_password, verify_password, create_access_token


router = APIRouter(prefix="/auth", tags=["auth"])
