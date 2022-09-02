import Puppy

class PuppyLog: LoggerDelegate {
    static let shared = PuppyLog()
    
    let fileURL: URL

    private let puppy = Puppy()
    private let logFormatter = LogFormatter()
    
    private init() {
        Puppy.useDebug = true
        let consoleLogger = ConsoleLogger("com.kto.asia.console")
        consoleLogger.format = logFormatter
        puppy.add(consoleLogger, withLevel: .debug)
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = URL(string: "\(paths.absoluteString)kto-asia/puppy.log")!
        let fileLogger = try? FileLogger("com.kto.asia.file",
                              fileURL: fileURL,
                              filePermission: "600")
        if let fileLogger = fileLogger {
            fileLogger.format = logFormatter
            puppy.add(fileLogger, withLevel: .debug)
        }
    }

    func debug(_ message: String, tag: String) {
        log(.debug, message, tag: tag)
    }

    func info(_ message: String, tag: String) {
        log(.info, message, tag: tag)
    }

    func warning(_ message: String, tag: String) {
        log(.warning, message, tag: tag)
    }

    func error(_ message: String, tag: String) {
        log(.error, message, tag: tag)
    }
    
    private func log(_ level: LogLevel, _ message: String, tag: String) {
        if Configuration.enableLogger {
            switch level {
            case .trace:
                break
            case .verbose:
                break
            case .debug:
                puppy.debug(message, tag: tag)
            case .info:
                puppy.info(message, tag: tag)
            case .notice:
                break
            case .warning:
                puppy.warning(message, tag: tag)
            case .error:
                puppy.error(message, tag: tag)
            case .critical:
                break
            }
        }
    }
}

class LogFormatter: LogFormattable {
    func formatMessage(_ level: LogLevel, message: String, tag: String, function: String, file: String, line: UInt, swiftLogInfo: [String : String], label: String, date: Date, threadID: UInt64) -> String {
        let date = dateFormatter(date)
        let file = shortFileName(file)
        return "[\(level.emoji) \(level)] \(date) \(tag) \(file) #L.\(line) \(function) #M: \(message)"
    }
}
