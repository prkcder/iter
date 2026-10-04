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


# Query customers on one plan who viewed Pricing or Settings in the last 7 days,
# keeping only each customer's latest qualifying page view.

# distinct on (c.id) keeps one row per customer; ordering by event_time desc
# makes that row the customer's newest qualifying page view.
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

def fetch_rows():
    """Run the query and return each row as a dictionary."""
    # The connection closes as soon as the query finishes,
    # so it isn't held open while we wait on Iterable.
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as connection:
        rows = connection.execute(QUERY).fetchall()
    return rows


def build_user_payload(row):
    """Profile fields for Iterable's users/update."""
    return {
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


def build_event_payload(row):
    """page_view event for Iterable's events/track."""
    return {
        "email": row["email"],
        "userId": str(row["customer_id"]),
        "eventName": "page_view",
        # Reusing the page view id means re-running the script
        # updates the same event instead of creating a duplicate.
        "id": str(row["page_view_id"]),
        # When the view actually happened (Unix seconds), not when the script ran
        "createdAt": int(row["event_time"].timestamp()),
        "dataFields": {
            "page": row["page"],
            "device": row["device"],
            "browser": row["browser"],
            "location": row["location"],
            # Iterable's date format: yyyy-MM-dd HH:mm:ss
            "timestamp": row["event_time"].strftime("%Y-%m-%d %H:%M:%S"),
            "candidate": row["candidate"],
        },
    }


def send_to_iterable(endpoint, payload, email):
    """POST a payload to Iterable, log the result, and return True on success."""
    url = f"{ITERABLE_BASE_URL}/{endpoint}"
 
    try:
        # timeout so the script never hangs if Iterable doesn't respond
        response = requests.post(url, json=payload, headers=HEADERS, timeout=10)
    except requests.RequestException as error:
        logger.error(f"{email} {endpoint} network error: {error}")
        return False
 
    if response.ok:
        logger.info(f"{email} {endpoint} {response.status_code} {response.text}")
        return True
 
    if 400 <= response.status_code < 500:
        # Our request was wrong (bad key, bad field type, etc.)
        logger.error(f"{email} {endpoint} client error {response.status_code}: {response.text}")
    else:
        # Problem on Iterable's side
        logger.error(f"{email} {endpoint} server error {response.status_code}: {response.text}")
    return False
 
 
def main():
    # Fail early with a clear message instead of a confusing 401
    if not DATABASE_URL or not ITERABLE_API_KEY:
        logger.error("Missing DATABASE_URL or ITERABLE_API_KEY in .env")
        return
 
    try:
        rows = fetch_rows()
    except psycopg.Error as error:
        logger.error(f"Database error: {error}")
        return
 
    logger.info(f"Found {len(rows)} customers")
 
    # One failed call doesn't stop the run; the summary shows the totals
    results = []
    for row in rows:
        results.append(send_to_iterable("users/update", build_user_payload(row), row["email"]))
        results.append(send_to_iterable("events/track", build_event_payload(row), row["email"]))
 
    logger.info(f"Done: {results.count(True)} succeeded, {results.count(False)} failed")
 

if __name__ == "__main__":
    main()
    