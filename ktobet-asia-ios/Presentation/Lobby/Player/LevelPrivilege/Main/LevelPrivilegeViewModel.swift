import Foundation
import RxCocoa
import RxSwift
import sharedbu

class LevelPrivilegeViewModel: CollectErrorViewModel {
  class Item {
    enum Collapse: Int {
      case fold
      case unFold
    }

    private(set) var model: LevelOverview
    private(set) var level: Int32 = 0
    private(set) var time = ""
    private(set) var privileges: [LevelPrivilege] = []

    var isFold = false

    var collapse: Collapse {
      isFold ? .fold : .unFold
    }

    init(_ model: LevelOverview) {
      self.model = model
      self.level = model.level
      self.time = model.timeStamp.toDateTimeFormatString()
      self.privileges = model.privileges
    }
  }

  private let playerUseCase: PlayerDataUseCase

  private let disposeBag = DisposeBag()

  private(set) var itemsRelay = BehaviorRelay<[Item]>(value: [])
  private(set) var playerRelay = PublishRelay<Player>()

  let TopLevel = 10
  var currentLevel: Int32 = 0

  init(playerUseCase: PlayerDataUseCase) {
    self.playerUseCase = playerUseCase
  }
}

// MARK: - API

extension LevelPrivilegeViewModel {
  func fetchData() {
    Observable.zip(
      getPrivilege().asObservable(),
      loadPlayerInfo().asObservable())
      .subscribe(onNext: { [weak self] levelOverview, player in
        guard let self else { return }
        self.currentLevel = player.playerInfo.level

        let items = levelOverview.map { Item($0) }
        self.mappingItem(items)
      }, onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  private func loadPlayerInfo() -> Single<Player> {
    playerUseCase.loadPlayer()
      .do(onSuccess: { [weak self] in
        self?.playerRelay.accept($0)
      })
  }

  private func getPrivilege() -> Single<[LevelOverview]> {
    playerUseCase.getPrivilege()
  }
}

// MARK: - Data Handle

extension LevelPrivilegeViewModel {
  func mappingItem(_ newData: [Item]) {
    let copyValue = itemsRelay.value

    newData.forEach { theNew in
      if let theOld = copyValue.first(where: { $0.level == theNew.level }) {
        theNew.isFold = theOld.isFold
      }
    }

    itemsRelay.accept(newData)
  }

  func getItem(_ row: Int) -> Item {
    itemsRelay.value[row]
  }

  func isTopLevel(_ row: Int) -> Bool {
    row == 0 && getItem(row).level == TopLevel
  }

  func isPreviewLevel(_ row: Int) -> Bool {
    row == 0 && getItem(row).level != currentLevel
  }

  func isZeroLevel(_ row: Int) -> Bool {
    row == itemsRelay.value.count - 1
  }
}
