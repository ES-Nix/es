import numpy as np

from flask import Flask


app = Flask(__name__)


@app.route('/')
def index():
    np.array_equal(np.array([1,2]), np.sqrt(np.square(np.array([1,2]))))
    return 'Hello world!! UWUlO50F1D'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
