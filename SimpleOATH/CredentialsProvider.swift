import Foundation

class CredentialsProvider: NSObject, ObservableObject, YKFManagerDelegate {
    
    @Published var credentials = [Credential]()
    
    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    var accessoryConnection: YKFAccessoryConnection?
    
    var nfcConnection: YKFNFCConnection? {
        didSet {
            if let connection = nfcConnection, let callback = connectionCallback {
                callback(connection)
            }
        }
    }
    
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?

    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            self.connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }

    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
        session = nil
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
        self.refresh()
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        credentials.removeAll()
        accessoryConnection = nil
        session = nil
    }
    
    var session: YKFKeyOATHSession?
    
    func session(completion: @escaping (_ session: YKFKeyOATHSession?, _ error: Error?) -> Void) {
        if let session = session {
            completion(session, nil)
            return
        }
        connection { [weak self] connection in
            connection.oathSession { session, error in
                self?.session = session
                completion(session, error)
            }
        }
    }

    func refresh() {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            session.calculateAll { calculatedCredentials, error in
                YubiKitManager.shared.stopNFCConnection()
                guard let calculatedCredentials = calculatedCredentials else { print("Error: \(error!)"); return }
                DispatchQueue.main.async { [weak self] in
                    self?.credentials = calculatedCredentials.map {
                        return Credential(issuer: $0.credential.issuer, account: $0.credential.account, otp: $0.code?.otp)
                    }
                }
            }
        }
    }
    
    func delete(credential: Credential) {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            let oathCredential = YKFOATHCredential()
            oathCredential.account = credential.account
            oathCredential.issuer = credential.issuer
            session.delete(oathCredential) { error in
                guard error == nil else { print("Error: \(error!)"); return }
                if let index = self.credentials.firstIndex(of: credential) {
                    self.credentials.remove(at: index)
                }
                self.refresh()
            }
        }
    }
    
    func add(credential: Credential) {
        session { session, error in
            guard let session = session else { print("Error: \(error!)"); return }
            let secret = NSData.ykf_data(withBase32String: "asecretsecret")!
            let credentialTemplate = YKFOATHCredentialTemplate(totpWith: .SHA512, secret: secret, issuer: credential.issuer, account: credential.account)
            session.putCredential(credentialTemplate, requiresTouch: false) { error in
                guard error == nil else { print("Error: \(error!)"); return }
                self.refresh()
            }
        }
    }
}


extension CredentialsProvider {
    static func previewCredentialsProvider() -> CredentialsProvider {
        let provider = CredentialsProvider()
        provider.credentials = Credential.previewCredentials()
        return provider
    }
}
