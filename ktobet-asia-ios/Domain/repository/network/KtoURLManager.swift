import Alamofire
import RxSwift

class KtoURLManager {
  private let timeout: Double
  
  private let portalHosts: [String]
  private let versionUpdateHosts: [String]
  private let internetProtocol: String
  private let urlSession: URLSessionProtocol
  
  private var _portalURL: String!
  private var _versionUpdateURL: String!
  
  var portalURL: URL {
    guard let _portalURL else { fatalError("_portalURL has not been initialized. Call checkHosts() first.") }
    return URL(string: _portalURL)!
  }
  
  var versionUpdateURL: URL {
    guard let _versionUpdateURL else { fatalError("_versionUpdateURL has not been initialized. Call checkHosts() first.") }
    return URL(string: _versionUpdateURL)!
  }

  lazy var currentDomain = portalURL.absoluteString
    .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "")
    .replacingOccurrences(of: "/", with: "")
  
  init(
    timeout: Double = 4,
    portalHosts: [String] = Configuration.hostName.values.flatMap { $0 },
    versionUpdateHosts: [String] = Configuration.versionUpdateHostName.values.flatMap { $0 },
    internetProtocol: String = Configuration.internetProtocol,
    urlSession: URLSessionProtocol = URLSession.shared)
  {
    self.timeout = timeout
    self.portalHosts = portalHosts
    self.versionUpdateHosts = versionUpdateHosts
    self.internetProtocol = internetProtocol
    self.urlSession = urlSession
  }
  
  func checkHosts() async {
    let defaultPortalURLString = "\(internetProtocol)\(portalHosts.first!)/"
    let defaultVersionUpdateURLString = "\(internetProtocol)\(versionUpdateHosts.first!)/"

    let hostCheckStatus = HostCheckStatus()
    
    await withTaskGroup(of: Bool?.self) { group in
      group.addTask { [unowned self] in
        do {
          try await Task.sleep(seconds: timeout)
          _portalURL = _portalURL ?? defaultPortalURLString
          _versionUpdateURL = _versionUpdateURL ?? defaultVersionUpdateURLString
          
          return true
        }
        catch { return nil }
      }
      
      group.addTask { [unowned self] in
        do {
          _portalURL = try await findFastestHost(from: portalHosts)
          await hostCheckStatus.updatePortalStatus()
          
          return false
        }
        catch { return nil }
      }
      
      group.addTask { [unowned self] in
        do {
          _versionUpdateURL = try await findFastestHost(from: versionUpdateHosts)
          await hostCheckStatus.updateVersionUpdateStatus()
          
          return false
        }
        catch { return nil }
      }
      
      for await isTimeout in group.compactMap({ $0 }) {
        let isAllDone = await hostCheckStatus.isAllDone
        
        if isTimeout || isAllDone {
          group.cancelAll()
        }
      }
    }
  }
  
  private func findFastestHost(from allHosts: [String]) async throws -> String {
    let defaultHost = "\(internetProtocol)\(allHosts.first!)/"
    
    return try await withThrowingTaskGroup(of: String?.self) { group in
      allHosts.forEach { host in
        group.addTask { [unowned self] in try await checkServerResponse(for: host) }
      }

      for try await foundHost in group.compactMap({ $0 }) {
        group.cancelAll()
        return foundHost
      }

      return defaultHost
    }
  }
  
  func checkServerResponse(for host: String) async throws -> String? {
    try Task.checkCancellation()
    
    let url = URL(string: "\(internetProtocol)\(host)/")!
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
      
    if
      let (_, response) = try? await urlSession.data(for: request),
      let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    {
      return url.absoluteString
    }
    else {
      return nil
    }
  }
}

private actor HostCheckStatus {
  private var checkStatus = (portal: false, versionUpdate: false)

  func updatePortalStatus() {
    guard !Task.isCancelled else { return }
    checkStatus.portal = true
  }

  func updateVersionUpdateStatus() {
    guard !Task.isCancelled else { return }
    checkStatus.versionUpdate = true
  }

  var isAllDone: Bool {
    checkStatus.portal && checkStatus.versionUpdate
  }
}

protocol URLSessionProtocol {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }
