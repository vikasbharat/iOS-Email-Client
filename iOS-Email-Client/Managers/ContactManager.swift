//
//  ContactManager.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/19/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import Contacts

class ContactManager {
    static let store = CNContactStore()
    
    class func getContacts(completion: @escaping ((Bool, [Contact]?) -> Void)){
        self.store.requestAccess(for: .contacts) { (granted, error) in
            guard granted else {
                completion(false, nil)
                return
            }
            
            let keysToFetch:[CNKeyDescriptor] = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactEmailAddressesKey as CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch )
            var cnContacts = [CNContact]()
            
            do {
                try self.store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    cnContacts.append(contact)
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
                
            }
            
            var contacts = [Contact]()
            
            for contact in cnContacts {
                let emails = contact.emailAddresses.map{ return String($0.value) }
                
                guard !emails.isEmpty, let fullname = CNContactFormatter.string(from: contact, style: .fullName) else {
                    continue
                }
                
                for email in emails {
                    let contact = Contact()
                    contact.displayName = fullname
                    contact.email = email.replacingOccurrences(of: " ", with: "")
                    contacts.append(contact)
                }
            }
            
            completion(true, contacts)
        }
    }
}