import pandas as pd
import uvicorn

from fastapi import FastAPI


app = FastAPI()

@app.get("/")
async def root():
    assert pd.DataFrame().to_json() == str({})
    return {"message": "Hello world!! nyFERAuO8L"}

def start():
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=5000,
        reload=True
    )


if __name__ == '__main__':
    print("Starting FastAPI server...")
    start()
