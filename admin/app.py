import streamlit as st
import requests
import pandas as pd
from collections import defaultdict
import os

API_URL = "http://192.168.1.2:8000/api"
REQUEST_TIMEOUT_SECONDS = 12
DEFAULT_PUBLIC_BASE_URL = os.getenv("BACKEND_PUBLIC_BASE_URL", API_URL.replace("/api", ""))

st.set_page_config(page_title="Auto DNA Admin Panel", layout="wide")


def inject_styles():
    st.markdown(
        """
        <style>
            .stApp {
                background: radial-gradient(circle at 20% 20%, #172554 0%, #0b1220 45%, #090f1a 100%);
            }
            .hero-card {
                background: linear-gradient(120deg, rgba(59,130,246,0.25), rgba(16,185,129,0.20));
                border: 1px solid rgba(148,163,184,0.25);
                border-radius: 16px;
                padding: 1.2rem 1.4rem;
                margin-bottom: 1rem;
            }
            .subtle-label {
                font-size: 0.82rem;
                color: #94a3b8;
                text-transform: uppercase;
                letter-spacing: 0.08em;
            }
            .metric-card {
                background: rgba(15, 23, 42, 0.88);
                border: 1px solid rgba(148,163,184,0.20);
                border-radius: 14px;
                padding: 0.9rem 1rem;
            }
            .metric-value {
                font-size: 1.5rem;
                font-weight: 700;
                color: #e2e8f0;
                margin-top: 0.25rem;
            }
            .plate-header {
                background: rgba(15, 23, 42, 0.88);
                border: 1px solid rgba(148,163,184,0.20);
                border-radius: 12px;
                padding: 0.7rem 1rem;
                margin: 0.75rem 0 0.5rem;
            }
            .status-pill {
                display: inline-block;
                padding: 0.18rem 0.55rem;
                border-radius: 999px;
                font-size: 0.78rem;
                font-weight: 600;
            }
            .status-approved { background: rgba(16,185,129,0.20); color: #6ee7b7; }
            .status-rejected { background: rgba(239,68,68,0.20); color: #fca5a5; }
            .status-pending { background: rgba(245,158,11,0.22); color: #fcd34d; }
            .login-shell {
                max-width: 500px;
                margin: 8vh auto 0;
                padding: 1.1rem;
                border-radius: 16px;
                border: 1px solid rgba(148,163,184,0.2);
                background: rgba(15, 23, 42, 0.9);
            }
        </style>
        """,
        unsafe_allow_html=True,
    )


def status_class(status):
    return {
        "approved": "status-approved",
        "rejected": "status-rejected",
        "pending": "status-pending",
    }.get((status or "pending").lower(), "status-pending")


def login(username, password):
    try:
        response = requests.post(
            f"{API_URL}/auth/login",
            data={"username": username, "password": password},
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        st.error(f"Cannot connect to backend: {exc}")
        return

    if response.status_code == 200:
        data = response.json()
        if data.get("role") == "admin":
            st.session_state["token"] = data["access_token"]
            st.rerun()
        else:
            st.error("Access denied. Admin privileges required.")
    else:
        st.error("Invalid credentials.")


def fetch_reports(token):
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(
            f"{API_URL}/admin/reports",
            headers=headers,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        st.error(f"Failed to fetch reports: {exc}")
        return []

    if response.status_code == 200:
        return response.json()
    st.error("Failed to fetch reports.")
    return []


def update_report_status(token, report_id, status):
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.patch(
            f"{API_URL}/admin/reports/{report_id}/status",
            params={"status": status},
            headers=headers,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        st.error(f"Network error while updating report {report_id}: {exc}")
        return

    if response.status_code == 200:
        st.success(f"Report {report_id} updated to {status}.")
        st.rerun()
    else:
        st.error(f"Failed to update report {report_id}.")


def build_image_url(image_path, public_base_url):
    if not image_path:
        return None

    path = str(image_path).strip()
    if not path:
        return None

    if path.startswith("http://") or path.startswith("https://"):
        return path

    normalized = path.replace("\\", "/")
    if normalized.startswith("uploads/"):
        return f"{public_base_url.rstrip('/')}/{normalized}"

    if "/uploads/" in normalized:
        suffix = normalized.split('/uploads/', 1)[1]
        return f"{public_base_url.rstrip('/')}/uploads/{suffix.lstrip('/')}"

    return f"{public_base_url.rstrip('/')}/{normalized.lstrip('/')}"


def grouped_by_plate(reports):
    grouped = defaultdict(list)
    for report in reports:
        grouped[str(report.get("plate_number", "UNKNOWN")).upper()].append(report)
    return dict(sorted(grouped.items(), key=lambda item: item[0]))


def render_metrics(reports):
    total = len(reports)
    approved = sum(1 for r in reports if (r.get("status") or "").lower() == "approved")
    rejected = sum(1 for r in reports if (r.get("status") or "").lower() == "rejected")
    pending = sum(1 for r in reports if (r.get("status") or "pending").lower() == "pending")

    col1, col2, col3, col4 = st.columns(4)
    for col, label, value in [
        (col1, "Total Reports", total),
        (col2, "Pending", pending),
        (col3, "Approved", approved),
        (col4, "Rejected", rejected),
    ]:
        with col:
            st.markdown(
                f"""
                <div class='metric-card'>
                    <div class='subtle-label'>{label}</div>
                    <div class='metric-value'>{value}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )


def render_login():
    st.markdown(
        """
        <div class='login-shell'>
            <div class='subtle-label'>Auto DNA</div>
            <h2 style='margin-top:0.35rem;'>Admin Control Center</h2>
            <p style='color:#94a3b8;margin-top:-0.35rem;'>Review incidents, validate AI summaries, and approve report outcomes.</p>
        </div>
        """,
        unsafe_allow_html=True,
    )
    with st.container():
        username = st.text_input("Username")
        password = st.text_input("Password", type="password")
        if st.button("Sign in", use_container_width=True):
            login(username.strip(), password)


def render_dashboard():
    st.sidebar.title("Admin")
    if st.sidebar.button("Logout", use_container_width=True):
        del st.session_state["token"]
        st.rerun()

    if "public_base_url" not in st.session_state:
        st.session_state["public_base_url"] = DEFAULT_PUBLIC_BASE_URL

    st.session_state["public_base_url"] = st.sidebar.text_input(
        "Backend public URL",
        value=st.session_state["public_base_url"],
        help="Used to render uploaded images. Example: http://192.168.1.4:8000",
    ).strip() or DEFAULT_PUBLIC_BASE_URL

    reports = fetch_reports(st.session_state["token"])

    st.markdown(
        """
        <div class='hero-card'>
            <div class='subtle-label'>Auto DNA Dashboard</div>
            <h2 style='margin:0.3rem 0 0.15rem;'>Incident Moderation Workspace</h2>
            <p style='margin:0;color:#cbd5e1;'>Monitor plate-level incident history and manage report decisions quickly.</p>
        </div>
        """,
        unsafe_allow_html=True,
    )

    if not reports:
        st.info("No reports found.")
        return

    render_metrics(reports)
    st.markdown("### Filters")

    filter_col1, filter_col2 = st.columns([2, 1])
    with filter_col1:
        search_plate = st.text_input("Search by plate", placeholder="Type plate number...").strip().upper()
    with filter_col2:
        status_filter = st.selectbox("Status", ["all", "pending", "approved", "rejected"], index=0)

    filtered = reports
    if search_plate:
        filtered = [r for r in filtered if search_plate in str(r.get("plate_number", "")).upper()]
    if status_filter != "all":
        filtered = [r for r in filtered if (r.get("status") or "pending").lower() == status_filter]

    if not filtered:
        st.warning("No reports match the current filters.")
        return

    grouped_reports = grouped_by_plate(filtered)
    st.markdown("### Plate-wise Report Queue")

    for plate, plate_reports in grouped_reports.items():
        st.markdown(
            f"""
            <div class='plate-header'>
                <strong>Plate:</strong> {plate} &nbsp;&nbsp; <span style='color:#94a3b8;'>Reports: {len(plate_reports)}</span>
            </div>
            """,
            unsafe_allow_html=True,
        )

        df = pd.DataFrame(plate_reports)
        for required in ["id", "description", "status", "ai_damage_estimation"]:
            if required not in df.columns:
                df[required] = ""
        st.dataframe(df[["id", "description", "status", "ai_damage_estimation"]], use_container_width=True)

        image_items = []
        for report in plate_reports:
            image_url = build_image_url(report.get("image_path"), st.session_state["public_base_url"])
            if image_url:
                image_items.append((report.get("id"), image_url))

        if image_items:
            st.markdown("**Uploaded Images**")
            cols = st.columns(min(3, len(image_items)))
            for idx, (report_id, image_url) in enumerate(image_items):
                with cols[idx % len(cols)]:
                    st.image(image_url, caption=f"Report #{report_id}", use_column_width=True)

        for report in plate_reports:
            report_id = report.get("id")
            report_status = (report.get("status") or "pending").lower()
            ai_text = str(report.get("ai_damage_estimation") or "").strip()
            if not ai_text or ai_text.lower().startswith("failed") or ai_text.lower().startswith("error"):
                ai_text = "No AI data available yet."

            with st.expander(f"Report #{report_id}"):
                st.markdown(
                    f"""
                    <span class='status-pill {status_class(report_status)}'>{report_status.upper()}</span>
                    """,
                    unsafe_allow_html=True,
                )
                st.write("Description")
                st.caption(str(report.get("description") or "No description provided."))
                st.write("AI Damage Estimation")
                st.caption(str(ai_text))
                if report.get("image_path"):
                    st.caption(f"Image path: {report['image_path']}")
                    image_url = build_image_url(report.get("image_path"), st.session_state["public_base_url"])
                    if image_url:
                        st.image(image_url, caption="Uploaded vehicle image", use_column_width=True)

                action_col1, action_col2 = st.columns(2)
                with action_col1:
                    if st.button(
                        "Approve",
                        key=f"approve_{report_id}",
                        disabled=report_status == "approved",
                        use_container_width=True,
                    ):
                        update_report_status(st.session_state["token"], report_id, "approved")
                with action_col2:
                    if st.button(
                        "Reject",
                        key=f"reject_{report_id}",
                        disabled=report_status == "rejected",
                        use_container_width=True,
                    ):
                        update_report_status(st.session_state["token"], report_id, "rejected")


inject_styles()

if "token" not in st.session_state:
    render_login()
else:
    render_dashboard()
