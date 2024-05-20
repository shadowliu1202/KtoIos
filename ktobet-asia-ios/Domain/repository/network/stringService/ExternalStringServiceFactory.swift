import Foundation
import sharedbu

class ExternalStringServiceFactory: ExternalStringService {
    func deposit() -> DepositStringService {
        DepositStringServiceAdapter()
    }
  
    func casino() -> CasinoStringService {
        CasinoStringServiceAdapter()
    }
  
    func p2p() -> P2PStringService {
        P2PStringServiceAdapter()
    }
}
