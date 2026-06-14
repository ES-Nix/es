from flask import Flask
from scipy import optimize


app = Flask(__name__)


@app.route('/')
def index():
    def f(x):
        return x**3 - 1

    def fprime1(x):
        return 3 * x**2
    
    def fprime2(x):
        return 6 * x

    # https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.newton.html
    result = optimize.newton(f, 1.5, fprime=fprime1, fprime2=fprime2)
    expected = 1.0
    assert result == expected, f"Expected {expected}, got {result}"

    return 'Hello world!!'


def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
