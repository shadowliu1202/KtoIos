import Firebase

class FirebaseLog: LoggerDelegate {
  static let shared = FirebaseLog()
  
  private init() { }

  func debug(_: String, tag _: String, function _: String, file _: String, line _: UInt) { }

  func info(_ message: String, tag _: String, function _: String, file _: String, line _: UInt) {
    Crashlytics.crashlytics().log(message)
  }

  func warning(_: String, tag _: String, function _: String, file _: String, line _: UInt) { }

  func error(
    _ error: Error, tag _: String,
    function _: String,
    file _: String,
    line _: UInt,
    customValues: [String: Any])
  {
    let log: [String: Any] = [
      "NetworkStatus": NetworkStateMonitor.shared.connectivityStatus.description,
      "IP": getIP()
    ]
    .merging(customValues, uniquingKeysWith: { frist, _ in frist })

    Crashlytics.crashlytics().setCustomKeysAndValues(log)
    Crashlytics.crashlytics().record(error: error)
  }

  private func getIP() -> String {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    if getifaddrs(&ifaddr) == 0 {
      var ptr = ifaddr

      while ptr != nil {
        defer { ptr = ptr?.pointee.ifa_next }

        guard let interface = ptr?.pointee else { return "" }

        let addrFamily = interface.ifa_addr.pointee.sa_family

        if
          addrFamily == UInt8(AF_INET) ||
          addrFamily == UInt8(AF_INET6)
        {
          // wifi = ["en0"]
          // wired = ["en2", "en3", "en4"]
          // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

          let name = String(cString: interface.ifa_name)
          if
            name == "en0" ||
            name == "en2" ||
            name == "en3" ||
            name == "en4" ||
            name == "pdp_ip0" ||
            name == "pdp_ip1" ||
            name == "pdp_ip2" ||
            name == "pdp_ip3"
          {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            getnameinfo(
              interface.ifa_addr,
              socklen_t(interface.ifa_addr.pointee.sa_len),
              &hostname,
              socklen_t(hostname.count),
              nil,
              socklen_t(0),
              NI_NUMERICHOST)

            address = String(cString: hostname)
          }
        }
      }
      freeifaddrs(ifaddr)
    }
    return address ?? ""
  }
}
