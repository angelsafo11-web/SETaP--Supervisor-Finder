"""
This is the file you actually run.
It builds the FastAPI app, creates the database tables, and 'plugs in'
each group of routes (routers) we built in the routers/ folder.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Base, engine
from routers import auth, staff, students, messages

# Creates app.db and all tables the FIRST time this runs
# (does nothing if they already exist)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Supervisor Finder API")

# Allows a separate frontend (running on a different address) to call this API.
# allow_origins=["*"] is fine for coursework/local dev - in a real deployment
# you would list your actual frontend's address instead.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(staff.router)
app.include_router(students.router)
app.include_router(messages.router)


@app.get("/")
def health_check():
    return {"status": "Supervisor Finder API is running"}
