import Foundation

class Logger {
    static let shared = Logger()
    static func configure() {
        if Configuration.enableRemoteLog {
            FirebaseLog.configure()
        }
    }
    
    private var delegates: [LoggerDelegate] = []
    
    private init() {
        if Configuration.enableFileLog {
            delegates.append(PuppyLog.shared)
        }
        
        if Configuration.enableRemoteLog {
            delegates.append(FirebaseLog.shared)
        }
    }
    
    func debug(_ message: String, tag: String = "", function: String = #function, file: String = #file, line: UInt = #line) {
        for delegate in delegates {
            delegate.debug(message, tag: tag, function: function, file: file, line: line)
        }
    }
    
    func error(_ error: Error, tag: String = "", function: String = #function, file: String = #file, line: UInt = #line) {
        for delegate in delegates {
            delegate.error(error, tag: tag, function: function, file: file, line: line)
        }
    }
    
}
