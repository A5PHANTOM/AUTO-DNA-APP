from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import shutil
import uuid
import os

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/repairs",
    tags=["Car Repair Requests"]
)

@router.post("/", response_model=schemas.RepairRequestResponse)
async def create_repair_request(
    vehicle_details: str = Form(...),
    damage_description: str = Form(...),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "user" and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only 'user' can request repair estimates")
        
    image_path = None
    if image:
        file_ext = image.filename.split(".")[-1]
        file_name = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"uploads/{file_name}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = file_path
        
    new_request = models.RepairRequest(
        user_id=current_user.id, 
        vehicle_details=vehicle_details, 
        damage_description=damage_description,
        image_path=image_path
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/", response_model=List[schemas.RepairRequestResponse])
def get_repair_requests(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role == "workshop":
        # Workshop owners see all requests
        requests = db.query(models.RepairRequest).all()
    else:
        # Standard users see only their own
        requests = db.query(models.RepairRequest).filter(models.RepairRequest.user_id == current_user.id).all()
    return requests

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

# This is just to see the exact validation error in the server logs
@router.post("/{request_id}/bids", response_model=schemas.RepairBidResponse)
def create_bid(request_id: int, bid: schemas.RepairBidCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "workshop":
        raise HTTPException(status_code=403, detail="Only workshop owners can make bids")
        
    repair_request = db.query(models.RepairRequest).filter(models.RepairRequest.id == request_id).first()
    if not repair_request:
        raise HTTPException(status_code=404, detail="Request not found")

    new_bid = models.RepairBid(**bid.model_dump(), request_id=request_id, workshop_id=current_user.id)
    db.add(new_bid)
    db.commit()
    db.refresh(new_bid)
    return new_bid

@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_repair_request(request_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    repair_request = db.query(models.RepairRequest).filter(models.RepairRequest.id == request_id).first()
    if not repair_request:
        raise HTTPException(status_code=404, detail="Request not found")
        
    if repair_request.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to delete this request")

    # Delete bids first
    db.query(models.RepairBid).filter(models.RepairBid.request_id == request_id).delete()
    
    db.delete(repair_request)
    db.commit()
    return
