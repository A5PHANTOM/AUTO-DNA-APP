from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import shutil
import os
import uuid

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/marketplace",
    tags=["Marketplace"]
)

@router.post("/", response_model=schemas.VehicleResponse)
async def post_vehicle(
    vehicle_name: str = Form(...),
    model: str = Form(...),
    year: int = Form(...),
    plate_number: str = Form(...),
    price: float = Form(...),
    description: str = Form(...),
    contact_info: str = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Enforce mandatory image
    if not image or not image.filename:
        raise HTTPException(status_code=400, detail="An image is mandatory for marketplace listings.")

    # Save image locally
    filename = f"{uuid.uuid4()}_{image.filename}"
    filepath = os.path.join("uploads", filename)
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
    image_path = filepath

    new_vehicle = models.Vehicle(
        user_id=current_user.id,
        vehicle_name=vehicle_name,
        model=model,
        year=year,
        plate_number=plate_number,
        price=price,
        description=description,
        contact_info=contact_info,
        image_path=image_path
    )
    db.add(new_vehicle)
    db.commit()
    db.refresh(new_vehicle)
    return new_vehicle

@router.get("/", response_model=List[schemas.VehicleResponse])
def get_all_vehicles(db: Session = Depends(database.get_db)):
    vehicles = db.query(models.Vehicle).all()
    
    # Process each vehicle to fetch the accident summary
    for v in vehicles:
        reports = db.query(models.Report).filter(models.Report.plate_number == v.plate_number).all()
        v.accident_reports = reports
            
    return vehicles

@router.get("/my-listings", response_model=List[schemas.VehicleResponse])
def get_my_listings(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    vehicles = db.query(models.Vehicle).filter(models.Vehicle.user_id == current_user.id).all()
    for v in vehicles:
        reports = db.query(models.Report).filter(models.Report.plate_number == v.plate_number).all()
        v.accident_reports = reports
    return vehicles

@router.delete("/{vehicle_id}", response_model=dict)
def delete_vehicle(
    vehicle_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    if vehicle.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this vehicle")
        
    db.delete(vehicle)
    db.commit()
    return {"status": "success", "message": "Vehicle deleted successfully"}
