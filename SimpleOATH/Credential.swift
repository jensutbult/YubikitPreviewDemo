struct Credential: Identifiable, Equatable {
    let id = UUID()
    let issuer: String?
    let account: String
    let otp: String?
}

extension Credential {
    static func previewCredentials() -> [Credential] {
        [Credential(issuer: "Behemoth", account: "camina.drummer@gmail.com", otp: "314159"),
         Credential(issuer: "Tachi", account: "amos.burton@gmail.com", otp: "265358"),
         Credential(issuer: "Razorback", account: "clarissa.mao@gmail.com", otp: "979323"),
         Credential(issuer: "Canterbury", account: "naomi.nagata@gmail.com", otp: "846264"),
         Credential(issuer: "ISA Excalibur", account: "vir.cotto@gmail.com", otp: "338327"),
         Credential(issuer: "White Star 1", account: "londo.molari@gmail.com", otp: "950288")]
    }
}
