from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine, Base
from routers import auth, staff, students

app = FastAPI(title = "Supervisor Finder API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(auth.router)
app.include_router(staff.router)
app.include_router(students.router)

@app.get("/")
def health_check():
    return{"status": "Supervisor Finder API is running successfully."}


