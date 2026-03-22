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
