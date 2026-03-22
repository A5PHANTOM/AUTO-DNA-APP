from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
import os

load_dotenv()

from .routers import auth, reports, search, marketplace, ai, admin
import os

from .database import engine, Base
from . import models

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Auto DNA API")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(reports.router)
app.include_router(search.router)
app.include_router(marketplace.router)
app.include_router(ai.router)
app.include_router(admin.router)

# Create static directory for uploaded images if it doesn't exist
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def read_root():
    return {"message": "Welcome to Auto DNA Backend!"}
