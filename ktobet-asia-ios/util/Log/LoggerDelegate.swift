protocol LoggerDelegate {
  func debug(_ message: String, tag: String, function: String, file: String, line: UInt)
  func info(_ message: String, tag: String, function: String, file: String, line: UInt)
  func warning(_ message: String, tag: String, function: String, file: String, line: UInt)
  func error(_ error: Error, tag: String, function: String, file: String, line: UInt, customValues: [String: Any])
}
