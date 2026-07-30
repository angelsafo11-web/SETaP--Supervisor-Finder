from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.context import CryptContext

SECRET_KEY = "change-this-to-something-random-and-secret"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# This tells FastAPI's docs page (and clients) that a token should be sent
# as: Authorization: Bearer <token>, and that tokens are obtained from /auth/login
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def hash_password(raw_password: str) -> str:
    return pwd_context.hash(raw_password)


def verify_password(raw_password: str, password_hash: str) -> bool:
    return pwd_context.verify(raw_password, password_hash)


def create_access_token(user_id: int, role: str) -> str:
    expire = datetime.now(datetime.timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": str(user_id), "role": role, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)




def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )


def get_current_claims(token: str = Depends(oauth2_scheme)) -> dict:
    """Returns the claims (payload) of the current user's JWT token."""
    return decode_token(token)


def require_staff(claims: dict = Depends(get_current_claims)) -> int:
    """Use this in any route only a staff member should access. Returns their staff_id."""
    if claims.get("role") != "staff":
        raise HTTPException(status_code=403, detail="Staff account required")
    return int(claims["sub"])


def require_student(claims: dict = Depends(get_current_claims)) -> int:
    """Use this in any route only a student should access. Returns their student_id."""
    if claims.get("role") != "student":
        raise HTTPException(status_code=403, detail="Student account required")
    return int(claims["sub"])
