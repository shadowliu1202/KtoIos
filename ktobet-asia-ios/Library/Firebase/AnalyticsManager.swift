import Firebase
import FirebaseAnalytics

final class AnalyticsManager {
  private init() { }
  
  static func setUserID(_ id: String) {
    Crashlytics.crashlytics().setUserID(id)
  }

  static func clearUserID() {
    Crashlytics.crashlytics().setUserID("")
  }
  
  static func brandNewInstall() {
    Analytics.logEvent("brand_new_install", parameters: nil)
  }

  static func appReinstall(lastInstallDate: String, surviveDay: Int) {
    Analytics.logEvent("app_install_again", parameters: [
      "last_install_date": lastInstallDate,
      "surviveDay": surviveDay
    ])
  }

  static func playerLogin() {
    Analytics.logEvent("player_is_login", parameters: nil)
  }
}
