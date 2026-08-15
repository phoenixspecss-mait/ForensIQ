from celery import Celery

# Redis running locally, default port.
# db=0 for the broker (task queue), db=1 for the result backend
# (keeping them separate avoids key collisions, as mentioned in the plan).
REDIS_BROKER_URL = "redis://localhost:6379/0"
REDIS_BACKEND_URL = "redis://localhost:6379/1"

celery_app = Celery(
    "foreniq",
    broker=REDIS_BROKER_URL,
    backend=REDIS_BACKEND_URL,
    include=["tasks"],  # tells Celery where to find task definitions
)

# Optional but nice: task results expire after 1 hour instead of
# sitting in Redis forever.
celery_app.conf.result_expires = 3600
