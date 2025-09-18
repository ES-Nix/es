from fastapi import FastAPI
from app.tasks import add

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI with Celery"}

@app.post("/add/")
def add_numbers(a: int, b: int):
    task = add.delay(a, b)
    return {"task_id": task.id, "status": "Processing"}
