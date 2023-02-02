import Firebase

class FirebaseLog: LoggerDelegate {
  static let shared = FirebaseLog()

  private init() { }

  func setUserID(_ id: String) {
    Crashlytics.crashlytics().setUserID(id)
  }

  func clearUserID() {
    Crashlytics.crashlytics().setUserID("")
  }

  func debug(_: String, tag _: String, function _: String, file _: String, line _: UInt) { }

  func info(_: String, tag _: String, function _: String, file _: String, line _: UInt) { }

  func warning(_: String, tag _: String, function _: String, file _: String, line _: UInt) { }

  func error(_ error: Error, tag _: String, function _: String, file _: String, line _: UInt) {
    Crashlytics.crashlytics()
      .setCustomValue(NetworkStateMonitor.shared.connectivityStatus.description, forKey: "NetworkStatus")
    Crashlytics.crashlytics().record(error: error)
  }
}
