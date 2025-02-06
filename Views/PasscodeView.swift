//
//  PasscodeView.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI

/// Main view to setup a passcode
struct PasscodeView: View {
    
    @EnvironmentObject var manager: DataManager
    @Environment(\.presentationMode) var presentation
    @State private var showWrongPasswordAnimation: Bool = false
    @State private var passcodeArray: [String] = [String]()
    @State private var setupPasscode: String = ""
    @State var setupMode: Bool = false
    
    // MARK: - Main rendering function
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PasscodeView
        }
    }
    
    /// Passcode view
    private var PasscodeView: some View {
        var passcodeTitle = "\(setupPasscode.count == 6 ? "Confirm" : "Setup") Passcode"
        if !setupMode { passcodeTitle = "Enter Passcode" }
        return VStack(spacing: 30) {
            Text(passcodeTitle).font(.custom("GeneralSans-Medium", size: 22))
            HStack(spacing: 15) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        if passcodeArray.count > index {
                            Circle()
                        } else {
                            Circle().strokeBorder(lineWidth: 2)
                                
                        }
                    }.frame(width: 12, height: 12, alignment: .center)
                }
            }.offset(x: showWrongPasswordAnimation ? -20 : 0)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 20, content: {
                ForEach(0..<9, id: \.self, content: { index in
                    KeypadButton(index: index + 1)
                })
            }).padding([.leading, .trailing, .top], 40)
            
            KeypadButton(index: 0)
        }.foregroundColor(.white)
    }
    
    /// Create keypad button
    private func KeypadButton(index: Int) -> some View {
        let size = UIScreen.main.bounds.width/3 - 50
        return Button(action: {
            UIImpactFeedbackGenerator().impactOccurred()
            if setupMode == true {
                if passcodeArray.count != 6 {
                    passcodeArray.append("\(index)")
                }
                if passcodeArray.count == 6 {
                    verifySetupPasscode()
                }
            } else {
                if passcodeArray.count != 6 {
                    passcodeArray.append("\(index)")
                }
                if passcodeArray.count == 6 {
                    if manager.savedPasscode == passcodeArray.joined() {
                        manager.didEnterCorrectPasscode = true
                        presentation.wrappedValue.dismiss()
                    } else {
                        resetPasscodeEntry()
                    }
                }
            }
        }, label: {
            ZStack {
                Circle()
                    .foregroundColor(Color(red: 0.635, green: 0.635, blue: 0.64))
                    .opacity(0.3)
                Text("\(index)")
                    .font(.custom("GeneralSans-Regular", size: 40))
                    .foregroundColor(.white).opacity(0.8)
            }
        })
        .frame(width: size, height: size)
        .disabled(passcodeArray.count == 6)
    }
    
/// Verify setup passcode
    private func verifySetupPasscode() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if setupPasscode == passcodeArray.joined() {
                manager.savedPasscode = setupPasscode
                presentation.wrappedValue.dismiss()
            } else {
                if setupPasscode.count == 0 {
                    setupPasscode = passcodeArray.joined()
                    passcodeArray.removeAll()
                } else {
                    setupPasscode = ""
                    resetPasscodeEntry()
                }
            }
        }
    }
    
    private func resetPasscodeEntry() {
        passcodeArray.removeAll()
        let duration = 0.1
        withAnimation(Animation.easeIn(duration: duration)) {
            showWrongPasswordAnimation = true
        }
        withAnimation(Animation.easeIn(duration: duration).delay(duration)) {
            showWrongPasswordAnimation = false
        }
    }
}

// MARK: - Preview UI
struct PasscodeView_Previews: PreviewProvider {
    static var previews: some View {
        PasscodeView().environmentObject(DataManager(preview: true))
    }
}
