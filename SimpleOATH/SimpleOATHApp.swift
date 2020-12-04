åimport SwiftUI

@main
struct SimpleOATHApp: App {
    var body: some Scene {
        WindowGroup {
            CredentialListView(credentialsProvider: CredentialsProvider())
        }
    }
}
