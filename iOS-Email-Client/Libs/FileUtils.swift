//
//  FileUtils.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 1/25/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class FileUtils{
    
    static func saveEmailToFile(email: String, metadataKey: String, body: String, headers: String?){
        let fileBodyUrl = FileUtils.getURLForBody(email: email, metadataKey: metadataKey)
        let fileHeaderUrl = FileUtils.getURLForHeader(email: email, metadataKey: metadataKey)
        let directoryUrl = FileUtils.getDirectoryURLForEmail(email: email, metadataKey: metadataKey)
        FileUtils.saveToFile(fileUrl: fileBodyUrl, directoryUrl: directoryUrl, text: body)
        if let myHeaders = headers {
            FileUtils.saveToFile(fileUrl: fileHeaderUrl, directoryUrl: directoryUrl, text: myHeaders)
        }        
    }
    
    static func existBodyFile(email: String, metadataKey: String) -> Bool{
        let fileBodyUrl = FileUtils.getURLForBody(email: email, metadataKey: metadataKey)
        return FileManager.default.fileExists(atPath: fileBodyUrl.path)
    }
    
    static func saveToFile(fileUrl: URL, directoryUrl: URL, text: String){
        guard let data = text.data(using: .utf8) else {
            return
        }
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            try! FileManager.default.createDirectory(atPath: directoryUrl.path, withIntermediateDirectories: true, attributes: nil)
            try! data.write(to: fileUrl, options: .atomic)
            return
        }
    }
    
    static func getBodyFromFile(account: Account, metadataKey: String) -> String{
        let fileUrl = FileUtils.getURLForBody(email: account.email, metadataKey: metadataKey)
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return ""
        }
        let data = try! Data(contentsOf: fileUrl)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    static func deleteDirectoryFromEmail(account: Account, metadataKey: String){
        let fileUrl = FileUtils.getDirectoryURLForEmail(email: account.email, metadataKey: metadataKey)
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return
        }
        try! FileManager.default.removeItem(atPath: fileUrl.path)
    }
    
    static func deleteAccountDirectory(account: Account){
        let fileUrl = FileUtils.getDirectoryForAccount(email: account.email)
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return
        }
        try! FileManager.default.removeItem(atPath: fileUrl.path)
    }
    
    static func getHeaderFromFile(account: Account, metadataKey: String) -> String{
        let fileUrl = FileUtils.getURLForHeader(email: account.email, metadataKey: metadataKey)
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return ""
        }
        let data = try! Data(contentsOf: fileUrl)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    static func getDirectoryForAccount(email: String) -> URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)
        return appGroupURL!.appendingPathComponent(email)
    }
    
    static func getDirectoryURLForEmail(email: String, metadataKey: String) -> URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)
        return appGroupURL!.appendingPathComponent(email)
            .appendingPathComponent("emails")
            .appendingPathComponent(metadataKey)
    }
    
    static func getURLForBody(email: String, metadataKey: String) -> URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)
        return appGroupURL!.appendingPathComponent(email)
            .appendingPathComponent("emails")
            .appendingPathComponent(metadataKey)
            .appendingPathComponent("body.txt")
    }
    
    static func getURLForHeader(email: String, metadataKey: String) -> URL {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)
        return appGroupURL!.appendingPathComponent(email)
            .appendingPathComponent("emails")
            .appendingPathComponent(metadataKey)
            .appendingPathComponent("header.txt")
    }
    
}
