//
//  Signer.swift
//  BitSense
//
//  Created by Peter on 28/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import Foundation
import LibWally

class Signer {
    
    class func sign(psbt: String, completion: @escaping ((psbt: String?, rawTx: String?, errorMessage: String?)) -> Void) {
        var seedsToSignWith = [[String:Any]]()
        var xprvsToSignWith = [HDKey]()
        var psbtToSign:PSBT!
        var chain:Network!
        var coinType:String!
        
        func reset() {
            seedsToSignWith.removeAll()
            xprvsToSignWith.removeAll()
            psbtToSign = nil
            chain = nil
        }
        
        func finalizeWithBitcoind() {
            Reducer.makeCommand(command: .finalizepsbt, param: "\"\(psbtToSign.description)\"") { (object, errorDescription) in
                if let result = object as? NSDictionary {
                    if let complete = result["complete"] as? Bool {
                        if complete {
                            let hex = result["hex"] as! String
                            reset()
                            completion((nil, hex, nil))
                        } else {
                            let psbt = result["psbt"] as! String
                            reset()
                            completion((psbt, nil, nil))
                        }
                    } else {
                        reset()
                        completion((nil, nil, errorDescription))
                    }
                } else {
                    reset()
                    completion((nil, nil, errorDescription))
                }
            }
        }
        
        func processWithActiveWallet() {
            Reducer.makeCommand(command: .walletprocesspsbt, param: "\"\(psbtToSign.description)\", true, \"ALL\", true") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    if let processedPsbt = dict["psbt"] as? String {
                        do {
                            psbtToSign = try PSBT(processedPsbt, chain)
                            if xprvsToSignWith.count > 0 {
                                attemptToSignLocally()
                            } else {
                                finalizeWithBitcoind()
                            }
                        } catch {
                            if xprvsToSignWith.count > 0 {
                                attemptToSignLocally()
                            } else {
                                finalizeWithBitcoind()
                            }
                        }
                    }
                } else {
                    reset()
                    completion((nil, nil, errorDescription))
                }
            }
        }
        
        func attemptToSignLocally() {
            /// Need to ensure similiar seeds do not sign mutliple times. This can happen if a user adds the same seed multiple times.
            var xprvStrings = [String]()
            for xprv in xprvsToSignWith {
                xprvStrings.append(xprv.description)
                
            }
            xprvsToSignWith.removeAll()
            var uniqueXprvs = Array(Set(xprvStrings))
            for uniqueXprv in uniqueXprvs {
                if let xprv = HDKey(uniqueXprv) {
                    xprvsToSignWith.append(xprv)
                }
            }
            if xprvsToSignWith.count > 0 {
                var signableKeys = [String]()
                for (i, key) in xprvsToSignWith.enumerated() {
                    let inputs = psbtToSign.inputs
                    for (x, input) in inputs.enumerated() {
                        /// Create an array of child keys that we know can sign our inputs.
                        if let origins: [PubKey : KeyOrigin] = input.canSign(key) {
                            for origin in origins {
                                if let childKey = try? key.derive(origin.value.path) {
                                    if let privKey = childKey.privKey {
                                        precondition(privKey.pubKey == origin.key)
                                        signableKeys.append(privKey.wif)
                                    }
                                }
                            }
                        } else {
                            // Libwally does not like signing with direct decendants of m (e.g. m/0/0), so if above fails we can try and fall back on this, deriving child keys directly from root xprv.
                            if let origins = input.origins {
                                for origin in origins {
                                    if let path = BIP32Path(origin.value.path.description.replacingOccurrences(of: "m/", with: "")) {
                                        if var childKey = try? key.derive(path) {
                                            if var privKey = childKey.privKey {
                                                signableKeys.append(privKey.wif)
                                                // Overwite vars with dummies for security
                                                privKey = Key("KwfUAErbeHJCafVr37aRnYcobent1tVV1iADD2k3T8VV1pD2qpWs", .mainnet)!
                                                childKey = HDKey("xpub6FETvV487Sr4VSV9Ya5em5ZAug4dtnFwgnMG7TFAfkJDHoQ1uohXft49cFenfpJHbPueMnfyxtBoAuvSu7XNL9bbLzcM1QJCPwtofqv3dqC")!
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        /// Once the above loops complete we remove an duplicate signing keys from the array then sign the psbt with each unique key.
                        if i + 1 == xprvsToSignWith.count && x + 1 == inputs.count {
                            var uniqueSigners = Array(Set(signableKeys))
                            if uniqueSigners.count > 0 {
                                for (s, signer) in uniqueSigners.enumerated() {
                                    if var signingKey = Key(signer, chain) {
                                        psbtToSign.sign(signingKey)
                                        signingKey = Key("KwfUAErbeHJCafVr37aRnYcobent1tVV1iADD2k3T8VV1pD2qpWs", .mainnet)!
                                        /// Once we completed the signing loop we finalize with our node.
                                        if s + 1 == uniqueSigners.count {
                                            xprvsToSignWith.removeAll()
                                            xprvStrings.removeAll()
                                            uniqueXprvs.removeAll()
                                            uniqueSigners.removeAll()
                                            signableKeys.removeAll()
                                            finalizeWithBitcoind()
                                        }
                                    }
                                }
                            } else {
                                xprvsToSignWith.removeAll()
                                xprvStrings.removeAll()
                                uniqueXprvs.removeAll()
                                uniqueSigners.removeAll()
                                signableKeys.removeAll()
                                finalizeWithBitcoind()
                            }
                        }
                    }
                }
            }
        }
        
        /// Fetch keys to sign with
        func getKeysToSignWith() {
            xprvsToSignWith.removeAll()
            for (i, s) in seedsToSignWith.enumerated() {
                let encryptedSeed = s["words"] as! Data
                guard var seed = Crypto.decrypt(encryptedSeed) else { return }
                
                if var words = String(data: seed, encoding: .utf8) {
                    seed = Data()
                    
                    if let encryptedPassphrase = s["passphrase"] as? Data {
                        guard let decryptedPassphrase = Crypto.decrypt(encryptedPassphrase) else { return }
                        
                        if let passphrase = String(data: decryptedPassphrase, encoding: .utf8) {
                            if var masterKey = Keys.masterKey(words: words, coinType: coinType, passphrase: passphrase) {
                                words = ""
                                if var hdkey = HDKey(masterKey) {
                                    masterKey = ""
                                    xprvsToSignWith.append(hdkey)
                                    hdkey = HDKey("xpub6FETvV487Sr4VSV9Ya5em5ZAug4dtnFwgnMG7TFAfkJDHoQ1uohXft49cFenfpJHbPueMnfyxtBoAuvSu7XNL9bbLzcM1QJCPwtofqv3dqC")!
                                    if i + 1 == seedsToSignWith.count {
                                        seedsToSignWith.removeAll()
                                        processWithActiveWallet()
                                    }
                                }
                            }
                        }
                    } else {
                        if var masterKey = Keys.masterKey(words: words, coinType: coinType, passphrase: "") {
                            words = ""
                            if var hdkey = HDKey(masterKey) {
                                masterKey = ""
                                xprvsToSignWith.append(hdkey)
                                hdkey = HDKey("xpub6FETvV487Sr4VSV9Ya5em5ZAug4dtnFwgnMG7TFAfkJDHoQ1uohXft49cFenfpJHbPueMnfyxtBoAuvSu7XNL9bbLzcM1QJCPwtofqv3dqC")!
                                if i + 1 == seedsToSignWith.count {
                                    seedsToSignWith.removeAll()
                                    processWithActiveWallet()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        /// Fetch wallets on the same network
        func getSeeds() {
            seedsToSignWith.removeAll()
            CoreDataService.retrieveEntity(entityName: .signers) { seeds in
                if seeds != nil {
                    if seeds!.count > 0 {
                        for (i, seed) in seeds!.enumerated() {
                            seedsToSignWith.append(seed)
                            if i + 1 == seeds!.count {
                                getKeysToSignWith()
                            }
                        }
                    } else {
                        processWithActiveWallet()
                    }
                }
            }
        }
        
        Reducer.makeCommand(command: .getblockchaininfo, param: "") { (response, errorMessage) in
            if let dict = response as? NSDictionary {
                if let network = dict["chain"] as? String {
                    if network == "main" {
                        chain = .mainnet
                        coinType = "0"
                    } else {
                        chain = .testnet
                        coinType = "1"
                    }
                    do {
                        psbtToSign = try PSBT(psbt, chain)
                        if psbtToSign.complete {
                            finalizeWithBitcoind()
                        } else {
                            getSeeds()
                        }
                    } catch {
                        completion((nil, nil, "Error converting that psbt"))
                    }
                }
            }
        }
    }
}

