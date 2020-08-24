//
//  Commands.swift
//  BitSense
//
//  Created by Peter on 24/03/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

public enum BTC_CLI_COMMAND: String {
    case abortrescan = "abortrescan"
    case listlockunspent = "listlockunspent"
    case lockunspent = "lockunspent"
    case getblock = "getblock"
    case getbestblockhash = "getbestblockhash"
    case getaddressesbylabel = "getaddressesbylabel"
    case listlabels = "listlabels"
    case decodescript = "decodescript"
    case combinepsbt = "combinepsbt"
    case utxoupdatepsbt = "utxoupdatepsbt"
    case listaddressgroupings = "listaddressgroupings"
    case converttopsbt = "converttopsbt"
    case getaddressinfo = "getaddressinfo"
    case createmultisig = "createmultisig"
    case analyzepsbt = "analyzepsbt"
    case createpsbt = "createpsbt"
    case joinpsbts = "joinpsbts"
    case getmempoolinfo = "getmempoolinfo"
    case signrawtransactionwithkey = "signrawtransactionwithkey"
    case listwallets = "listwallets"
    case unloadwallet = "unloadwallet"
    case rescanblockchain = "rescanblockchain"
    case listwalletdir = "listwalletdir"
    case loadwallet = "loadwallet"
    case createwallet = "createwallet"
    case finalizepsbt = "finalizepsbt"
    case walletprocesspsbt = "walletprocesspsbt"
    case decodepsbt = "decodepsbt"
    case walletcreatefundedpsbt = "walletcreatefundedpsbt"
    case fundrawtransaction = "fundrawtransaction"
    case uptime = "uptime"
    case importmulti = "importmulti"
    case getdescriptorinfo = "getdescriptorinfo"
    case deriveaddresses = "deriveaddresses"
    case getrawtransaction = "getrawtransaction"
    case decoderawtransaction = "decoderawtransaction"
    case getnewaddress = "getnewaddress"
    case gettransaction = "gettransaction"
    case signrawtransactionwithwallet = "signrawtransactionwithwallet"
    case createrawtransaction = "createrawtransaction"
    case getrawchangeaddress = "getrawchangeaddress"
    case getwalletinfo = "getwalletinfo"
    case getblockchaininfo = "getblockchaininfo"
    case getbalance = "getbalance"
    case sendtoaddress = "sendtoaddress"
    case getunconfirmedbalance = "getunconfirmedbalance"
    case listtransactions = "listtransactions"
    case listunspent = "listunspent"
    case bumpfee = "bumpfee"
    case importprivkey = "importprivkey"
    case abandontransaction = "abandontransaction"
    case getpeerinfo = "getpeerinfo"
    case getnetworkinfo = "getnetworkinfo"
    case getmininginfo = "getmininginfo"
    case estimatesmartfee = "estimatesmartfee"
    case sendrawtransaction = "sendrawtransaction"
    case importaddress = "importaddress"
    case signmessagewithprivkey = "signmessagewithprivkey"
    case verifymessage = "verifymessage"
    case signmessage = "signmessage"
    case encryptwallet = "encryptwallet"
    case walletpassphrase = "walletpassphrase"
    case walletlock = "walletlock"
    case walletpassphrasechange = "walletpassphrasechange"
    case gettxoutsetinfo = "gettxoutsetinfo"
    case help = "help"
}

public enum LIGHTNING_CLI: String {
    case getinfo = "getinfo"
    case invoice = "invoice"
    case newaddr = "newaddr"
    case listfunds = "listfunds"
    case listtransactions = "listtransactions"
    case txprepare = "txprepare"
    case txsend = "txsend"
    case pay = "pay"
    case decodepay = "decodepay"
    case connect = "connect"
    case fundchannel_start = "fundchannel_start"
    case fundchannel_complete = "fundchannel_complete"
    case listpeers = "listpeers"
    case listsendpays = "listsendpays"
    case listinvoices = "listinvoices"
    case withdraw = "withdraw"
    case getroute = "getroute"
    case listchannels = "listchannels"
    case sendpay = "sendpay"
    case rebalance = "rebalance"
    case keysend = "keysend"
    case listnodes = "listnodes"
    case sendmsg = "sendmsg"
    case recvmsg = "recvmsg"
}
