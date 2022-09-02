import Foundation

class Logger {
    static let shared = Logger()
    
    var delegate: LoggerDelegate? = nil
    
    private init() {}
    
    func debug(_ message: String, tag: String = "") {
        delegate?.debug(message, tag: tag)
    }
}
