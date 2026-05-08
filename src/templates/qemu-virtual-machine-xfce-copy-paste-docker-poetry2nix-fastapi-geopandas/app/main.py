import uvicorn
import geopandas as gpd

from fastapi import FastAPI


app = FastAPI()

@app.get("/")
async def root():
    expected = '1.0.1'
    result = gpd.__version__
    assert result == expected, f"Expected {expected}, got {result}"

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
