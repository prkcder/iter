import os
import psycopg 
import requests
import logging
from psycopg.rows import dict_row
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.StreamHandler(),          # prints to the terminal
        logging.FileHandler("sync.log"),  # also saves to a file
    ],
)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")

ITERABLE_API_KEY = os.getenv("ITERABLE_API_KEY")
ITERABLE_BASE_URL = "https://api.iterable.com/api"

HEADERS = {
    "Api-Key": ITERABLE_API_KEY,
    "Content-Type": "application/json",
}

QUERY = """
select distinct on (c.id)
    c.id as customer_id, c.email, c.first_name, c.last_name, c.plan_type, c.candidate,
    pv.id as page_view_id, pv.page, pv.device, pv.browser, pv.location, pv.event_time
from customers c
join page_views pv on c.id = pv.user_id
where c.plan_type = 'enterprise'
  and pv.page in ('Pricing', 'Settings')
  and pv.event_time >= now() - interval '7 days'
order by c.id, pv.event_time desc;
"""

connection = psycopg.connect(DATABASE_URL, row_factory=dict_row)
print("Connected to the database")

cursor = connection.cursor()
cursor.execute(QUERY)

rows = cursor.fetchall()
print(f"Found {len(rows)} customers")

for row in rows:
    user_payload = {
        "email": row["email"],
        "userId": str(row["customer_id"]),
        "dataFields": {
            "firstName": row["first_name"],
            "lastName": row["last_name"],
            "planType": row["plan_type"],
            "candidate": row["candidate"],
            "recentPageView": True,
        },
    }

    event_payload = {
        "email": row["email"],
        "userId": str(row["customer_id"]),
        "eventName": "page_view",
        "id": str(row["page_view_id"]),
        "createdAt": int(row["event_time"].timestamp()),
        "dataFields": {
            "page": row["page"],
            "device": row["device"],
            "browser": row["browser"],
            "location": row["location"],
            "timestamp": row["event_time"].strftime("%Y-%m-%d %H:%M:%S"),
            "candidate": row["candidate"],
        },
    }

    user_response = requests.post(f"{ITERABLE_BASE_URL}/users/update", json=user_payload, headers=HEADERS)
    print(row["email"], "users/update", user_response.status_code, user_response.text)

    event_response = requests.post(f"{ITERABLE_BASE_URL}/events/track", json=event_payload, headers=HEADERS)
    print(row["email"], "events/track", event_response.status_code, event_response.text)


connection.close()


