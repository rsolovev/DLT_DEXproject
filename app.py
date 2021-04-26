from web3 import Web3
import json
from flask import Flask, render_template

app = Flask(__name__)


def get_w3():
    w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
    return w3


def get_accounts():
    with open('data/accounts.json') as accounts_file:
        accounts = json.load(accounts_file)
    return accounts


def get_w3_account(account_addr):
    w3 = get_w3()
    accounts = get_accounts()
    priv_key = ""
    for acc in accounts.items():
        if acc[1]["address"] == account_addr:
            priv_key = acc[1]["private_key"]
    account = w3.eth.account.privateKeyToAccount(priv_key)

    return account


def get_name_from_w3account(w3_account):
    accounts = get_accounts()
    name = ""
    for acc in accounts.items():
        if acc[1]["address"] == w3_account.address:
            name = acc[0]
    return name


def get_balances(w3_account):
    w3 = get_w3()
    balances = {"ETH": int(w3.eth.getBalance(w3_account.address)) / 10 ** 18}

    return balances


@app.route('/')
def select_account():
    accounts = get_accounts()
    addresses = [acc[1]["address"] for acc in accounts.items()]
    names = [acc[0] for acc in accounts.items()]
    users = dict(zip(names, addresses))
    return render_template('select_account.html', users=users)


@app.route('/<account_address>')
def dashboard(account_address):
    w3_account = get_w3_account(account_address)
    name = get_name_from_w3account(w3_account)
    balances = get_balances(w3_account)
    return render_template('dashboard.html', account_addr=w3_account.address, balances=balances, name=name)
