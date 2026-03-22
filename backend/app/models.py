from sqlalchemy import Column, Integer, String, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String, default="user")  # 'user' or 'admin'

    reports = relationship("Report", back_populates="user")
    vehicles = relationship("Vehicle", back_populates="owner")

class Report(Base):
    __tablename__ = "reports"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    plate_number = Column(String, index=True)
    description = Column(Text)
    image_path = Column(String, nullable=True)
    status = Column(String, default="pending")  # 'pending', 'approved', 'rejected'
    ai_damage_estimation = Column(Text, nullable=True) # AI analysis result

    user = relationship("User", back_populates="reports")

class Vehicle(Base):
    __tablename__ = "vehicles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    vehicle_name = Column(String)
    model = Column(String)
    year = Column(Integer)
    plate_number = Column(String, index=True)
    price = Column(Float)
    description = Column(Text)
    image_path = Column(String, nullable=True)
    contact_info = Column(String)

    owner = relationship("User", back_populates="vehicles")
