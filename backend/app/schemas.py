from pydantic import BaseModel
from typing import Optional, List

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

class TokenData(BaseModel):
    username: Optional[str] = None

# User Schemas
class UserBase(BaseModel):
    username: str

class UserCreate(UserBase):
    password: str
    role: Optional[str] = "user"

class UserResponse(UserBase):
    id: int
    role: str

    class Config:
        from_attributes = True

# Report Schemas
class ReportBase(BaseModel):
    plate_number: str
    description: str

class ReportCreate(ReportBase):
    pass

class ReportResponse(ReportBase):
    id: int
    user_id: int
    image_path: Optional[str] = None
    status: str
    ai_damage_estimation: Optional[str] = None

    class Config:
        from_attributes = True

# Vehicle Schemas
class VehicleBase(BaseModel):
    vehicle_name: str
    model: str
    year: int
    plate_number: str
    price: float
    description: str
    contact_info: str

class VehicleCreate(VehicleBase):
    pass

class VehicleResponse(VehicleBase):
    id: int
    user_id: int
    image_path: Optional[str] = None
    accident_reports: List[ReportResponse] = []

    class Config:
        from_attributes = True

# Spare Part Schemas
class SparePartOfferBase(BaseModel):
    price: float
    notes: Optional[str] = None

class SparePartOfferCreate(SparePartOfferBase):
    pass

class SparePartOfferResponse(SparePartOfferBase):
    id: int
    request_id: int
    workshop_id: int

    class Config:
        from_attributes = True

class SparePartRequestBase(BaseModel):
    part_name: str
    car_model: str
    description: Optional[str] = None

class SparePartRequestCreate(SparePartRequestBase):
    pass

class SparePartRequestResponse(SparePartRequestBase):
    id: int
    user_id: int
    image_path: Optional[str] = None
    offers: List[SparePartOfferResponse] = []

    class Config:
        from_attributes = True

from datetime import datetime

class MessageBase(BaseModel):
    text: str

class MessageCreate(MessageBase):
    pass

class MessageResponse(MessageBase):
    id: int
    thread_id: int
    sender_id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class ChatThreadCreate(BaseModel):
    offer_id: Optional[int] = None
    bid_id: Optional[int] = None

class ChatThreadResponse(BaseModel):
    id: int
    offer_id: Optional[int] = None
    bid_id: Optional[int] = None
    user_id: int
    workshop_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class RepairBidBase(BaseModel):
    amount: float
    notes: Optional[str] = None

class RepairBidCreate(RepairBidBase):
    pass

class RepairBidResponse(RepairBidBase):
    id: int
    request_id: int
    workshop_id: int

    class Config:
        from_attributes = True

class RepairRequestBase(BaseModel):
    vehicle_details: str
    damage_description: str

class RepairRequestCreate(RepairRequestBase):
    pass

class RepairRequestResponse(RepairRequestBase):
    id: int
    user_id: int
    image_path: Optional[str] = None
    status: str
    bids: List[RepairBidResponse] = []

    class Config:
        from_attributes = True
