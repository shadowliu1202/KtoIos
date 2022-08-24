import Foundation
import SharedBu

class NetworkFactory: ExternalProtocolService {
    private var httpClient : HttpClient!

    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getCash() -> CashProtocol {
        CashAdapter(PlayerApi(httpClient))
    }
    
    func getCommon() -> CommonProtocol {
        CommonAdapter(BankApi(httpClient))
    }
    
    func getDeposit() -> DepositProtocol {
        DepositAdapter(BankApi(httpClient), CPSApi(httpClient))
    }
    
    func getImage() -> ImageProtocol {
        ImageAdapter(ImageApi(httpClient))
    }
    
    func getCasino() -> CasinoProtocol {
        CasinoAdapter(CasinoApi(httpClient))
    }
    
    func getNumberGame() -> NumberGameProtocol {
        NumberGameAdapter(NumberGameApi(httpClient))
    }
    
    func getArcade() -> ArcadeProtocol {
        ArcadeAdapter(ArcadeApi(httpClient))
    }
    
    func getCrypto() -> CryptoProtocol {
        fatalError("TODO")
    }
    
    func getWithdrawal() -> WithdrawalProtocol {
        fatalError("TODO")
    }
    
    func getPlayer() -> PlayerProtocol {
        fatalError("TODO")
    }
}
