from flask import Flask, render_template
from utils import *

app = Flask(__name__)


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


@app.route('/<account_address>/wallet')
def wallet_dashboard(account_address):
    w3_account = get_w3_account(account_address)
    name = get_name_from_w3account(w3_account)
    return render_template('wallet_dashboard.html', account_addr=w3_account.address, name=name)


@app.route('/<account_address>/wallet/create_wallet')
def create_wallet(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    tx_hash = contract.functions.create_wallet().transact({'from': w3_account.address})
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    if tx_receipt['status'] == 1:
        message = str(f'{tx_hash.hex()} confirmed\n') + \
                  "deployed at block: " + str(tx_receipt['blockNumber'])
    else:
        message = "ERROR"
    return render_template('create_wallet.html', message=message, account_addr=account_address)


@app.route('/<account_address>/wallet/eth_balance')
def check_wallet_eth_balance(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    eth_balance = contract.functions.eth_balanceOf(w3_account.address).call({'from': w3_account.address})
    return render_template('wallet_eth_balance.html', message=eth_balance, account_addr=account_address)


# TODO: deposit template, dex call
@app.route('/<account_address>/wallet/deposit_eth')
def deposit_eth_to_wallet(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("wallet")
    contract = w3.eth.contract(address=address, abi=abi)

    pass
