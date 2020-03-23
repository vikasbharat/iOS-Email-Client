//
//  Alias.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Alias: Object {
    @objc dynamic var name = ""
    @objc dynamic var rowId = 0
    @objc dynamic var domainName : String? = nil
    @objc dynamic var active = true
    @objc dynamic var account : Account!
    
    var email: String {
        let domain = domainName ?? Env.plainDomain
        return "\(name)@\(domain)"
    }
    
    class func fromDictionary(data: [String: Any], account: Account) -> (String, [Alias]) {
        let aliases = data["aliases"] as! [[String: Any]]
        let domain = data["domain"] as! [String: Any]
        let domainName = domain["name"] as! String
        let aliasesArray: [Alias] = aliases.map({Alias.aliasFromDictionary(aliasData: $0, domainName: domainName, account: account)})
        return (domainName, aliasesArray)
    }
    
    class func aliasFromDictionary(aliasData: [String : Any], domainName: String, account: Account) -> Alias {
        let newAlias = Alias()
        newAlias.name = aliasData["name"] as! String
        newAlias.account = account
        newAlias.active = aliasData["status"] as! Bool
        newAlias.rowId = aliasData["addressId"] as! Int
        newAlias.domainName = domainName == Env.plainDomain ? nil : domainName
        return newAlias
    }
    
    override static func primaryKey() -> String? {
        return "rowId"
    }
}
