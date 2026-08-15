import os

import exifread
import c2pa

from celery_app import celery_app
import db

UPLOAD_DIR = "uploads"


def extract_exif(file_path: str) -> dict:
    """
    Reads EXIF tags from an image file (camera model, software used,
    GPS coordinates, timestamp, etc). Returns an empty dict if the
    file has no EXIF data (very common for screenshots, AI-generated
    images, or images stripped of metadata).
    """
    try:
        with open(file_path, "rb") as f:
            tags = exifread.process_file(f, details=False)
    except Exception as e:
        return {"error": f"Could not read EXIF: {e}"}

    if not tags:
        return {}

    # exifread returns special IFD objects; convert everything to plain
    # strings so this is safe to store as JSON.
    readable_tags = {tag: str(value) for tag, value in tags.items()}

    return {
        "camera_make": readable_tags.get("Image Make"),
        "camera_model": readable_tags.get("Image Model"),
        "software": readable_tags.get("Image Software"),
        "datetime_original": readable_tags.get("EXIF DateTimeOriginal"),
        "gps_present": any(tag.startswith("GPS") for tag in readable_tags),
        "all_tags": readable_tags,
    }


def extract_c2pa(file_path: str) -> dict:
    """
    Checks for a C2PA / Content Credentials manifest — a cryptographically
    signed record of how the file was created/edited. Many AI image
    generators (and some cameras/apps) now embed one.

    No manifest at all is the NORMAL case for most files — that alone
    isn't proof of fakery, just absence of provenance data.
    """
    try:
        with c2pa.Reader(file_path) as reader:
            manifest_json = reader.json()
        return {
            "has_c2pa": True,
            "manifest": manifest_json,
        }
    except c2pa.C2paError.ManifestNotFound:
        return {"has_c2pa": False}
    except Exception as e:
        # Any other error (corrupt manifest, unsupported format, etc.)
        # — record it but don't crash the whole job over it.
        return {"has_c2pa": False, "error": str(e)}


@celery_app.task(name="tasks.extract_metadata")
def extract_metadata(job_id: str, saved_filename: str):
    """
    Real metadata extraction task. Given the job_id and the filename
    saved on disk (from the /verify upload), runs EXIF + C2PA extraction,
    saves the result to the database, and returns the combined result.
    """
    db.update_job_status(job_id, "processing")

    file_path = os.path.join(UPLOAD_DIR, saved_filename)

    if not os.path.exists(file_path):
        error_result = {"job_id": job_id, "error": f"File not found: {file_path}"}
        db.update_job_status(job_id, "failed", error_result)
        return error_result

    exif_data = extract_exif(file_path)
    c2pa_data = extract_c2pa(file_path)

    # This is the normalized summary Part 4's ensemble model will
    # eventually consume, alongside Part 2/3's AI scores.
    signals = {
        "exif_present": bool(exif_data) and "error" not in exif_data,
        "has_c2pa": c2pa_data.get("has_c2pa", False),
        "software_tag": exif_data.get("software") if exif_data else None,
        "gps_present": exif_data.get("gps_present", False) if exif_data else False,
    }

    result = {
        "job_id": job_id,
        "exif": exif_data,
        "c2pa": c2pa_data,
        "signals": signals,
    }

    db.update_job_status(job_id, "done", result)
    return result
