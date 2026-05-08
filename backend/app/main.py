from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
import os

load_dotenv()

from .routers import auth, reports, search, marketplace, ai, admin, spare_parts, chat, repairs
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

from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi import Request

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    body = await request.body()
    with open("validation_errors.log", "a") as f:
        f.write(f"Validation Error: {exc.errors()}\nBody: {body.decode()}\n\n")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "body": body.decode()},
    )

app.include_router(auth.router)
app.include_router(reports.router)
app.include_router(search.router)
app.include_router(marketplace.router)
app.include_router(ai.router)
app.include_router(admin.router)
app.include_router(spare_parts.router)
app.include_router(chat.router)
app.include_router(repairs.router)

# Create static directory for uploaded images if it doesn't exist
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def read_root():
    return {"message": "Welcome to Auto DNA Backend!"}
