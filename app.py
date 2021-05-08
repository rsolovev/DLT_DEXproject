from flask import Flask, render_template, request
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
    tx_hash = contract.functions.create_wallet(w3_account.address).transact({'from': w3_account.address})
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    if tx_receipt['status'] == 1:
        message = str(f'{tx_hash.hex()} confirmed\n') + \
                  "deployed at block: " + str(tx_receipt['blockNumber'])
    else:
        message = "ERROR"
    return render_template('create_wallet.html', message=message, account_addr=account_address)


@app.route('/<account_address>/wallet/eth_management', methods=['GET', 'POST'])
def wallet_eth_management(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    eth_balance = contract.functions.eth_balanceOf(w3_account.address).call({'from': w3_account.address}) / 10 ** 18
    message = ''
    # deposit/withdraw part
    if request.method == "POST":
        if request.form['dep'] != '':
            eth = request.form['dep']
        elif request.form['with'] != '':
            eth = request.form['with']
        else:
            eth = 0
        value = w3.toWei(int(eth), 'ether')
        if request.form['dep'] != '':
            tx_hash = contract.functions.deposit_eth(w3_account.address).transact(
                {'from': w3_account.address, 'value': value})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        elif request.form['with'] != '':
            try:
                tx_hash = contract.functions.withdraw(w3_account.address, value).transact(
                    {'from': w3_account.address})
                tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            except Exception as e:
                message = e
    return render_template('wallet_eth_management.html', balance=eth_balance, account_addr=account_address,
                           message=message)


@app.route('/<account_address>/wallet/coins_management', methods=['GET', 'POST'])
def wallet_coins_management(account_address):
    return render_template('wallet_coins_management.html', account_addr=account_address)


@app.route('/<account_address>/wallet/coins_management/create_token', methods=['GET', 'POST'])
def wallet_create_token(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    if request.method == "POST":
        total_supply = request.form['tot']
        name = request.form['name']
        symbol = request.form['sym']
        decimals = request.form['dec']
        token_address = contract.functions.createToken(w3_account.address, int(total_supply), name, symbol,
                                                       int(decimals)).transact(
            {'from': w3_account.address})
        tx_receipt = w3.eth.waitForTransactionReceipt(token_address)
        print(token_address)
    return render_template('wallet_create_coin.html', account_addr=account_address)
