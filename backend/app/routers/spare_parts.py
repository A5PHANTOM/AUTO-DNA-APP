from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import shutil
import uuid
import os

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/spare-parts",
    tags=["Spare Parts Marketplace"]
)

@router.post("/", response_model=schemas.SparePartRequestResponse)
async def create_spare_part_request(
    part_name: str = Form(...),
    car_model: str = Form(...),
    description: str = Form(None),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "user" and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only 'user' can request spare parts")
        
    image_path = None
    if image:
        file_ext = image.filename.split(".")[-1]
        file_name = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"uploads/{file_name}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = file_path
        
    new_request = models.SparePartRequest(
        user_id=current_user.id, 
        part_name=part_name, 
        car_model=car_model, 
        description=description,
        image_path=image_path
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/", response_model=List[schemas.SparePartRequestResponse])
def get_spare_part_requests(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role == "workshop":
        # Workshops see all requests
        requests = db.query(models.SparePartRequest).all()
    else:
        # Standard users see only their own
        requests = db.query(models.SparePartRequest).filter(models.SparePartRequest.user_id == current_user.id).all()
    return requests

@router.post("/{request_id}/offers", response_model=schemas.SparePartOfferResponse)
def create_offer(request_id: int, offer: schemas.SparePartOfferCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "workshop":
        raise HTTPException(status_code=403, detail="Only workshops can make offers")
        
    part_request = db.query(models.SparePartRequest).filter(models.SparePartRequest.id == request_id).first()
    if not part_request:
        raise HTTPException(status_code=404, detail="Request not found")

    new_offer = models.SparePartOffer(**offer.model_dump(), request_id=request_id, workshop_id=current_user.id)
    db.add(new_offer)
    db.commit()
    db.refresh(new_offer)
    return new_offer

@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_spare_part_request(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    part_request = db.query(models.SparePartRequest).filter(models.SparePartRequest.id == request_id).first()
    if not part_request:
        raise HTTPException(status_code=404, detail="Request not found")
        
    if part_request.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to delete this request")

    # Manually cascade delete just in case SQLite enforces foreign keys
    offers = db.query(models.SparePartOffer).filter(models.SparePartOffer.request_id == request_id).all()
    for offer in offers:
        threads = db.query(models.ChatThread).filter(models.ChatThread.offer_id == offer.id).all()
        for thread in threads:
            db.query(models.Message).filter(models.Message.thread_id == thread.id).delete()
            db.delete(thread)
        db.delete(offer)
    
    db.delete(part_request)
    db.commit()
    return
