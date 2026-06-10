import mmh3
import uvicorn

from fastapi import FastAPI


app = FastAPI()

@app.get("/")
async def root():
    expected = 126000048256919600573431412872524959502
    result = mmh3.hash128(bytes(123))
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
