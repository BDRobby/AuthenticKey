//
//  TokenListItem.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import AlertToast

struct TokenListItem: View {
    
    @EnvironmentObject var manager: DataManager
    @State private var tokenGenerator: TokenGenerator?
    @State private var tokenCode: String = "000 000"
    @State private var counter: Int = 30
    @State private var sharedCounter = 30
    @Binding var showAlert: Bool
    let sharedTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let model: TokenModel
    
    
    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .frame(width: 45, height: 45)
                    .overlay(BrandImageView)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(tokenCode)
                        .font(.custom("GeneralSans-Medium", size: 26))
                    HStack {
                        Text("\(model.issuer ?? "") · \(model.accountName ?? "")")
                            .font(.custom("GeneralSans-Medium", size: 15))
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(model.issuer ?? "") token code is \(tokenCode)" ))
                
                Spacer()
                
                ZStack {
                    CounterView(counter: sharedCounter)
                }
                .accessibilityLabel(Text("Time until \(model.issuer ?? "") token code expires: \(sharedCounter) seconds"))
                
            }
            
            
            Divider()
                .frame(height: 1.5)
                .overlay(.gray)
                .opacity(0.15)
        }
        
        /// This allows the user to Rename or Delete Token
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = tokenGenerator?.generateMFACode().code
                UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                showAlert = true
            }) {
                Label("Copy Token", systemImage: "square.on.square")
            }
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                manager.renameToken(model)
            }) {
                Label("Edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive, action: {
                UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                manager.deleteToken(model)
            }) {
                Label("Delete", systemImage: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        
        /// This allows user to delete view
       .swipeActions {
           Button(action: {
               UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
               manager.deleteToken(model)
           }) {
               Label("Delete", systemImage: "trash")
      
           }
           .tint(.red)
           .accessibilityAction {
               manager.deleteToken(model)
           }
           .accessibilityLabel(Text("Press the button to delete token"))
      
           Button(action: {
               UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
               manager.renameToken(model)
           }) {
               Label("Edit", systemImage: "square.and.pencil")
      
           }
           .tint(.gray.opacity(2.0))
           .accessibilityAction {
               manager.deleteToken(model)
           }
           .accessibilityLabel(Text("Press the button to edit token"))
       }
        
        
        /// This copies the Token Code
        .onTapGesture {
            UIPasteboard.general.string = tokenGenerator?.generateMFACode().code
            UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
            showAlert = true
        }
        
        /// This is for the counter to animate (I think...)
        .onAppear {
            if tokenGenerator == nil {
                tokenGenerator = TokenGenerator(token: model)
                updateTokenCodeAndCounter()
            }
        }
        .onReceive(sharedTimer) { _ in
            sharedCounter = counter
            updateTokenCodeAndCounter()
            }
    }
    func updateTokenCodeAndCounter() {
            tokenCode = tokenGenerator?.generateMFACode().code?.formattedToken ?? "000 000"
            counter = tokenGenerator?.generateMFACode().counter ?? 30
            
        }
    
    
/// Counter View
    private func CounterView(counter: Int) -> some View {
            let lineWidth: Double = 2
            let color: Color = counter <= 10 ? Color.red : Color.blue
            let percentage: Double = ((Double(counter) * 100.0) / 30.0) / 100.0
            return ZStack {
                Circle().stroke(lineWidth: lineWidth).opacity(0.15)
                Circle().trim(from: 0, to: percentage)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: NSLocalizedString("\(counter)", comment: "Time until token code expires"), counter))
                    .font(.system(size: 18))
                    .foregroundColor(counter <= 10 ? .red : .blue)
            }
            .foregroundColor(.blue)
            .frame(width: 35, height: 35)
        }
    
    
/// Brand Image View (Replace w/ BrandFetch API)
private var BrandImageView: some View {
    ZStack {
        if let brand = model.issuer ?? model.accountName, let image = UIImage(named: brand) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(label: Text("Logo for \(brand)"))
        } else {
            Color.backgroundColor
            Text(model.issuer?.prefix(1) ?? "")
                .accessibilityLabel("Prefix for \(String(model.issuer?.prefix(1) ?? ""))")
                .foregroundColor(.white)
                .font(.custom("GeneralSans-SemiBold", size: 30))
        }
    }
    .cornerRadius(8)
    .background(Color.black)
  }
} // Goes to main struct



struct TokenListItem_Previews: PreviewProvider {
    static var previews: some View {
        TokenListItem(showAlert: .constant(false), model: .init(uri: "otpauth://totp/Test?secret=123&issuer=Facebook")!)
            .environmentObject(DataManager())
    }
}
