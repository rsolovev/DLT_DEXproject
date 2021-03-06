from web3 import Web3, HTTPProvider
import json
import os.path
from os import walk


def deploy(conractName):
    w3 = Web3(HTTPProvider("HTTP://127.0.0.1:7545"))
    global wallet_addr
    with open("contracts/" + conractName + ".abi") as abi_file:
        abi = json.loads(abi_file.read())
    with open("contracts/" + conractName + ".bin") as bin_file:
        bytecode = json.loads(bin_file.read())
    with open('data/service_account.json') as safile:
        service_account = json.load(safile)
    private_key = service_account["Service_account"]["private_key"]

    w3.eth.account = w3.eth.account.privateKeyToAccount(private_key)
    contract = w3.eth.contract(abi=abi, bytecode=bytecode["object"])

    if conractName == "ERC20":
        tx_id = contract.constructor(10000, "Aboba token", "ABB", 18, w3.eth.account.address).transact(
            {'from': w3.eth.account.address})
    elif conractName == "Wallet":
        tx_id = contract.constructor().transact({'from': w3.eth.account.address})
    elif conractName == "MathchingEngine":
        tx_id = contract.constructor(wallet_addr).transact({'from': w3.eth.account.address})

    tx_receipt = w3.eth.waitForTransactionReceipt(tx_id)
    if tx_receipt['status'] == 1:
        print(f'{tx_id.hex()} confirmed')
        print("contract address: " + tx_receipt['contractAddress'])
        print("deployed at block: " + str(tx_receipt['blockNumber']))

    db = {}
    if os.path.isfile('data/database.json'):
        with open('data/database.json') as db_file:
            db = json.loads(db_file.read())
    db[conractName] = tx_receipt['contractAddress']
    with open('data/database.json', 'w') as outfile:
        json.dump(db, outfile)

    if conractName == "Wallet":
        wallet_addr = tx_receipt['contractAddress']


def deploy_all():
    contracts = ['ERC20', 'Wallet', 'MathchingEngine']
    for contract in contracts:
        deploy(contract)
        pass


wallet_addr = ''
deploy_all()
db = {}
with open('data/tokens.json', 'w') as outfile:
    json.dump(db, outfile)
