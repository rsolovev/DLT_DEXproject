from web3 import Web3
import json
from flask import Flask, render_template

app = Flask(__name__)


@app.route('/')
def select_account():
    with open('accounts.json') as accounts_file:
        accounts = json.load(accounts_file)
        addresses = []
        for acc in accounts.items():
            addresses.append(acc[1]["address"])
    return render_template('select_account.html', addresses=addresses)


@app.route('/<account>')
def dashboard(account):
    return render_template('dashboard.html', account=account)
