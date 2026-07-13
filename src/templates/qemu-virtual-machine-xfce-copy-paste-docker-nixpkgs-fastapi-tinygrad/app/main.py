import uvicorn
from fastapi import FastAPI
from tinygrad import Tensor

app = FastAPI()


@app.get("/")
async def root():
    N = 1024
    a, b = Tensor.rand(N, N), Tensor.rand(N, N)
    c = (a.reshape(N, 1, N) * b.T.reshape(1, N, N)).sum(axis=2)
    return {"message": f"Hello world {c.shape}"}


def start():
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=5000,
        reload=False,
    )


if __name__ == '__main__':
    start()
