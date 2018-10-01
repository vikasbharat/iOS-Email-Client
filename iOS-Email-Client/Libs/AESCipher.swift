//
//  AESCipher.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AESCipher {
    class func encrypt(data: Data, keyData: Data, ivData: Data, operation: Int) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let options = CCOptions(kCCOptionPKCS7Padding)
        
        var numBytesEncrypted : size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes({ dataBytes in
                ivData.withUnsafeBytes({ ivBytes in
                    keyData.withUnsafeBytes({ keyBytes in
                        CCCrypt(CCOperation(operation), CCAlgorithm(kCCAlgorithmAES128), options, keyBytes, keyLength, ivBytes, dataBytes, data.count, cryptBytes, cryptLength, &numBytesEncrypted)
                    })
                })
            })
        }
        
        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
            return nil
        }
        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        return cryptData
    }
    
    class func streamEncrypt(path: String, outputName: String, keyData: Data, ivData: Data, operation: Int) -> String? {
        let outputURL = CriptextFileManager.getURLForFile(name: outputName)
        try? FileManager.default.removeItem(at: outputURL)
        FileManager.default.createFile(atPath: outputURL.path, contents: nil, attributes: nil)
        
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: path)
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let options = CCOptions(kCCOptionPKCS7Padding)
        
        var cryptor: CCCryptorRef? = nil
        let cryptorPointer = UnsafeMutablePointer<CCCryptorRef?>(&cryptor)
        
        let cryptorStatus = keyData.withUnsafeBytes({ keyBytes in
            ivData.withUnsafeBytes({ ivBytes in
                CCCryptorCreate(CCOperation(operation), CCAlgorithm(kCCAlgorithmAES128), options, keyBytes, keyLength, ivBytes, cryptorPointer)
            })
        })
        
        guard UInt32(cryptorStatus) == UInt32(kCCSuccess),
            let cryptorRef = cryptor else {
            return nil
        }
        
        let updateSuccess = doUpdate(cryptor: cryptorRef, inputPath: path, outputURL: outputURL)
        let finalSuccess = doFinal(cryptor: cryptorRef, fileSize: fileSize, outputURL: outputURL)
        
        guard updateSuccess && finalSuccess else {
            return nil
        }

        return outputURL.path
    }
    
    private class func doUpdate(cryptor: CCCryptorRef, inputPath: String, outputURL: URL) -> Bool {
        guard let inputStream = InputStream.init(fileAtPath: inputPath),
            let outputStream = OutputStream.init(url: outputURL, append: false) else {
                return false
        }
        
        let bufferSize = 512
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var dataOutMoved:Int = 0
        
        inputStream.open()
        outputStream.open()
        
        while inputStream.hasBytesAvailable {
            let input = inputStream.read(buffer, maxLength: bufferSize)
            let outBufferSize = CCCryptorGetOutputLength(cryptor, input, false)
            let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufferSize)
            CCCryptorUpdate(cryptor, buffer, input, outBuffer, outBufferSize, &dataOutMoved)
            outputStream.write(outBuffer, maxLength: dataOutMoved)
        }
        
        outputStream.close()
        inputStream.close()
        
        return true
    }
    
    private class func doFinal(cryptor: CCCryptorRef, fileSize: Int, outputURL: URL) -> Bool {
        let bufferSize = 512
        var dataOutMoved:Int = 0
        
        guard let outputStream2 = OutputStream.init(url: outputURL, append: true) else {
            return false
        }
        
        outputStream2.open()
        
        let outBufferSize = CCCryptorGetOutputLength(cryptor, fileSize, true)
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufferSize)
        CCCryptorFinal(cryptor, outBuffer, bufferSize, &dataOutMoved)
        outputStream2.write(outBuffer, maxLength: dataOutMoved)
        print(Data.init(bytes: outBuffer, count: dataOutMoved).base64EncodedString())
        
        outputStream2.close()
        
        return true
    }
    
    class func generateKey(password: String, saltData: Data) -> Data? {
        let keySize = 16
        let passwordData = password.data(using: .utf8)!
        var key = Data(count: keySize)
        var localKey = key
        let status = passwordData.withUnsafeBytes({ (passwordBytes: UnsafePointer<Int8>) in
            saltData.withUnsafeBytes({ (saltBytes: UnsafePointer<UInt8>) in
                localKey.withUnsafeMutableBytes({ (keyBytes: UnsafeMutablePointer<UInt8>) in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes, passwordData.count, saltBytes, saltData.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 10000, keyBytes, key.count)
                })
            })
        })
        
        guard UInt32(status) == UInt32(kCCSuccess) else {
            return nil
        }
        return key
    }
    
    class func generateRandomBytes(length bytesCount: Int = 16) -> Data {
        var randomBytes = Array<UInt8>(repeating: 0, count: bytesCount)
        SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        return Data(bytes: randomBytes)
    }
    
    class func sha256(_ data: Data) -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}