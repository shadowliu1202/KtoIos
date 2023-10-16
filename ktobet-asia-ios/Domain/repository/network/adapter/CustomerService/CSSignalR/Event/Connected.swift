import Foundation
import RxSwift
import sharedbu

class Connected: ChatRoomVisitor {
  private let httpClient: HttpClient
  private let disposeBag = DisposeBag()

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func visit(config _: Config) {
    // Do nothing
  }

  func visit(connection: sharedbu.Connection) {
    connection.update(connectStatus: sharedbu.Connection.StatusConnected())
  }

  func visit(messageManager: MessageManager) {
    getInProcess()
      .compactMap {
        $0.data
      }
      .map {
        try ChatMapper.convert(beans: $0)
      }
      .subscribe(onSuccess: {
        messageManager.refresh(histories: $0)
      })
      .disposed(by: disposeBag)
  }

  private func getInProcess() -> Single<ResponseData<[InProcessBean]>> {
    httpClient.request(
      NewAPITarget(
        path: "onlinechat/api/room/in-process",
        method: .get))
      .map(ResponseData<[InProcessBean]>.self)
  }
}
