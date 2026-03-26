from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel
import os
import google.generativeai as genai
from PIL import Image
import io
import re
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

    # Configure Gemini
    if api_key:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')

    # 🔹 Helper to extract percentage
    def extract_percentage(text):
        match = re.search(r'(\d{1,3})\s*%', text)
        if match:
            return min(int(match.group(1)), 100)
        return None

    # =========================
    # TEXT ANALYSIS (NO IMAGE)
    # =========================
    if not report.image_path or not os.path.exists(report.image_path):
        try:
            if not api_key:
                estimation_text = f"MOCKED: Based on '{report.description}', moderate damage detected."
                report.ai_damage_estimation = estimation_text
                db.commit()
                return AIResponse(
                    estimation=estimation_text,
                    percentage=30
                )

            prompt = f"""
            Analyze this incident report description and estimate damage severity.

            Description: "{report.description}"

            Return:
            - Brief professional explanation
            - Damage percentage (0-100%)

            Format example:
            Damage: XX%
            Explanation: ...
            """

            response = model.generate_content(prompt)
            text = response.text

            percentage = extract_percentage(text) or 40

            report.ai_damage_estimation = text
            db.commit()

            return AIResponse(
                estimation=text,
                percentage=percentage
            )

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"AI text analysis failed: {str(e)}")

    # =========================
    # IMAGE ANALYSIS
    # =========================
    try:
        pil_image = Image.open(report.image_path)

        if not api_key:
            estimation_text = "MOCKED: Moderate vehicle damage detected. Repair needed."
            report.ai_damage_estimation = estimation_text
            db.commit()
            return AIResponse(
                estimation=estimation_text,
                percentage=45
            )

        prompt = """
        Analyze this vehicle accident image.

        Return:
        - Visible damages
        - Affected parts
        - Estimated severity percentage (0-100%)

        Format:
        Damage: XX%
        Explanation: ...
        """

        response = model.generate_content([prompt, pil_image])
        text = response.text

        percentage = extract_percentage(text) or 50

        report.ai_damage_estimation = text
        db.commit()

        return AIResponse(
            estimation=text,
            percentage=percentage
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

        model = genai.GenerativeModel('gemini-2.5-flash')
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
