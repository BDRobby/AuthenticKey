//
//  AppConfig.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import Foundation
import RevenueCat

let email = "bdrobby@proton.me"
let subject = "AuthenticKey Support"
            
let coded = "mailto:\(email)?subject=\(subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    
func openEmailURL() {
    if let emailURL:NSURL = NSURL(string: coded!) {
        if UIApplication.shared.canOpenURL(emailURL as URL){
            UIApplication.shared.open(emailURL as URL)
        }
    }
}

let brandSubject = "Request Brand Icon"
let body = "I would like to request icons for:"

let codedIcon = "mailto:\(email)?subject=\(brandSubject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

func openIconEmailURL() {
    if let emailURL:NSURL = NSURL(string: codedIcon!) {
        if UIApplication.shared.canOpenURL(emailURL as URL){
            UIApplication.shared.open(emailURL as URL)
        }
    }
}

/// Generic configurations for the app
class AppConfig {
    
    
    // MARK: - Settings flow items
    static let emailSupport: URL = URL(string: "mailto: \(email)")!
    static let feedbackSupport: URL = URL(string: "mailto: \(email)")!
    static let privacyURL: URL = URL(string: "https://www.google.com/")!
    static let termsAndConditionsURL: URL = URL(string: "https://authentic-key.notion.site/AuthenticKey-Support-dcae427f53734bf98428c53a672a0b55")!
    static let yourAppURL: URL = URL(string: "https://apps.apple.com/app/idXXXXXXXXX")!
    
    // MARK: - In App Purchases
    static let isPremiumUser: String = "Premium"
    static let freeAccounts: Int = 0
}

/// Main app colors
extension Color {
    static let backgroundColor: Color = Color("BackgroundColor")
    static let lightBackgroundColor: Color = Color("SecondaryBackgroundColor")
    static let iconColor: Color = Color("IconButtonColors")
    static let textColor: Color = Color("TextColors")
}

/// Full Screen flow
enum FullScreenMode: Int, Identifiable {
    case scanner, passcodeView
    var id: Int { hashValue }
}

/// Sheet Screen flow
enum SheetsMode: Int, Identifiable {
    case settings, setupPasscodeView
    var id: Int { hashValue }
}

/// Popover Screen flow
enum PopoverMode: Int, Identifiable {
    case renamePop
    var id: Int { hashValue }
}

