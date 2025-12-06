from http.client import HTTPException
from fastapi import FastAPI
from celery.result import AsyncResult
from app.tasks import add, celery_app


app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI with Celery"}

@app.post("/add/")
def add_numbers(a: int, b: int):
    task = add.delay(a, b)
    return {"task_id": task.id, "status": "Processing"}

@app.get("/result/{task_id}")
async def get_result(task_id: str, timeout: int = 5):
    result = AsyncResult(task_id, app=celery_app)
    try:
        value = result.get(timeout=timeout)
        return {
            "task_id": task_id,
            "status": result.status,
            "result": value
        }
    except TimeoutError:
        raise HTTPException(status_code=408, detail="Task result not ready (timeout)")
