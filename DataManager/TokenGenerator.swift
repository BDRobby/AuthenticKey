//
//  TokenGenerator.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import CryptoKit
import Foundation

/// Generator engine for a authenticator/MFA code based on a TokenModel
public class TokenGenerator {
    
    /// Private properties
    private var counter: UInt64 = UInt64(Date().timeIntervalSince1970 / TimeInterval(30)).bigEndian
    private var generatedCodeTime: Date?
    private var generatedCodeValue: String?
    private var expirationCounter: Int = Int.random(in: 10...30)
    private var token: TokenModel
    
    /// Init the generator with a token model
    public init(token tokenModel: TokenModel) {
        token = tokenModel
    }
    
    /// Generates the authenticator/MFA code for a given token
    /// - Parameter token: token model
    /// - Returns: returns the authenticator/MFA code and the time counter
    public func generateMFACode() -> (code: String?, counter: Int?) {
        func generateHash() -> UInt32 {
            guard let secret = token.base32Data.flatMap({ $0.withUnsafeBufferPointer(Data.init(buffer:)) }) else { return 0 }
            let counterData = withUnsafeBytes(of: &counter) { Array($0) }
            let hash = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: secret))
         
            var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
                let offset = ptr[hash.byteCount - 1] & 0x0f
                let truncatedHashPtr = ptr.baseAddress! + Int(offset)
                return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
            }
         
            truncatedHash = UInt32(bigEndian: truncatedHash)
            truncatedHash = truncatedHash & 0x7FFF_FFFF
            truncatedHash = truncatedHash % UInt32(pow(10, Float(token.digits)))
            return truncatedHash
        }
        
        if generatedCodeTime == nil || generatedCodeValue == nil {
            generatedCodeTime = Date()
            generatedCodeValue = String(format: "%0*u", token.digits, generateHash())
        }
        
        let timeDifference = Calendar.current.dateComponents([.second], from: generatedCodeTime!, to: Date()).second ?? 0
        let expiration = expirationCounter-timeDifference
        
        if expiration <= 0 {
            generatedCodeTime = nil
            expirationCounter = 30
            counter = UInt64(Date().timeIntervalSince1970 / TimeInterval(30)).bigEndian
        }
        
        return (generatedCodeValue, max(expiration, 0))
    }
}
