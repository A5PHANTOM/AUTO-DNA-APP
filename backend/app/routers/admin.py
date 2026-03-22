from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from .. import schemas, models, database
from ..auth import get_current_admin_user

router = APIRouter(
    prefix="/api/admin",
    tags=["Admin"]
)

@router.get("/reports", response_model=List[schemas.ReportResponse])
def get_all_reports(db: Session = Depends(database.get_db), current_admin: models.User = Depends(get_current_admin_user)):
    reports = db.query(models.Report).all()
    return reports

@router.patch("/reports/{report_id}/status", response_model=schemas.ReportResponse)
def update_report_status(
    report_id: int, 
    status: str, 
    db: Session = Depends(database.get_db), 
    current_admin: models.User = Depends(get_current_admin_user)
):
    if status not in ["approved", "rejected", "pending"]:
        raise HTTPException(status_code=400, detail="Invalid status")
        
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    report.status = status
    db.commit()
    db.refresh(report)
    return report
