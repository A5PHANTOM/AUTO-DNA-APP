import streamlit as st
import requests
import pandas as pd

API_URL = "http://127.0.0.1:8000/api"

st.set_page_config(page_title="Auto DNA Admin Panel", layout="wide")

def login(username, password):
    response = requests.post(f"{API_URL}/auth/login", data={"username": username, "password": password})
    if response.status_code == 200:
        data = response.json()
        if data.get("role") == "admin":
            st.session_state["token"] = data["access_token"]
            st.success("Logged in successfully!")
            st.rerun()
        else:
            st.error("Access denied. Admin privileges required.")
    else:
        st.error("Invalid credentials.")

def fetch_reports(token):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{API_URL}/admin/reports", headers=headers)
    if response.status_code == 200:
        return response.json()
    st.error("Failed to fetch reports.")
    return []

def update_report_status(token, report_id, status):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.patch(f"{API_URL}/admin/reports/{report_id}/status", params={"status": status}, headers=headers)
    if response.status_code == 200:
        st.success(f"Report {report_id} updated to {status}.")
        st.rerun()
    else:
        st.error(f"Failed to update report {report_id}.")

if "token" not in st.session_state:
    st.title("Auto DNA Admin Login")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")
    if st.button("Login"):
        login(username, password)
else:
    st.title("Auto DNA Admin Dashboard")
    if st.sidebar.button("Logout"):
        del st.session_state["token"]
        st.rerun()
    
    reports = fetch_reports(st.session_state["token"])
    
    if reports:
        st.subheader("Search & Filter")
        search_plate = st.text_input("Search by Plate Number", "", placeholder="Enter plate number...").strip().upper()
        
        if search_plate:
            reports = [r for r in reports if search_plate in r['plate_number'].upper()]

        if not reports:
            st.warning("No reports found for this plate number.")
        else:
            st.subheader("Vehicle Incident Reports (Grouped by Plate)")
            
            # Grouping by plate number
            grouped_reports = {}
            for r in reports:
                plate = r['plate_number']
                if plate not in grouped_reports:
                    grouped_reports[plate] = []
                grouped_reports[plate].append(r)
            
            for plate, plate_reports in grouped_reports.items():
                st.markdown(f"### 🚗 Plate: **{plate}** ({len(plate_reports)} Reports)")
                
                # Show dataframe for this specific plate
                df = pd.DataFrame(plate_reports)
                df = df[['id', 'description', 'status', 'ai_damage_estimation']]
                st.dataframe(df, use_container_width=True)

                st.markdown(f"**Manage Reports for {plate}:**")
                for report in plate_reports:
                    with st.expander(f"Report ID: {report['id']} - {report['status'].upper()}"):
                        st.write(f"**Description:** {report['description']}")
                        st.write(f"**AI Estimation:** {report.get('ai_damage_estimation', 'N/A')}")
                        if report.get('image_path'):
                            st.write(f"**Image Path:** {report['image_path']}")
                        
                        col1, col2 = st.columns(2)
                        with col1:
                            if st.button("Approve", key=f"approve_{report['id']}", disabled=report['status'] == 'approved'):
                                update_report_status(st.session_state["token"], report['id'], "approved")
                        with col2:
                            if st.button("Reject", key=f"reject_{report['id']}", disabled=report['status'] == 'rejected'):
                                update_report_status(st.session_state["token"], report['id'], "rejected")
                st.divider()
    else:
        st.info("No reports found.")
