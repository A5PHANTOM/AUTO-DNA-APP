from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/chat",
    tags=["Chat messaging"]
)

@router.post("/threads", response_model=schemas.ChatThreadResponse)
def create_or_get_thread(thread_req: schemas.ChatThreadCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    offer = db.query(models.SparePartOffer).filter(models.SparePartOffer.id == thread_req.offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    part_request = db.query(models.SparePartRequest).filter(models.SparePartRequest.id == offer.request_id).first()
    
    if current_user.role == "user" and part_request.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only chat on your own requests")
    if current_user.role == "workshop" and offer.workshop_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only chat on your own offers")
        
    user_id = part_request.user_id
    workshop_id = offer.workshop_id
    
    existing_thread = db.query(models.ChatThread).filter(
        models.ChatThread.offer_id == thread_req.offer_id,
        models.ChatThread.user_id == user_id,
        models.ChatThread.workshop_id == workshop_id
    ).first()
    
    if existing_thread:
        return existing_thread
        
    new_thread = models.ChatThread(offer_id=thread_req.offer_id, user_id=user_id, workshop_id=workshop_id)
    db.add(new_thread)
    db.commit()
    db.refresh(new_thread)
    return new_thread

@router.get("/threads", response_model=List[dict])
def get_threads(db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role == "workshop":
        threads = db.query(models.ChatThread).filter(models.ChatThread.workshop_id == current_user.id).all()
    else:
        threads = db.query(models.ChatThread).filter(models.ChatThread.user_id == current_user.id).all()
        
    result = []
    for t in threads:
        offer = db.query(models.SparePartOffer).filter(models.SparePartOffer.id == t.offer_id).first()
        part_request = db.query(models.SparePartRequest).filter(models.SparePartRequest.id == offer.request_id).first() if offer else None
        
        partner_id = t.user_id if current_user.role == "workshop" else t.workshop_id
        partner = db.query(models.User).filter(models.User.id == partner_id).first()
        
        result.append({
            "id": t.id,
            "offer_id": t.offer_id,
            "part_name": part_request.part_name if part_request else "Unknown Part",
            "partner_name": partner.username if partner else "Unknown User",
            "created_at": t.created_at
        })
    return result

@router.post("/threads/{thread_id}/messages", response_model=schemas.MessageResponse)
def send_message(thread_id: int, message: schemas.MessageCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    thread = db.query(models.ChatThread).filter(models.ChatThread.id == thread_id).first()
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
        
    if current_user.id not in [thread.user_id, thread.workshop_id] and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not a participant in this thread")
        
    new_message = models.Message(thread_id=thread_id, sender_id=current_user.id, text=message.text)
    db.add(new_message)
    db.commit()
    db.refresh(new_message)
    return new_message

@router.get("/threads/{thread_id}/messages", response_model=List[schemas.MessageResponse])
def get_messages(thread_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    thread = db.query(models.ChatThread).filter(models.ChatThread.id == thread_id).first()
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
        
    if current_user.id not in [thread.user_id, thread.workshop_id] and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not a participant in this thread")
        
    messages = db.query(models.Message).filter(models.Message.thread_id == thread_id).order_by(models.Message.timestamp.asc()).all()
    return messages
