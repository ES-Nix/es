import uvicorn
import jax
import jax.numpy as jnp
from fastapi import FastAPI

app = FastAPI()

@jax.jit
def matmul(a, b):
    return jnp.dot(a, b)

@app.get("/")
async def root():
    key = jax.random.PRNGKey(0)
    N = 64
    a = jax.random.normal(key, (N, N))
    b = jax.random.normal(key, (N, N))
    c = matmul(a, b)
    return {"message": f"Hello world {c.shape}"}

def start():
    uvicorn.run("app.main:app", host="0.0.0.0", port=5000, reload=False)

if __name__ == '__main__':
    start()
