import mmh3

from flask import Flask


app = Flask(__name__)


@app.route('/')
def index():
    assert mmh3.hash128(bytes(123)) == 126000048256919600573431412872524959502
    return 'Hello world!!'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
