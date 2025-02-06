//
//  TokenModel.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import Foundation

/// Main model for the token
public struct TokenModel {
    
    public let id: String
    public let uri: String
    public var secret: String
    public let accountName: String?
    public let issuer: String?
    public let digits: Int
    
    /// Init the token model with a given URI from scanned QR code
    /// - Parameter tokenURI: URI from QR code
    public init?(uri tokenURI: String, id identifier: String? = nil, issuer: String? = nil, name: String? = nil) {
        guard let url: URL = URL(string: tokenURI),
              let components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "otpauth", components.host == "totp", let queryItems: [URLQueryItem] = components.queryItems,
              let secretValue = queryItems.filter({ $0.name.lowercased() == "secret" }).first?.value
        else { return nil }
        
        id = identifier ?? "\(secretValue)\(Date().timeIntervalSince1970.description)"
        uri = tokenURI
        secret = secretValue
        accountName = name ?? components.path.replacingOccurrences(of: "/", with: "")
        self.issuer = issuer ?? queryItems.filter({ $0.name.lowercased() == "issuer" }).first?.value
        
        /// Assign the digits count for the MFA token, otherwise set it by default to 6
        if let digitsValue = queryItems.filter({ $0.name.lowercased() == "digits" }).first?.value {
            digits = Int(digitsValue) ?? 6
        } else {
            digits = 6
        }
        // Temporary variable to store the decoded secret
            var decodedSecret: String?
            
            // Decode Base64 encoded secret
            if let base64Secret = queryItems.first(where: { $0.name.lowercased() == "base64secret" })?.value {
                if let decodedData = decodeBase64Data(from: base64Secret) {
                    decodedSecret = String(data: decodedData, encoding: .utf8)
                }
            }
            
            // Decode Base16 (hexadecimal) encoded secret
            if let base16Secret = queryItems.first(where: { $0.name.lowercased() == "base16secret" })?.value {
                if let decodedData = decodeBase16Data(from: base16Secret) {
                    decodedSecret = String(data: decodedData, encoding: .utf8)
                }
            }
            
            // Assign the decoded secret to self.secret
            if let decodedSecret = decodedSecret {
                self.secret = decodedSecret
            }
    }
}

// MARK: - Get the Base32 Data from Token secret
extension TokenModel {
    
    /// Convert the Token secret to data
    var base32Data: [UInt8]? {
        let length = secret.unicodeScalars.count
        if length == 0 { return nil }
        
        func getSuffixPadding(_ string: String) -> Int {
            let suffix: [String] = ["======", "====", "===", "="]
            return suffix.first(where: { string.hasSuffix($0) })?.count ?? 0
        }
        
        let leastPaddingLength = getSuffixPadding(secret)
        if let index = secret.unicodeScalars.firstIndex(where: { $0.value > 0xff || decodeTable[Int($0.value)] > 31 }) {
            let position = secret.unicodeScalars.distance(from: secret.unicodeScalars.startIndex, to: index)
            if position != length - leastPaddingLength {
                return nil
            }
        }
        
        var remainEncodedLength = length - leastPaddingLength
        var additionalBytes = 0
        switch remainEncodedLength % 8 {
        case 0: break
        case 2: additionalBytes = 1
        case 4: additionalBytes = 2
        case 5: additionalBytes = 3
        case 7: additionalBytes = 4
        default: return nil
        }

        let dataSize = remainEncodedLength / 8 * 5 + additionalBytes
        return secret.utf8CString.withUnsafeBufferPointer { (data: UnsafeBufferPointer<CChar>) -> [UInt8] in
            var encoded = data.baseAddress!
            var result = Array<UInt8>(repeating: 0, count: dataSize)
            var decodedOffset = 0
            var value0, value1, value2, value3, value4, value5, value6, value7: UInt8
            (value0, value1, value2, value3, value4, value5, value6, value7) = (0,0,0,0,0,0,0,0)
            
            while remainEncodedLength >= 8 {
                value0 = decodeTable[Int(encoded[0])]
                value1 = decodeTable[Int(encoded[1])]
                value2 = decodeTable[Int(encoded[2])]
                value3 = decodeTable[Int(encoded[3])]
                value4 = decodeTable[Int(encoded[4])]
                value5 = decodeTable[Int(encoded[5])]
                value6 = decodeTable[Int(encoded[6])]
                value7 = decodeTable[Int(encoded[7])]
                
                result[decodedOffset]     = value0 << 3 | value1 >> 2
                result[decodedOffset + 1] = value1 << 6 | value2 << 1 | value3 >> 4
                result[decodedOffset + 2] = value3 << 4 | value4 >> 1
                result[decodedOffset + 3] = value4 << 7 | value5 << 2 | value6 >> 3
                result[decodedOffset + 4] = value6 << 5 | value7
                
                remainEncodedLength -= 8
                decodedOffset += 5
                encoded = encoded.advanced(by: 8)
            }
            
            (value0, value1, value2, value3, value4, value5, value6, value7) = (0,0,0,0,0,0,0,0)

            switch remainEncodedLength {
            case 7:
                value6 = decodeTable[Int(encoded[6])]
                value5 = decodeTable[Int(encoded[5])]
                fallthrough
            case 5:
                value4 = decodeTable[Int(encoded[4])]
                fallthrough
            case 4:
                value3 = decodeTable[Int(encoded[3])]
                value2 = decodeTable[Int(encoded[2])]
                fallthrough
            case 2:
                value1 = decodeTable[Int(encoded[1])]
                value0 = decodeTable[Int(encoded[0])]
            default: break
            }
            
            switch remainEncodedLength {
            case 7:
                result[decodedOffset + 3] = value4 << 7 | value5 << 2 | value6 >> 3
                fallthrough
            case 5:
                result[decodedOffset + 2] = value3 << 4 | value4 >> 1
                fallthrough
            case 4:
                result[decodedOffset + 1] = value1 << 6 | value2 << 1 | value3 >> 4
                fallthrough
            case 2:
                result[decodedOffset]     = value0 << 3 | value1 >> 2
            default: break
            }
            
            return result
        }
    }
    
    /// Decode table
    var decodeTable: [UInt8] {
        [
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,26,27, 28,29,30,31, 255,255,255,255, 255,255,255,255,
            255, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
            15,16,17,18, 19,20,21,22, 23,24,25,255, 255,255,255,255,
            255, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
            15,16,17,18, 19,20,21,22, 23,24,25,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
            255,255,255,255, 255,255,255,255, 255,255,255,255, 255,255,255,255,
        ]
    }
}

extension TokenModel {
    func decodeBase64Data(from base64String: String) -> Data? {
        return Data(base64Encoded: base64String)
    }
}

// Add a method to decode Base16 (hexadecimal) encoded data
extension TokenModel {
    func decodeBase16Data(from base16String: String) -> Data? {
        var hexString = base16String
        if hexString.count % 2 != 0 {
            hexString = "0" + hexString
        }
        var data = Data(capacity: hexString.count / 2)
        var index = hexString.startIndex
        for _ in 0..<hexString.count / 2 {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        return data
    }
}
