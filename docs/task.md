# Auto DNA - Task Checklist

## 1. Project Setup & Database
- [ ] Initialize Python virtual environment.
- [ ] Set up FastAPI project structure.
- [ ] Implement SQLite database setup and connection.
- [ ] Create SQLAlchemy models (Users, Reports, Vehicles).
- [ ] Implement database migration (Alembic or basic create tables).

## 2. Backend API Development (FastAPI)
- [ ] **Authentication Module:**
  - [ ] Implement User/Admin signup and login endpoints.
  - [ ] Implement basic session or token-based auth.
- [ ] **Report Module:**
  - [ ] Implement endpoint to create a vehicle incident report (with image upload).
  - [ ] Implement endpoint to retrieve user's reports.
- [ ] **Search Module:**
  - [ ] Implement endpoint to search vehicle history by number plate.
- [ ] **Marketplace Module:**
  - [ ] Implement endpoint to post a used vehicle (with image upload).
  - [ ] Implement endpoint to fetch all posted vehicles.
- [ ] **AI Module:**
  - [ ] Integrate Gemini API for vehicle damage analysis.
  - [ ] Create endpoint to process image/description and return estimated damage percentage.
- [ ] **Admin Module (Backend):**
  - [ ] Endpoint to fetch all reports (pending, approved, rejected).
  - [ ] Endpoint to update report status.

## 3. Admin Panel Development (Streamlit)
- [ ] Initialize Streamlit project.
- [ ] Implement Admin Login page.
- [ ] Implement Admin Dashboard to view all reports.
- [ ] Implement functionality to Approve/Reject reports.

## 4. Frontend Application Development (Flutter)
- [ ] Initialize Flutter project.
- [ ] Set up routing and state management (e.g., Provider or Riverpod).
- [ ] **Authentication UI:**
  - [ ] Login and Signup Screens.
- [ ] **Home / Dashboard:**
  - [ ] Navigation menu structure.
- [ ] **Report Submission UI:**
  - [ ] Form to submit incident details.
  - [ ] Image picker integration.
  - [ ] Integration with AI damage estimation.
- [ ] **Vehicle History Search UI:**
  - [ ] Search bar for number plate and results view.
- [ ] **Marketplace UI:**
  - [ ] List of available vehicles for sale.
  - [ ] Form to post a vehicle for sale.

## 5. Integration and Testing
- [ ] Connect Flutter app to FastAPI backend.
- [ ] Test end-to-end flows for User reporting and Admin approval.
- [ ] Test AI damage estimation accuracy and error handling.
- [ ] Final UI/UX review and bug fixes.
