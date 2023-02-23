import Foundation
import RxSwift
import SharedBu

protocol BankRepository {
  func getBankMap() -> Single<[(Int, Bank)]>
  func getBankDictionary() -> Single<[Int: Bank]>
}

class BankRepositoryImpl: BankRepository {
  private var bankApi: BankApi!

  init(_ bankApi: BankApi) {
    self.bankApi = bankApi
  }

  func getBankMap() -> Single<[(Int, Bank)]> {
    self.getBankDictionary().map { ($0.dictionaryToTuple().sorted(by: { $0.0 < $1.0 }).map { ($0, $1) }) }
  }

  func getBankDictionary() -> Single<[Int: Bank]> {
    self.bankApi.getBanks().map { (response: ResponseData<[SimpleBank]>) -> [Int: Bank] in
      if let data = response.data {
        return data.map({ Bank(bankId: Int32($0.bankId), name: $0.name, shortName: $0.shortName) })
          .toDictionary { Int($0.bankId) }
      }
      return [:]
    }
  }
}
