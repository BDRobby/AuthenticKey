//
//  DataManager.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import CoreData
import Foundation
import RevenueCat
import CloudKit

/// Main data manager for the app
class DataManager: NSObject, ObservableObject {
    
    /// Dynamic properties that the UI will react to
    @Published var fullScreenMode: FullScreenMode?
    @Published var sheetsMode: SheetsMode?
    @Published var popoverMode: PopoverMode?
    @Published var tokensList: [TokenModel] = [TokenModel]()
    @Published var didEnterCorrectPasscode: Bool = false
    @Published var tokenRenameValue: String = ""
    @Published var issuerRenameValue: String = ""
    @Published var showTokenRenameView: Bool = false
    @Published var isPremiumUser: Bool = false
    @Published var isReady = false
    @Published var showAlert = false
    
    
    
    
    
    /// Dynamic properties that the UI will react to AND store values in UserDefaults
    @AppStorage("savedPasscode") var savedPasscode: String = ""
    // @AppStorage("isPremiumUser") var isPremiumUser: Bool = false
    {
        didSet { }
    }
    
    
    /// Private properties
    private var selectedRenameToken: TokenModel?
    private var selectedRenameIssuer: TokenModel?
    
    /// Core Data container with the database model
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container: NSPersistentCloudKitContainer = NSPersistentCloudKitContainer(name: "Database")
        
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            DispatchQueue.main.async {
                self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                self.fetchSavedTokens()
            }
        }
        
        let options = NSPersistentCloudKitContainerSchemaInitializationOptions()
        try? container.initializeCloudKitSchema(options: options)
        
        return container
    }()
    
    
    /// Default init method. Load the Core Data container
    init(preview: Bool = true) {
        super.init()
        if preview {
            persistentContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            tokensList.append(TokenModel(uri: "otpauth://totp/Apps4World?secret=ABCD&digits=6&issuer=Facebook")!)
            tokensList.append(TokenModel(uri: "otpauth://totp/Demo?secret=BNMZYUAC&digits=6&issuer=Twitter")!)
            tokensList.append(TokenModel(uri: "otpauth://totp/apps4world@gmail.com?secret=XZZYC&digits=6&issuer=Google")!)
            tokensList.append(TokenModel(uri: "otpauth://totp/Mr.Shopper?secret=AB34CZYC&digits=6&issuer=Amazon")!)
            tokensList.append(TokenModel(uri: "otpauth://totp/Apps4World?secret=UZBNMZYC&digits=6&issuer=Instagram")!)
        }
    }
    
    /// Fetch all saved tokens
    private func fetchSavedTokens() {
        let fetchRequest: NSFetchRequest<TokenEntity> = TokenEntity.fetchRequest()
        if let results = try? persistentContainer.viewContext.fetch(fetchRequest) {
            var tokens = [TokenModel]()
            results.forEach { entity in
                if let token = TokenModel(uri: entity.uri ?? "", id: entity.id, issuer: entity.issuer, name: entity.name) {
                    tokens.append(token)
                }
            }
            DispatchQueue.main.async {
                self.tokensList = tokens
            }
        }
    }
    
    func initialize() {
        self.isReady = true
    }
    
    /// Add token
    func addToken(withURI uri: String) {
        guard let token = TokenModel(uri: uri) else { return }
        let tokenEntity = TokenEntity(context: persistentContainer.viewContext)
        tokenEntity.id = token.id
        tokenEntity.uri = token.uri
        
        persistentContainer.viewContext.perform {
            do {
                try self.persistentContainer.viewContext.save()
                self.fetchSavedTokens()
            } catch { }
        }
    }
    
    /// Delete token
    func deleteToken(_ model: TokenModel) {
        // Function to handle the deletion
        func deleteMatchingToken() {
            let fetchRequest: NSFetchRequest<TokenEntity> = TokenEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", model.id)

            if let foundMatch: TokenEntity = try? self.persistentContainer.viewContext.fetch(fetchRequest).first {
                self.persistentContainer.viewContext.delete(foundMatch)
                self.persistentContainer.viewContext.perform {
                    try? self.persistentContainer.viewContext.save()
                    self.fetchSavedTokens()
                }
            }
        }

        // Present alert and perform deletion when the secondary action is tapped
        presentAlert(title: "Delete Account", message: "Are you sure you want to delete this account? You will not be able to recover this and you may lose access to this account without a token", primaryAction: .Cancel, secondaryAction: UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            DispatchQueue.main.async {
                deleteMatchingToken()
            }
        }))
    }
    
    /// Rename account name token
    func renameToken(_ model: TokenModel) {
        if showTokenRenameView {
            // Update the token name in the overlay view
            tokenRenameValue = "New Token Name"
            issuerRenameValue = "New Issuer Name"
        } else {
            selectedRenameToken = model
            tokenRenameValue = model.accountName ?? ""
            selectedRenameIssuer = model
            issuerRenameValue = model.issuer ?? ""
            withAnimation { showTokenRenameView = true }
        }
    }
    
    /// Rename account name token action
    func renameToken() {
        guard let model = selectedRenameToken else { return }
        if tokenRenameValue != model.accountName && !tokenRenameValue.trimmingCharacters(in: .whitespaces).isEmpty {
            let fetchRequest: NSFetchRequest<TokenEntity> = TokenEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", model.id)
            if let foundMatch = try? self.persistentContainer.viewContext.fetch(fetchRequest).first {
                foundMatch.name = tokenRenameValue
                try? self.persistentContainer.viewContext.save()
                self.fetchSavedTokens()
            }
        }
        withAnimation { showTokenRenameView = false }
    }
    func renameIssuer() {
        print("Renaming issuer to: \(issuerRenameValue)")
        guard let model = selectedRenameIssuer else { return }
        if issuerRenameValue != model.issuer && !issuerRenameValue.trimmingCharacters(in: .whitespaces).isEmpty {
            let fetchRequest: NSFetchRequest<TokenEntity> = TokenEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", model.id)
            if let foundMatch = try? self.persistentContainer.viewContext.fetch(fetchRequest).first {
                foundMatch.issuer = issuerRenameValue
                do {
                    try self.persistentContainer.viewContext.save()
                    self.fetchSavedTokens()
                } catch {
                    print("Failed to save TokenEntity: \(error)")
                }
            }
        }
    }
}

