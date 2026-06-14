import uvicorn
import geopandas as gpd

from fastapi import FastAPI


app = FastAPI()

@app.get("/")
async def root():
    result = gpd.__version__

    return {"message": f"Hello world {result}"}

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
