from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel
import os
import google.generativeai as genai
from PIL import Image
import io

from .. import schemas, models, database
from ..auth import get_current_user

router = APIRouter(
    prefix="/api/ai",
    tags=["AI"]
)

# In a real app, you would load this from env variables using dotenv
# Assuming it will be provided or mocked. We will try to load it from env.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "mock_key")
genai.configure(api_key=GEMINI_API_KEY)

class AIResponse(BaseModel):
    estimation: str
    percentage: int

@router.get("/analyze-report/{report_id}", response_model=AIResponse)
def analyze_report(
    report_id: int,
    db: Session = Depends(database.get_db)
):
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    api_key = os.getenv("GEMINI_API_KEY", "")
    
    # If there is no image, analyze the description instead
    if not report.image_path or not os.path.exists(report.image_path):
        try:
            if not api_key:
                return AIResponse(
                    estimation=f"MOCKED AI RESPONSE: Based on the description '{report.description}', we estimate moderate damage.",
                    percentage=30
                )
            
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-flash-latest')
            prompt = f"Analyze this incident report description. Estimate the damage severity as a percentage (0-100) based purely on the text. Description: '{report.description}'. Keep response professional and brief."
            response = model.generate_content(prompt)
            
            return AIResponse(
                estimation=response.text,
                percentage=40
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"AI text analysis failed: {str(e)}")
    
    # Analyze with image
    try:
        pil_image = Image.open(report.image_path)
        
        if not api_key:
            return AIResponse(
                estimation="MOCKED AI RESPONSE: The image reveals moderate structural damage. Required part replacement and painting estimated.",
                percentage=45
            )

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-flash-latest')
        prompt = "Analyze this car image from an incident report. Describe the visual damage, what parts are affected, and estimate the damage severity as a percentage (0-100). Keep the description professional and brief."
        response = model.generate_content([prompt, pil_image])
        
        return AIResponse(
            estimation=response.text,
            percentage=50
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI analysis failed: {str(e)}")

@router.post("/estimate-damage", response_model=AIResponse)
async def estimate_damage(
    image: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user)
):
    try:
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents))
        
        # In case the key is a mock, just return a mock response
        if GEMINI_API_KEY == "mock_key":
            return AIResponse(
                estimation="This is a mocked AI response showing moderate damage to the front bumper.",
                percentage=45
            )

        model = genai.GenerativeModel('gemini-flash-latest')
        prompt = "Analyze this car image. Describe the visual damage and estimate the damage severity as a percentage (0-100). Keep the description brief."
        response = model.generate_content([prompt, pil_image])
        
        estimation = response.text
        # Normally would parse the text to find the exact percentage, skipping for prototype simplicity
        # Default mock percentage if parsing isn't done correctly
        percentage = 50 
        
        return AIResponse(
            estimation=estimation,
            percentage=percentage
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI analysis failed: {str(e)}")
