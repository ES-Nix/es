from flask import Flask
# from django.core.management import execute_from_command_line


app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello world!!'

# @app.route('/pandas')
# def index_pandas():
#     return pd.__version__

def start():
    app.run(host='0.0.0.0', port=5000)


if __name__ == '__main__':
    start()
