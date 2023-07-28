import Foundation
import Moya
import RxSwift
import SharedBu

class CustomServiceAPI: CustomServiceAPIConvertor {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func createRoom(_ bean: PreChatAnswerSurvey?) -> Single<String> {
    var codableBean: Encodable = .empty
    if let bean {
      codableBean = convert(surveyAnswers: bean.answerSurvey)
    }
    return httpClient
      .requestJsonString(
        path: "onlinechat/api/room",
        method: .post,
        task: .requestJSONEncodable(codableBean))
  }

  private func convert(surveyAnswers: AnswerSurvey_) -> PreChatAnswerSurveyBean {
    PreChatAnswerSurveyBean(
      answerSurvey: AnswerSurveyBean(
        questions: surveyAnswers.questions
          .map {
            convert(question: $0)
          }))
  }

  func getCustomerServiceStatus() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/cs-status",
        method: .get)
  }

  func getInProcess() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/in-process",
        method: .get)
  }

  func getPlayerInChat() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/player/in-chat",
        method: .get)
  }

  func getQueueNumber() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/queue-number",
        method: .get)
  }

  func playerClose() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/player/close",
        method: .post)
  }

  func removeChatRoomToken() -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/common/remove-token",
        method: .post)
  }

  func send(bean: SendBean_) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/send",
        method: .post,
        task: .requestJSONEncodable(convert(sendBean: bean)))
  }

  private func convert(sendBean: SendBean_) -> SendBean {
    .init(
      message: convert(messageBean: sendBean.message),
      roomId: sendBean.roomId)
  }

  private func convert(messageBean: MessageBean) -> Message {
    .init(
      quillDeltas: messageBean.quillDeltas.map {
        convert(quillDeltaBean: $0)
      })
  }

  private func convert(quillDeltaBean: QuillDeltaBean) -> QuillDelta {
    .init(
      attributes: convert(attributes: quillDeltaBean.attributes),
      insert: quillDeltaBean.insert)
  }

  private func convert(attributes: Attributes_?) -> Attributes? {
    .init(
      align: attributes?.align?.intValue,
      background: attributes?.background,
      bold: attributes?.bold?.boolValue,
      color: attributes?.color,
      font: attributes?.font,
      image: attributes?.image,
      italic: attributes?.italic?.boolValue,
      link: attributes?.link,
      size: attributes?.size,
      underline: attributes?.underline?.boolValue)
  }

  func send(bean: SendImageBean_) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/room/send",
        method: .post,
        task: .requestJSONEncodable(convert(sendImageBean: bean)))
  }

  private func convert(sendImageBean: SendImageBean_) -> SendBean {
    .init(
      message: convert(message: sendImageBean.message),
      roomId: sendImageBean.roomId)
  }

  private func convert(message: SendImageBean_.Message) -> Message {
    .init(
      quillDeltas:
      message.quillDeltas.map {
        convert(quillDelta: $0)
      })
  }

  private func convert(quillDelta: SendImageBean_.QuillDelta) -> QuillDelta {
    .init(
      attributes: convert(attributes: quillDelta.attributes),
      insert: quillDelta.insert)
  }

  private func convert(attributes: SendImageBean_.Attributes) -> Attributes {
    .init(image: attributes.image)
  }
  
  func uploadImage(query: [String: Any], imageData: [MultipartFormData]) -> Single<ResponseData<String>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "onlinechat/api/image/upload",
      method: .post,
      task: .uploadCompositeMultipart(imageData, urlParameters: query),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<String>.self)
  }
}
