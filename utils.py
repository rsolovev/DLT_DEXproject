from web3 import Web3
import json


def get_w3():
    w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
    return w3


def get_contract_info(name):
    with open('data/database.json') as db_file:
        db = json.loads(db_file.read())
    address = db["{}".format(name)]
    with open("contracts/" + name + ".abi") as abi_file:
        abi = json.loads(abi_file.read())

    return address, abi


def get_accounts():
    with open('data/accounts.json') as accounts_file:
        accounts = json.load(accounts_file)
    return accounts


def get_private_key(account_addr):
    accounts = get_accounts()
    priv_key = ""
    for acc in accounts.items():
        if acc[1]["address"] == account_addr:
            priv_key = acc[1]["private_key"]
    return priv_key


def get_w3_account(account_addr):
    w3 = get_w3()
    priv_key = get_private_key(account_addr)
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


def get_coins():
    with open('data/tokens.json') as db_file:
        coins = json.loads(db_file.read())
    return coins
