//
//  DashboardContentView.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import AlertToast
import RevenueCat
import RevenueCatUI
import StoreKit

struct DashboardContentView: View {
    @EnvironmentObject var manager: DataManager
    @Environment(\.requestReview) var requestReview
    @State private var tokenGenerator: TokenGenerator?
    @State var showAlert = false
    @State var displayPaywall = false
    @State var renameView = false
    let model: TokenModel
    let tokenText = "Token Copied"
    
    /// This is for the passcode timer (i think)
    func purchasePremiumPackage(package: Package) {
        Purchases.shared.purchase(package: package) { (transaction, purchaserInfo, error, userCancelled) in
            if purchaserInfo?.entitlements["Premium"]?.isActive == true {
                // User is premium
                DispatchQueue.main.async {
                    self.manager.isPremiumUser = true
                }
            }
        }
    }
    
    @AppStorage("backgroundTime") var backgroundTime: Double = Date().timeIntervalSinceReferenceDate
    @State private var isActive: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        ZStack {
                            VStack(spacing: 16) {
                                if manager.tokensList.count == 0 {
                                    EmptyListView.ignoresSafeArea(.keyboard)
                                } else {
                                    TokensListView
                                }
                            }
                        }
                        
                    )
                    .toolbar {
                        ToolBarView(displayPaywall: $displayPaywall)
                    }
            }
            .popover(isPresented: $manager.showTokenRenameView) {
                TokenEdit()
                    .presentationDetents([.medium, .large])
                    .presentationDetents([.height(400), .fraction(0.35)])
            }
        }
        .sheet(isPresented: self.$displayPaywall) {
            PaywallView()
                .onPurchaseCompleted { transaction, customerInfo in
                    print("Purchase completed: \(customerInfo.entitlements)")
                    DispatchQueue.main.async {
                        manager.isPremiumUser = true
                    }
                    self.displayPaywall = false
                }
        }
        
        /// Present sheet views
        .sheet(item: $manager.sheetsMode) { type in
            switch type {
            case .settings:
                SettingsContentView(displayPaywall: $displayPaywall).environmentObject(manager)
                    .presentationDetents([.medium, .large])
                    .presentationDetents([.height(600), .fraction(0.70)])
            case .setupPasscodeView:
                PasscodeView(setupMode: true).environmentObject(manager)
            }
        }
        
        /// Present fullscreen views
        .fullScreenCover(item: $manager.fullScreenMode) { type in
            switch type {
            case .passcodeView:
                PasscodeView().environmentObject(manager)
            case .scanner:
                ScannerContentView().environmentObject(manager)
            }
        }
        
        /// Show the passcode view if the passcode was setup
        .onAppear() {
            if manager.savedPasscode.count == 6 && !manager.didEnterCorrectPasscode {
                manager.fullScreenMode = .passcodeView
            }
            self.isActive = true
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.isActive = false
            self.backgroundTime = Date().timeIntervalSinceReferenceDate
            manager.didEnterCorrectPasscode = false
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.isActive = true
            if Date().timeIntervalSince(Date(timeIntervalSinceReferenceDate: self.backgroundTime)) >= 30 &&
                manager.savedPasscode.count == 6 &&
                !manager.didEnterCorrectPasscode {
                manager.fullScreenMode = .passcodeView
            }
        }
    } // end of body view
    
    // MARK: Token List View
    private var TokensListView: some View {
        ZStack {
            List {
                Section {
                    Text("Accounts")
                        .accessibilityLabel(Text("List of all accounts"))
                    ForEach(0..<manager.tokensList.count, id: \.self) { index in
                        TokenListItem(showAlert: $showAlert, model: manager.tokensList[index])
                            .environmentObject(manager)
                    }
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden, edges: .all)
                    
                    .gesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .onEnded { value in })
                }
                .listSectionSeparator(.hidden)
            }
            .background(.black)
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            
            
            .toast(isPresenting: $showAlert) {
                AlertToast(displayMode: .alert, type: .complete(.accentColor), title: (String(format: NSLocalizedString("\(tokenText)", comment: "Token copied to clipboard"), tokenText)))
                
            }
        }
        .offset(y: -25)
        .zIndex(2)
    }
    
    private var EmptyListView: some View {
        VStack {
            Text("Get started")
                .font(.custom("GeneralSans-Medium", size: 27))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(5)
                .accessibilityHidden(true)
            Text("Provide extra security levels for your accounts.")
                .font(.custom("GeneralSans-Regular", size: 18))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(Text("Get Started. Provide extra security levels for your accounts."))
        
        .padding(10)
        .offset(CGSize(width: 0, height: -30))
    }
}

// MARK: Header Toolbar View
struct ToolBarView: ToolbarContent {
    @EnvironmentObject var manager: DataManager
    @Binding var displayPaywall: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                
                print("Before if: \(manager.isPremiumUser)")
                if !manager.isPremiumUser, manager.tokensList.count >= AppConfig.freeAccounts {
                    print("Inside if: \(manager.isPremiumUser)")
                    displayPaywall = true
                } else {
                    print("Inside else: \(manager.isPremiumUser)")
                    manager.fullScreenMode = .scanner
                }
                
            }) {
                ZStack {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.accent, .quaternary)
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .labelsHidden()
                }
                .accessibilityLabel(Text("Press the button to scan QR code"))
            }
        }
        
        
        ToolbarItem(placement: .principal) {
            Text("AuthenticKey")
                .accessibilityHidden(true)
                
                .foregroundStyle(.white)
                .font(.custom("GeneralSans-Medium", size: 16))
        }
        
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                manager.sheetsMode = .settings
            }) {
                HStack {
                    Image(systemName: "gearshape.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.accent, .quaternary)
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .labelsHidden()
                }
                .accessibilityLabel(Text("Press the button to open settings menu"))
            }
        }
    }
}
// MARK: Rename Modal
struct TokenEdit: View {
        @EnvironmentObject var manager: DataManager
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                    .opacity(manager.showTokenRenameView ? 0.7 : 0.0)
                    .onTapGesture {
                        hideKeyboard()
                    }
                VStack {
                    VStack {
                        Text("Rename Account")
                            .font(.custom("GeneralSans-Medium", size: 20))
                        TextField("Service name", text: $manager.issuerRenameValue)
                          //  .focused($manager.issuerRenameValue, equals: true)
                            .padding()
                            .font(.custom("GeneralSans-Regular", size: 16))
                            .background(Color.lightBackgroundColor.cornerRadius(12).opacity(1))
                            .padding(.horizontal)
                            .colorScheme(.light)
                        
                        TextField("Account name", text: $manager.tokenRenameValue)
                            .padding()
                            .font(.custom("GeneralSans-Regular", size: 16))
                            .background(Color.lightBackgroundColor.cornerRadius(12).opacity(1))
                            .padding(.horizontal)
                            .colorScheme(.light)
                        Button {
                            hideKeyboard()
                            manager.renameToken()
                            manager.renameIssuer()
                            UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                        } label: {
                            ZStack {
                                Color.accentColor.cornerRadius(12)
                                Text("Save")
                                    .foregroundColor(.white)
                                    .font(.custom("GeneralSans-Medium", size: 18))
                            }
                        }
                        .frame(height: 50)
                        .padding(.horizontal)
                        .accessibilityLabel(Text("Press the button to save changes"))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical)
                    .background(Color.backgroundColor.cornerRadius(18))
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .offset(y: manager.showTokenRenameView ? 0 : UIScreen.main.bounds.height/0)
            }
        }
    }



struct DashboardContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        DashboardContentView(model: .init(uri: "otpauth://totp/Test?secret=123&issuer=Facebook")!).environmentObject(DataManager())
    }
}
