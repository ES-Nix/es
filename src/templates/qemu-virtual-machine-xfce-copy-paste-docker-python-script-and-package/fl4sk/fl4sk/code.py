from flask import Flask

# import numpy as np

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World! vQrEwlbbw94pj96bpvxb7d7p</p>"

# @app.route("/numpy")
# def np_hello_world():
#     return "<p>Hello, World! vQrEwlbbw94pj96bpvxb7d7p</p>"

foo = 1
