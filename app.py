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
    w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
    with open('accounts.json') as accounts_file:
        accounts = json.load(accounts_file)
    priv_key = ""
    for acc in accounts.items():
        if acc[1]["address"] == account:
            priv_key = acc[1]["private_key"]
    account = w3.eth.account.privateKeyToAccount(priv_key)
    balance = int(w3.eth.getBalance(account.address))/10**18
    return render_template('dashboard.html', account=account.address, balance=balance)
