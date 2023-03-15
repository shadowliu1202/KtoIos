import Alamofire
import Foundation
import Moya
import RxCocoa
import RxSwift
import SharedBu
import UIKit

struct APIErrorHandler {
  let target: UIViewController

  func handle(_ error: Error) {
    switch error {
    case let apiException as ApiException:
      let code = Int(apiException.errorCode) ?? 0
      let errorMsg: String = apiException.message ?? ""
      let err = NSError(domain: "", code: code, userInfo: ["errorMsg": errorMsg])
      handleHttpError(err)
    case let moyaError as MoyaError:
      handleMoyaError(moyaError)
    case let afError as AFError:
      handleAFError(afError)
    case let nsError as NSError:
      handleHttpError(nsError)
    default:
      handleUnknownError(error)
    }
  }
}

// MARK: - Error Handle

extension APIErrorHandler {
  private func handleMoyaError(_ error: MoyaError) {
    switch error {
    case .statusCode(let response):
      let nsError = NSError(
        domain: response.request?.url?.path ?? "",
        code: response.statusCode,
        userInfo: ["errorMsg": response.description])

      handleHttpError(nsError, errorResponse: response)

    case .underlying(let err, _):
      if err is AFError {
        handleAFError(err as! AFError)
      }
      else {
        handleHttpError(err as NSError)
      }

    case .parameterEncoding(let err):
      Logger.shared.error(err)

    case .encodableMapping,
         .imageMapping,
         .jsonMapping,
         .objectMapping,
         .stringMapping:
      target.showToast(Localize.string("common_malformedexception"), barImg: .failed)

    default:
      handleUnknownError(error)
    }
  }

  private func handleHttpError(_ nsError: NSError, errorResponse: Response? = nil) {
    let statusCode = nsError.code

    switch statusCode {
    case 401:
      @Injected(name: "CheckingIsLogged") var tracker: ActivityIndicator

      guard !tracker.isLoading else { return }

      handleUnknownError(nsError)

    case 403:
      target.showRestrictView()

    case 404:
      target.showToast(Localize.string("common_unknownerror", "\(statusCode)"), barImg: .failed)
      Logger.shared.error(nsError)

    case 410:
      target.handleMaintenance()

    case 429:
      target.handleTooManyRequest()

    case 502:
      if
        let errorResponse,
        let info = parse502Html(errorResponse)
      {
        target.showToast(Localize.string("common_unknownerror", "\(statusCode)"), barImg: .failed)
        Logger.shared.error(nsError, customValues: info)
      }
      else {
        handleUnknownError(nsError)
      }

    case 503:
      target.showToast(Localize.string("common_http_503", "\(statusCode)"), barImg: .failed)

    case 608:
      target.showCDNErrorView()

    default:
      handleUnknownError(nsError)
    }
  }

  private func handleAFError(_ error: AFError) {
    if case .sessionTaskFailed(let err) = error, let nsError = err as NSError? {
      handleHttpError(nsError)
    }
    else if case .explicitlyCancelled = error {
      // do nothing
    }
    else {
      handleUnknownError(error)
    }
  }

  private func handleUnknownError(_ error: Error) {
    let statusCode = (error as NSError).code

    if statusCode.isNetworkConnectionLost() {
      target.showToast(Localize.string("common_unknownhostexception"), barImg: .failed)
    }
    else {
      target.showToast(Localize.string("common_unknownerror", "\(statusCode)"), barImg: .failed)
      Logger.shared.error(error)
    }
  }
}

// MARK: - UI

extension UIViewController {
  fileprivate func showRestrictView() {
    let restrictedVC = UIStoryboard(name: "slideMenu", bundle: nil).instantiateViewController(withIdentifier: "restrictedVC")
    self.present(restrictedVC, animated: true, completion: nil)
  }

  fileprivate func showCDNErrorView() {
    let cndErrorVC = UIStoryboard(name: "slideMenu", bundle: nil)
      .instantiateViewController(withIdentifier: "CDNErrorViewController")
    self.present(cndErrorVC, animated: true, completion: nil)
  }

  fileprivate func handleTooManyRequest() {
    showToast(Localize.string("common_retry_later"), barImg: nil)
  }
}

// MARK: - Parse Error Response

extension APIErrorHandler {
  private func groups(_ regexPattern: String, from: String) -> [[String]] {
    let regex = try? NSRegularExpression(pattern: regexPattern)

    return regex?.matches(
      in: from,
      range: NSRange(from.startIndex..., in: from))
      .map { match in
        (0..<match.numberOfRanges).map {
          let rangeBounds = match.range(at: $0)
          guard let range = Range(rangeBounds, in: from) else { return "" }
          return String(from[range])
        }
      } ?? []
  }

  private func parse502Html(_ response: Response) -> [String: String]? {
    guard let rawHtml = String(data: response.data, encoding: .utf8) else { return nil }

    return [
      "502_Detail": self.groups("<div class=message>(.*?)</div>", from: rawHtml).first?.last ?? "",
      "502_Message": self.groups("<div class=detail>(.*?)</div>", from: rawHtml).first?.last?.removeHtmlTag() ?? "",
      "502_HOST": response.request?.url?.host ?? ""
    ]
  }
}
