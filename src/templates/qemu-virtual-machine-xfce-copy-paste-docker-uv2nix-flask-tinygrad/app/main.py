from flask import Flask
from tinygrad import Tensor

app = Flask(__name__)

@app.route('/')
def index():
    N = 1024
    a, b = Tensor.rand(N, N), Tensor.rand(N, N)
    c = (a.reshape(N, 1, N) * b.T.reshape(1, N, N)).sum(axis=2)
    assert c.shape == (N, N)
    return 'Hello world!!'

def start():
    app.run(host='0.0.0.0', port=5000)

if __name__ == '__main__':
    start()
