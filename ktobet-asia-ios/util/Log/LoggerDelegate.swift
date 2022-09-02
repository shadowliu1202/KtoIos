protocol LoggerDelegate {
    func debug(_ message: String, tag: String)
    func info(_ message: String, tag: String)
    func warning(_ message: String, tag: String)
    func error(_ message: String, tag: String)
}
