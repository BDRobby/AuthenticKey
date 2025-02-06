//
//  SettingsContentView.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import StoreKit
import MessageUI

struct SettingsContentView: View {
    
    @EnvironmentObject var manager: DataManager
    @Binding var displayPaywall: Bool
    
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section {
                        if manager.isPremiumUser == false {
                            VStack {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading) {
                                        Text("Upgrade to premium to begin safeguarding your accounts.")
                                            .font(.custom("GeneralSans-Medium", size: 16))
                                        
                                    }
                                    .foregroundStyle(.white)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("Add your first token for free")
                                    
                                    Spacer()
                                    
                                    Button("Upgrade") {
                                        displayPaywall = true
                                    }
                                    .accessibilityAction {
                                        displayPaywall = true
                                    }
                                    .font(.custom("GeneralSans-Medium", size: 16))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .foregroundColor(.white)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .accessibilityLabel(Text("Upgrade your membership and add unlimited tokens"))
                                    
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.backgroundColor)
                    
                    Section {
                        PasscodeSetup().environmentObject(manager)
                    } header: { Text("Security") }
                        .foregroundStyle(.gray)
                        .font(.custom("GeneralSans-Regular", size: 13))
                        .listRowBackground(Color.backgroundColor)
                    
                    
                    Section {
                        InAppPurchases(displayPaywall: $displayPaywall).environmentObject(manager)
                    } header: { Text("Membership")}
                        .foregroundStyle(.gray)
                        .font(.custom("GeneralSans-Regular", size: 13))
                        .listRowBackground(Color.backgroundColor)
    
                    
                    Section {
                        AppSupport()
                    }
                    .listRowBackground(Color.backgroundColor)
                }
                .padding(.top, 25)
                .background(.black)
                .scrollContentBackground(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }
}



// MARK: Memberships Section
struct InAppPurchases: View {
    @EnvironmentObject var manager: DataManager
    @Binding var displayPaywall: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                displayPaywall = true
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundStyle(.yellow)
                                .accessibilityHidden(true)
                            Text("Upgrade Premium")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                displayPaywall = true
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Restore Purchases")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: App Passcode Section
struct PasscodeSetup: View {
    @EnvironmentObject var manager: DataManager
    
    var body: some View {
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                manager.sheetsMode = .setupPasscodeView
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "circle.grid.3x3")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Set Passcode")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                manager.showAlert = true
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "lock.slash")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Disable Passcode")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        .alert(isPresented: $manager.showAlert) {
            Alert(
                title: Text("Delete Passcode"),
                message: Text("Are you sure you want to delete your passcode and disable protection?"),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text("Delete Passcode")) {
                    // Perform the action to delete the passcode here
                    manager.savedPasscode = ""
                }
            )
        }
    }
}

// MARK: App Support
struct AppSupport: View {
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                openEmailURL()
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Support")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                openIconEmailURL()
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "questionmark.square.dashed")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Request Brand Icon")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                requestReview()
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "star")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Leave a review")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        HStack {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                UIApplication.shared.open(AppConfig.termsAndConditionsURL)
            }, label: {
                VStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                            Text("Terms & Privacy")
                                .font(.custom("GeneralSans-Regular", size: 18))
                                .foregroundStyle(.white)
                        }
                    }
                }
            })
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.custom("GeneralSans-Regular", size: 17))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
    }
}


struct SettingsContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsContentView(displayPaywall: .constant(false)).environmentObject(DataManager())
    }
}

