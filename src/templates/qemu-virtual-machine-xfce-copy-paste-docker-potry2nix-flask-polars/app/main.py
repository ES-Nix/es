import polars as pl
from flask import Flask


app = Flask(__name__)


@app.route('/')
def index():
    pl.DataFrame()
    return 'Hello world!!'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
