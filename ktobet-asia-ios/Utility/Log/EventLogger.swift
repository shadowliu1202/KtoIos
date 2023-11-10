import FirebaseAnalytics

class EventLogger {
  static let shared = EventLogger()

  private init() { }

  func brandNewInstall() {
    log("brand_new_install", nil)
  }

  func appReinstall(lastInstallDate: String, surviveDay: Int) {
    log("app_install_again", [
      "last_install_date": lastInstallDate,
      "surviveDay": surviveDay
    ])
  }

  func playerLogin() {
    log("player_is_login", nil)
  }

  func log(_ name: String, _ parameters: [String: Any]? = nil) {
    Analytics.logEvent(name, parameters: parameters)
  }
}
