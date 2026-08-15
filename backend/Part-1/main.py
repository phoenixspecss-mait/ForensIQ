import os
import uuid

from fastapi import FastAPI, UploadFile, File, HTTPException

from tasks import extract_metadata
import db

app = FastAPI(title="ForeniQ - Part 1: Gateway")

# Create the jobs table if it doesn't already exist
db.init_db()

# Folder where uploaded files will be saved
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Only allow these file types for now (image/video)
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".mp4", ".mov"}

# Reject anything bigger than 50 MB (adjust as needed)
MAX_FILE_SIZE_MB = 50


@app.get("/")
def read_root():
    """Simple health check so you know the server is alive."""
    return {"status": "ok", "message": "Gateway is running"}


@app.post("/verify")
async def upload_file(file: UploadFile = File(...)):
    """
    Accepts one uploaded file and saves it to disk.
    Returns a job_id you'll later use to check status (once we add Celery).
    """
    # 1. Check the file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{ext}'. Allowed: {ALLOWED_EXTENSIONS}",
        )

    # 2. Read the file contents (in memory) so we can check size and save it
    contents = await file.read()
    size_mb = len(contents) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(
            status_code=400,
            detail=f"File too large ({size_mb:.1f} MB). Max is {MAX_FILE_SIZE_MB} MB.",
        )

    # 3. Generate a unique job_id and save the file under that name
    job_id = str(uuid.uuid4())
    saved_filename = f"{job_id}{ext}"
    saved_path = os.path.join(UPLOAD_DIR, saved_filename)

    with open(saved_path, "wb") as f:
        f.write(contents)

    # 4. Create a database row for this job (status: queued)
    db.create_job(job_id, file.filename, saved_filename)

    # 5. Queue the background task (goes to Redis, picked up by the Celery worker).
    # We explicitly set task_id=job_id so that /verify/{job_id}/status can look
    # up this exact task later using the same job_id.
    extract_metadata.apply_async(args=[job_id, saved_filename], task_id=job_id)

    # 6. Return the job_id right away — don't make the client wait for processing
    return {
        "job_id": job_id,
        "original_filename": file.filename,
        "saved_as": saved_filename,
        "size_mb": round(size_mb, 2),
        "status": "queued",
    }


@app.get("/verify/{job_id}/status")
def check_status(job_id: str):
    """
    Check whether the background task for this job has finished.
    Reads from our own database instead of Celery's result backend,
    since our database keeps records permanently (Celery results expire).
    """
    job = db.get_job(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail=f"No job found with id {job_id}")
    return job


@app.get("/jobs")
def list_recent_jobs(limit: int = 20):
    """Returns the most recent jobs, newest first — handy for debugging."""
    return db.list_jobs(limit=limit)
