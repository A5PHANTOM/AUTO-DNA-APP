from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/spare-parts",
    tags=["Spare Parts Marketplace"]
)

@router.post("/", response_model=schemas.SparePartRequestResponse)
def create_spare_part_request(request: schemas.SparePartRequestCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "user" and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only 'user' can request spare parts")
    new_request = models.SparePartRequest(**request.model_dump(), user_id=current_user.id)
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/", response_model=List[schemas.SparePartRequestResponse])
def get_spare_part_requests(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role == "workshop":
        # Workshop owners see all requests
        requests = db.query(models.SparePartRequest).all()
    else:
        # Standard users see only their own
        requests = db.query(models.SparePartRequest).filter(models.SparePartRequest.user_id == current_user.id).all()
    return requests

@router.post("/{request_id}/offers", response_model=schemas.SparePartOfferResponse)
def create_offer(request_id: int, offer: schemas.SparePartOfferCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "workshop":
        raise HTTPException(status_code=403, detail="Only workshop owners can make offers")
        
    part_request = db.query(models.SparePartRequest).filter(models.SparePartRequest.id == request_id).first()
    if not part_request:
        raise HTTPException(status_code=404, detail="Request not found")

    new_offer = models.SparePartOffer(**offer.model_dump(), request_id=request_id, workshop_id=current_user.id)
    db.add(new_offer)
    db.commit()
    db.refresh(new_offer)
    return new_offer
