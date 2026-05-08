import requests
import json

base_url = "http://127.0.0.1:8000/api"

# 1. Login as workshop
# First we need to make sure we have a workshop user, if not we register
login_data = {"username": "test_workshop_1", "password": "password"}
r = requests.post(f"{base_url}/auth/login", data=login_data)

if r.status_code != 200:
    print("Logging in failed, registering...")
    r = requests.post(f"{base_url}/auth/register", json={"username": "test_workshop_1", "password": "password", "role": "workshop"})
    print("Register:", r.status_code, r.text)
    r = requests.post(f"{base_url}/auth/login", data=login_data)
    print("Login after register:", r.status_code, r.text)

token = r.json().get("access_token")
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# 2. Try to post a bid
bid_payload = {
    "price": 150.5,
    "notes": "Testing bid"
}

r = requests.post(f"{base_url}/repairs/1/bids", headers=headers, json=bid_payload)
print("Bid Response:", r.status_code, r.text)
