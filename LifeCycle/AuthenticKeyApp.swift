//
//  AuthenticKeyApp.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//


import SwiftUI
import RevenueCat
import RevenueCatUI



@main
struct AuthenticatorApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager: DataManager = DataManager(preview: false)
    
    init() {
        Purchases.configure(withAPIKey: "appl_wWeBQADKCFTUidGOHjsqCIbZRSW")
        Purchases.logLevel = .debug
        
    }
    
    
    
    // MARK: - Main rendering function
    var body: some Scene {
        WindowGroup {
            DashboardContentView(model: .init(uri: "otpauth://totp/Test?secret=123&issuer=Facebook")!)
                .environmentObject(manager)
                .environment(\.managedObjectContext, manager.persistentContainer.viewContext)
                .task {
                    do {
                        let customerInfo = try await Purchases.shared.customerInfo()
                        manager.isPremiumUser = customerInfo.entitlements["Premium"]?.isActive == true
                    } catch {
                        print(error.localizedDescription)
                    }
                }
        }        
    }
}

/// Useful extensions for the app
extension String {
    var formattedToken: String {
        enumerated().map { $0.isMultiple(of: 3) && ($0 != 0) ? "\(" ")\($1)" : String($1) }.joined()
    }
}

/// Present an alert from anywhere in the app
func presentAlert(title: String, message: String, primaryAction: UIAlertAction, secondaryAction: UIAlertAction? = nil, tertiaryAction: UIAlertAction? = nil) {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(primaryAction)
        if let secondary = secondaryAction { alert.addAction(secondary) }
        if let tertiary = tertiaryAction { alert.addAction(tertiary) }
        rootController?.present(alert, animated: true, completion: nil)
    }
}

extension UIAlertAction {
    static var Cancel: UIAlertAction {
        UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    }
    
    static var OK: UIAlertAction {
        UIAlertAction(title: "OK", style: .cancel, handler: nil)
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        // 1
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        // 2
        let activeScene = windowScenes
            .filter { $0.activationState == .foregroundActive }
        // 3
        let firstActiveScene = activeScene.first
        // 4
        let keyWindow = firstActiveScene?.keyWindow
        
        return keyWindow
    }
}

var rootController: UIViewController? {
    return UIApplication.shared.firstKeyWindow?.rootViewController
}


/// Blur background view
//struct BackgroundBlurView: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
//        DispatchQueue.main.async {
//            view.superview?.superview?.backgroundColor = .clear
//        }
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {}
//}

/// Hide keyboard from any view
extension View {
    func hideKeyboard() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

