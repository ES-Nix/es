import geopandas as gpd

from flask import Flask


app = Flask(__name__)


@app.route('/')
def index():
    expected = '1.0.1'
    result = gpd.__version__
    assert result == expected, f"Expected {expected}, got {result}"

    return 'Hello world!!'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
