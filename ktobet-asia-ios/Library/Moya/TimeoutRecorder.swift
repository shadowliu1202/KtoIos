import Foundation
import Moya

class TimeoutRecorder: PluginType {
  private var requestSendTimes: [String: Date] = [:]
  
  func prepare(_ request: URLRequest, target _: TargetType) -> URLRequest {
    var request = request
    request.addValue(UUID().description, forHTTPHeaderField: "requestID")
    return request
  }
  
  func willSend(_ request: RequestType, target _: TargetType) {
    guard let requestID = request.request?.value(forHTTPHeaderField: "requestID") else { return }
    
    requestSendTimes[requestID] = Date()
  }
  
  func didReceive(_ result: Result<Response, MoyaError>, target _: TargetType) {
    let request: URLRequest?

    switch result {
    case .success(let response):
      request = response.request
    case .failure(let error):
      request = error.response?.request
    }
    
    guard
      let requestID = request?.value(forHTTPHeaderField: "requestID"),
      let requestSendTime = requestSendTimes[requestID],
      let urlString = request?.url?.absoluteString
    else { return }
            
    requestSendTimes[requestID] = nil
    let timeoutSeconds = -requestSendTime.timeIntervalSinceNow

    if timeoutSeconds > 10 {
      Logger.shared.error(NSError(
        domain: "RequestTimeout",
        code: APPError.DefaultStatusCode.requestTimeout.rawValue,
        userInfo: [
          "RequestURL": urlString,
          "TimeoutSeconds": timeoutSeconds.description
        ]))
    }
  }
}
