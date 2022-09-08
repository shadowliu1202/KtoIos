import Firebase

class FirebaseLog: LoggerDelegate {
    static let shared: FirebaseLog = FirebaseLog()
    static func configure() {
        FirebaseApp.configure()
    }
    
    private init() {}
    
    func setUserID(_ id: String) {
        Crashlytics.crashlytics().setUserID(id)
    }
    
    func clearUserID() {
        Crashlytics.crashlytics().setUserID("")
    }
    
    func debug(_ message: String, tag: String, function: String, file: String, line: UInt) {
        
    }
    
    func info(_ message: String, tag: String, function: String, file: String, line: UInt) {
        
    }
    
    func warning(_ message: String, tag: String, function: String, file: String, line: UInt) {
        
    }
    
    func error(_ error: Error, tag: String, function: String, file: String, line: UInt) {
        Crashlytics.crashlytics().record(error: error)
    }
}
