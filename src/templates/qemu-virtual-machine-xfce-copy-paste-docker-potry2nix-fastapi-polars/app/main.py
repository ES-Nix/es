import uvicorn
import polars as pl

from fastapi import FastAPI


app = FastAPI()

@app.get("/")
async def root():
    # expected = '{"columns":[{"name":"foo","datatype":"Int64","bit_settings":"","values":[1,2,3]},{"name":"bar","datatype":"Int64","bit_settings":"","values":[6,7,8]}]}'
    result = pl.DataFrame(
        {
            "foo": [1, 2, 3],
            "bar": [6, 7, 8],
        }).write_json()

    # assert result == expected, f"Expected {expected}, got {result}"

    return {"message": "Hello world "}

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
