import Alamofire
import Connectivity
import Foundation
import Moya
import RxBlocking
import RxSwift
import SDWebImage
import sharedbu
import SwiftyJSON
import UIKit

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == Response {
    private func asJsonResponse() -> Single<ResponseJson> {
        flatMap { response in
            guard
                let json = try? JSON(data: response.data),
                let rawString = json.rawString()
            else { return .error(ResponseParseError(rawData: response.data)) }
            return .just(ResponseJson(raw: rawString))
        }
    }

    func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseList<T>>where T: KotlinBase {
        asJsonResponse().asReaktiveResponseList(serial: serial)
    }

    func asReaktiveResponseItem<T>() -> SingleWrapper<ResponseItem<T>> where T: Any {
        asJsonResponse().asReaktiveResponseItem()
    }

    func asReaktiveResponseItem<T: Any, F: Any>(transfrom: @escaping ((T) -> F)) -> SingleWrapper<ResponseItem<F>> {
        asJsonResponse().asReaktiveResponseItem(transfrom: transfrom)
    }

    func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseItem<T>> where T: KotlinBase {
        asJsonResponse().asReaktiveResponseItem(serial: serial)
    }

    func asReaktiveResponsePayload<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponsePayload<T>> where T: KotlinBase {
        asJsonResponse().asReaktiveResponsePayload(serial: serial)
    }

    func asReaktiveResponseNothing() -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        asJsonResponse().asReaktiveResponseNothing()
    }

    func asReaktiveCompletable() -> CompletableWrapper {
        asJsonResponse().asReaktiveCompletable()
    }
}

extension RxSwift.Observable where Element == Response {
    private func asJsonResponse() -> Observable<ResponseJson> {
        flatMap { response in
            guard
                let json = try? JSON(data: response.data),
                let rawString = json.rawString()
            else { return Observable<ResponseJson>.error(ResponseParseError(rawData: response.data)) }
            return .just(ResponseJson(raw: rawString))
        }
    }

    func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseList<T>>where T: KotlinBase {
        asJsonResponse().asReaktiveResponseList(serial: serial)
    }

    func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseItem<T>>where T: KotlinBase {
        asJsonResponse().asReaktiveResponseItem(serial: serial)
    }
}
