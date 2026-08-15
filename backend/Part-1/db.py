import sqlite3
import json
from datetime import datetime, timezone

DB_PATH = "jobs.db"


def get_connection():
    """
    Opens a connection to the SQLite database file.
    SQLite stores the whole database as a single file (jobs.db),
    which is created automatically the first time we write to it.
    """
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # lets us access columns by name
    return conn


def init_db():
    """
    Creates the 'jobs' table if it doesn't already exist.
    Call this once when the app starts up.
    """
    conn = get_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS jobs (
            job_id TEXT PRIMARY KEY,
            original_filename TEXT,
            saved_filename TEXT,
            status TEXT NOT NULL,
            result_json TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()


def create_job(job_id: str, original_filename: str, saved_filename: str):
    """Inserts a new job row with status 'queued'."""
    now = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    conn.execute(
        """
        INSERT INTO jobs (job_id, original_filename, saved_filename, status, result_json, created_at, updated_at)
        VALUES (?, ?, ?, 'queued', NULL, ?, ?)
        """,
        (job_id, original_filename, saved_filename, now, now),
    )
    conn.commit()
    conn.close()


def update_job_status(job_id: str, status: str, result: dict | None = None):
    """
    Updates a job's status (e.g. 'processing', 'done', 'failed') and,
    optionally, stores its result as a JSON string.
    """
    now = datetime.now(timezone.utc).isoformat()
    conn = get_connection()
    conn.execute(
        """
        UPDATE jobs
        SET status = ?, result_json = ?, updated_at = ?
        WHERE job_id = ?
        """,
        (status, json.dumps(result) if result is not None else None, now, job_id),
    )
    conn.commit()
    conn.close()


def get_job(job_id: str) -> dict | None:
    """Fetches one job by id. Returns None if it doesn't exist."""
    conn = get_connection()
    row = conn.execute("SELECT * FROM jobs WHERE job_id = ?", (job_id,)).fetchone()
    conn.close()

    if row is None:
        return None

    job = dict(row)
    # Turn the stored JSON string back into a real dict for the API response
    job["result"] = json.loads(job["result_json"]) if job["result_json"] else None
    del job["result_json"]
    return job


def list_jobs(limit: int = 50) -> list[dict]:
    """Returns the most recent jobs, newest first."""
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM jobs ORDER BY created_at DESC LIMIT ?", (limit,)
    ).fetchall()
    conn.close()

    jobs = []
    for row in rows:
        job = dict(row)
        job["result"] = json.loads(job["result_json"]) if job["result_json"] else None
        del job["result_json"]
        jobs.append(job)
    return jobs
