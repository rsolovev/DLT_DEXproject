import os
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
    address, abi = get_contract_info("Wallet")
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
    address, abi = get_contract_info("Wallet")
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
        value = w3.toWei(float(eth), 'ether')
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


@app.route('/<account_address>/wallet/eth_management/send_eth', methods=['GET', 'POST'])
def wallet_send_eth(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("Wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    message = ''
    if request.method == "POST":
        receiver = request.form['rec']
        amount = request.form['amo']
        try:
            tx_hash = contract.functions.send_eth(w3_account.address, receiver, int(float(amount) * 10 ** 18)).transact(
                {'from': w3_account.address})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        except Exception as e:
            message = e
    return render_template('wallet_send_eth.html', account_addr=account_address, message=message)


@app.route('/<account_address>/wallet/coins_management', methods=['GET', 'POST'])
def wallet_coins_management(account_address):
    return render_template('wallet_coins_management.html', account_addr=account_address)


@app.route('/<account_address>/wallet/coins_management/create_token', methods=['GET', 'POST'])
def wallet_create_token(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("Wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    if request.method == "POST":
        total_supply = request.form['tot']
        name = request.form['name']
        symbol = request.form['sym']
        decimals = request.form['dec']
        tx_hash = contract.functions.createToken(w3_account.address, int(total_supply), name, symbol,
                                                 int(decimals)).transact(
            {'from': w3_account.address})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

        token_addr = contract.functions.getAddr().call({'from': w3_account.address})
        if os.path.isfile('data/tokens.json'):
            with open('data/tokens.json') as db_file:
                db = json.loads(db_file.read())
        db[symbol] = token_addr
        with open('data/tokens.json', 'w') as outfile:
            json.dump(db, outfile)
    return render_template('wallet_create_coin.html', account_addr=account_address)


@app.route('/<account_address>/wallet/coins_management/available_coins', methods=['GET', 'POST'])
def wallet_available_coins(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("Wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    coins = get_coins()
    balances = []
    for sym, tok_address in coins.items():
        token_balance = contract.functions.token_balanceOf(w3_account.address, tok_address).call(
            {'from': w3_account.address})
        balances.append(token_balance)
    return render_template('wallet_available_coins.html', account_addr=account_address, coins=coins, balances=balances)


@app.route('/<account_address>/wallet/coins_management/add_custom_token', methods=['GET', 'POST'])
def wallet_add_token(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("Wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    message = ''
    if request.method == "POST":
        try:
            token_addr = request.form['add']
            tx_hash = contract.functions.add_token(w3_account.address, token_addr).transact(
                {'from': w3_account.address})
            tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            if tx_receipt['status'] == 1:
                message = str(f'{tx_hash.hex()} confirmed\n') + \
                          "deployed at block: " + str(tx_receipt['blockNumber'])
            else:
                message = "ERROR"

            if os.path.isfile('data/tokens.json'):
                with open('data/tokens.json') as db_file:
                    db = json.loads(db_file.read())
            db[request.form['tic']] = token_addr
            with open('data/tokens.json', 'w') as outfile:
                json.dump(db, outfile)
        except Exception as e:
            message = e

    return render_template('wallet_add_custom_token.html', account_addr=account_address, message=message)


@app.route('/<account_address>/wallet/coins_management/send_token', methods=['GET', 'POST'])
def wallet_send_token(account_address):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("Wallet")
    contract = w3.eth.contract(address=address, abi=abi)
    message = ''
    if request.method == "POST":
        # try:
        receiver = request.form['rec']
        amount = request.form['amo']
        if os.path.isfile('data/tokens.json'):
            with open('data/tokens.json') as db_file:
                db = json.loads(db_file.read())
        token_addr = db[request.form['tic']]

        tx_hash = contract.functions.send_token(w3_account.address, receiver, token_addr,
                                                int(amount)).transact(
            {'from': w3_account.address})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
        # except Exception as e:
        #    message = e
    return render_template('wallet_send_token.html', account_addr=account_address, message=message)


@app.route('/<account_address>/wallet/coins_management/sell_token/<token>', methods=['GET', 'POST'])
def wallet_sell_token(account_address, token):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("MathchingEngine")
    contract = w3.eth.contract(address=address, abi=abi)
    message = ''
    if request.method == "POST":
        price = request.form['pri']
        amount = request.form['amo']
        if os.path.isfile('data/tokens.json'):
            with open('data/tokens.json') as db_file:
                db = json.loads(db_file.read())
        token_addr = db[token]
        tx_hash = contract.functions.sellOffer(w3_account.address, token_addr, int(float(price) * 10 ** 18),
                                               int(amount)).transact(
            {'from': w3_account.address})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return render_template('wallet_sell_token.html', account_addr=account_address, message=message, token=token)


@app.route('/<account_address>/wallet/coins_management/buy_token/<token>', methods=['GET', 'POST'])
def wallet_buy_token(account_address, token):
    w3 = get_w3()
    w3_account = get_w3_account(account_address)
    w3.eth.defaultAccount = w3_account
    address, abi = get_contract_info("MathchingEngine")
    contract = w3.eth.contract(address=address, abi=abi)
    message = ''
    if request.method == "POST":
        price = request.form['pri']
        amount = request.form['amo']
        if os.path.isfile('data/tokens.json'):
            with open('data/tokens.json') as db_file:
                db = json.loads(db_file.read())
        token_addr = db[token]
        tx_hash = contract.functions.buyOffer(w3_account.address, token_addr, int(float(price) * 10 ** 18),
                                              int(amount)).transact(
            {'from': w3_account.address})
        tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return render_template('wallet_buy_token.html', account_addr=account_address, message=message, token=token)
