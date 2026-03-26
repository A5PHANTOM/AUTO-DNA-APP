from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import shutil
import os
import uuid

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/reports",
    tags=["Reports"]
)

@router.post("/", response_model=schemas.ReportResponse)
async def create_report(
    plate_number: str = Form(...),
    description: str = Form(...),
    ai_damage_estimation: Optional[str] = Form(None),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    cleaned_ai = (ai_damage_estimation or "").strip()
    if cleaned_ai.lower().startswith("failed") or cleaned_ai.lower().startswith("error"):
        cleaned_ai = ""

    image_path = None
    if image:
        # Save image locally
        filename = f"{uuid.uuid4()}_{image.filename}"
        filepath = os.path.join("uploads", filename)
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = filepath

    new_report = models.Report(
        user_id=current_user.id,
        plate_number=plate_number.upper(),
        description=description,
        image_path=image_path,
        ai_damage_estimation=cleaned_ai or None
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)

    # Ensure first-time report records have AI text even when client-side estimation failed or was skipped.
    if not (new_report.ai_damage_estimation or "").strip():
        try:
            from .ai import analyze_report

            ai_response = analyze_report(new_report.id, db)
            if ai_response and getattr(ai_response, "estimation", None):
                new_report.ai_damage_estimation = ai_response.estimation
                db.commit()
        except Exception:
            pass

    db.refresh(new_report)
    return new_report

@router.get("/", response_model=List[schemas.ReportResponse])
def get_user_reports(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    reports = db.query(models.Report).filter(models.Report.user_id == current_user.id).all()
    return reports
