import XCTest
import ViewInspector
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

extension DepositOfflineConfirmView.Row: Inspecting { }

final class DepositOfflineConfirmViewTests: XCTestCase {

    func buildMemo(amount: String) -> OfflineDepositDTO.Memo {
        .init(
            identity: "",
            remitter: .init(name: "Test remiiter", account: "", bankName: ""),
            remittance: amount.toAccountCurrency(),
            beneficiary: .init(
                name: "",
                branch: "Test branch",
                account: .init(accountName: "Test receiver", accountNumber: "1234-5678-9011")
            ),
            expiredHour: 3
        )
    }

    func buildBankCard() -> PaymentsDTO.BankCard {
        .init(
            identity: "",
            bankId: "1",
            name: "Test selected bank",
            verifier: .init()
        )
    }

    func test_RemitAmountHaveTwoDecimal_DecimalTextColorIsOrangeFF8000() {
        let stubViewModel = DepositOfflineConfirmViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
            locale: .China()
        )

        let attributed = stubViewModel
            .amountAttributed(from: "100.12")
            .attribute(
                .foregroundColor,
                at: 4,
                longestEffectiveRange: nil,
                in: .init(location: 0, length: 2)
            ) as! UIColor

        XCTAssertEqual(attributed, UIColor.orangeFF8000)
    }

    func test_RemitAmountHaveNotDecimal_AllTextColorIsWhitePure() {
        let stubViewModel = DepositOfflineConfirmViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
            locale: .China()
        )

        let attributed = stubViewModel
            .amountAttributed(from: "100")
            .attribute(
                .foregroundColor,
                at: 0,
                longestEffectiveRange: nil,
                in: .init(location: 0, length: 3)
            ) as! UIColor

        XCTAssertEqual(attributed, UIColor.whitePure)
    }

    func test_ValidTimeLeft3Hours_TextIsCorrect() {
        let stubViewModel = DepositOfflineConfirmViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
            locale: .China()
        )

        let leftTime = stubViewModel.configTimeString(3 * 3600)

        XCTAssertEqual(leftTime, "03:00:00")
    }

    func test_ValidTimeLeft30Minutes_TextIsCorrect() {
        let stubViewModel = DepositOfflineConfirmViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
            locale: .China()
        )

        let leftTime = stubViewModel.configTimeString(30 * 60)

        XCTAssertEqual(leftTime, "30:00")
    }

    func test_ContentWillBeCopied_PressCopyButton() {
        let stubViewModel = DepositOfflineConfirmViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
            locale: .China()
        )

        let row = DepositOfflineConfirmView<DepositOfflineConfirmViewModel>.Row(type: .receiveBank)

        UIPasteboard.general.setObjects([])
        XCTAssertFalse(UIPasteboard.general.hasStrings)

        let expectation = row.inspection.inspect { view in
            try view
                .hStack()
                .button(2)
                .tap()

            XCTAssertTrue(UIPasteboard.general.hasStrings)
        }

        ViewHosting.host(
            view: row.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 30)
    }
}
