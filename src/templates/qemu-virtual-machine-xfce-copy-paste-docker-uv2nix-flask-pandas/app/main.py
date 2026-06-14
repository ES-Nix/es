import pandas as pd

from flask import Flask


app = Flask(__name__)


@app.route('/')
def index():
    assert pd.DataFrame().to_json() == str({})
    return 'Hello world!! utEOuhDAx6'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
