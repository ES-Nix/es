from flask import Flask
import jax
import jax.numpy as jnp

app = Flask(__name__)


@jax.jit
def matmul(a, b):
    return jnp.dot(a, b)


@app.route('/')
def index():
    key = jax.random.PRNGKey(0)
    N = 64
    a = jax.random.normal(key, (N, N))
    b = jax.random.normal(key, (N, N))
    matmul(a, b)
    return 'Hello world!!'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
