import numpy as np
import uvicorn
from fastapi import FastAPI

import matmul_fortran

app = FastAPI()


@app.get("/")
async def root():
    n = 4
    a = np.eye(n, dtype=np.float64)
    b = np.eye(n, dtype=np.float64)
    c = matmul_fortran.dgemm_simple(a, b, n)
    assert np.allclose(c, np.eye(n)), f"Fortran DGEMM wrong: {c}"
    return {"message": f"Hello world!! Fortran DGEMM: I*I=I ({n}x{n})"}


def start():
    uvicorn.run("app.main:app", host="0.0.0.0", port=5000, reload=False)


if __name__ == '__main__':
    start()
