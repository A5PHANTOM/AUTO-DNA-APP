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
    spare_part_requests = relationship("SparePartRequest", back_populates="user")
    spare_part_offers = relationship("SparePartOffer", back_populates="workshop")
    chat_threads_as_user = relationship("ChatThread", foreign_keys="[ChatThread.user_id]", back_populates="user")
    chat_threads_as_workshop = relationship("ChatThread", foreign_keys="[ChatThread.workshop_id]", back_populates="workshop")
    messages = relationship("Message", back_populates="sender")

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

class SparePartRequest(Base):
    __tablename__ = "spare_part_requests"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    part_name = Column(String, index=True)
    car_model = Column(String)
    description = Column(Text)

    user = relationship("User", back_populates="spare_part_requests")
    offers = relationship("SparePartOffer", back_populates="request")

class SparePartOffer(Base):
    __tablename__ = "spare_part_offers"
    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("spare_part_requests.id"))
    workshop_id = Column(Integer, ForeignKey("users.id"))
    price = Column(Float)
    notes = Column(Text, nullable=True)

    request = relationship("SparePartRequest", back_populates="offers")
    workshop = relationship("User", back_populates="spare_part_offers")
    chat_threads = relationship("ChatThread", back_populates="offer")

from sqlalchemy import DateTime
import datetime

class ChatThread(Base):
    __tablename__ = "chat_threads"
    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("spare_part_offers.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    workshop_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    offer = relationship("SparePartOffer", back_populates="chat_threads")
    user = relationship("User", foreign_keys=[user_id], back_populates="chat_threads_as_user")
    workshop = relationship("User", foreign_keys=[workshop_id], back_populates="chat_threads_as_workshop")
    messages = relationship("Message", back_populates="thread")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    thread_id = Column(Integer, ForeignKey("chat_threads.id"))
    sender_id = Column(Integer, ForeignKey("users.id"))
    text = Column(Text)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    thread = relationship("ChatThread", back_populates="messages")
    sender = relationship("User", back_populates="messages")
