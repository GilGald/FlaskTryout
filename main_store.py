from flask import Flask
app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello and welcome to my shop!'

@app.route('/item/<int:item_idd>')
def hello(item_idd):
    return 'Hello, World' + str(item_idd)