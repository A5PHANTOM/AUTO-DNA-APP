from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from .. import schemas, models, database

router = APIRouter(
    prefix="/api/search",
    tags=["Search"]
)

@router.get("/{plate_number}", response_model=List[schemas.ReportResponse])
def search_vehicle_history(
    plate_number: str,
    db: Session = Depends(database.get_db)
):
    plate_number = plate_number.upper()
    # Only return approved reports for public search
    reports = db.query(models.Report).filter(
        models.Report.plate_number == plate_number,
        models.Report.status == "approved"
    ).all()
    
    if not reports:
        # We can just return an empty list or 404. Empty list is more standard for search.
        return []
        
    return reports
