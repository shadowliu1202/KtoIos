import Puppy

class PuppyLog: LoggerDelegate {
  static let shared = PuppyLog()

  let fileURL: URL

  private let puppy = Puppy.default
  private let logFormatter = LogFormatter()

  private init() {
    Puppy.useDebug = true
    let consoleLogger = ConsoleLogger("com.kto.asia.console")
    consoleLogger.format = logFormatter
    puppy.add(consoleLogger, withLevel: .debug)

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    fileURL = URL(string: "\(paths.absoluteString)Log/puppy.log")!
    let fileLogger = try? FileLogger(
      "com.kto.asia.file",
      fileURL: fileURL,
      filePermission: "600")
    if let fileLogger {
      fileLogger.format = logFormatter
      puppy.add(fileLogger, withLevel: .info)
    }
  }

  func debug(_ message: String, tag: String, function: String, file: String, line: UInt) {
    log(.debug, message, tag: tag, function: function, file: file, line: line)
  }

  func info(_ message: String, tag: String, function: String, file: String, line: UInt) {
    log(.info, message, tag: tag, function: function, file: file, line: line)
  }

  func warning(_ message: String, tag: String, function: String, file: String, line: UInt) {
    log(.warning, message, tag: tag, function: function, file: file, line: line)
  }

  func error(_ error: Error, tag: String, function: String, file: String, line: UInt, customValues _: [String: Any]) {
    log(.error, "\(error)", tag: tag, function: function, file: file, line: line)
  }

  private func log(_ level: LogLevel, _ message: String, tag: String, function: String, file: String, line: UInt) {
    switch level {
    case .trace:
      break
    case .verbose:
      break
    case .debug:
      puppy.debug(message, tag: tag, function: function, file: file, line: line)
    case .info:
      puppy.info(message, tag: tag, function: function, file: file, line: line)
    case .notice:
      break
    case .warning:
      puppy.warning(message, tag: tag, function: function, file: file, line: line)
    case .error:
      puppy.error(message, tag: tag, function: function, file: file, line: line)
    case .critical:
      break
    }
  }

  func addLogger(_ logger: BaseLogger, withLevel level: LogLevel) {
    puppy.add(logger, withLevel: level)
  }

  func removeLogger(_ logger: BaseLogger) {
    puppy.remove(logger)
  }
}

class LogFormatter: LogFormattable {
  func formatMessage(
    _ level: LogLevel,
    message: String,
    tag: String,
    function: String,
    file: String,
    line: UInt,
    swiftLogInfo _: [String: String],
    label _: String,
    date: Date,
    threadID _: UInt64)
    -> String
  {
    let date = dateFormatter(date)
    let file = shortFileName(file)
    return "[\(level.emoji) \(level)] \(date) \(tag) \(file) #L.\(line) \(function) #M: \(message)"
  }
}
