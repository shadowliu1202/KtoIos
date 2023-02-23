import Puppy

class LogRecordViewModel {
  var manuallyLogger: FileLogger?

  init() {
    if let manuallyLogFileName = UserDefaults.standard.object(forKey: "ManuallyLogFileName") as? String {
      startManuallyLogger(fileName: manuallyLogFileName)
    }
  }

  func startManuallyLogger(fileName: String? = nil) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd'T'HH-mm-ss"
    let defaultFileName = dateFormatter.string(from: Date())
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = URL(string: "\(paths.absoluteString)Log/\(fileName ?? defaultFileName).log")!

    let fileLogger = try? FileLogger(
      "com.kto.asia.QAFile",
      fileURL: fileURL,
      filePermission: "600")

    guard let fileLogger else { return }
    fileLogger.format = LogFormatter()

    PuppyLog.shared.addLogger(fileLogger, withLevel: .info)
    manuallyLogger = fileLogger
    UserDefaults.standard.setValue(fileName ?? defaultFileName, forKey: "ManuallyLogFileName")
  }

  func terminateManuallyLogger() {
    guard let manuallyLogger else { return }
    PuppyLog.shared.removeLogger(manuallyLogger)
    self.manuallyLogger = nil
    UserDefaults.standard.setValue(nil, forKey: "ManuallyLogFileName")
  }
}
