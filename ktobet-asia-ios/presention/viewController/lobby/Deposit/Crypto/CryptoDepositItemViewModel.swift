import Foundation
import SharedBu

final class CryptoDepositItemViewModel {
    let option: PaymentsDTO.TypeOptions
    let icon: String
    let isSelected: Bool
    
    init (with option: PaymentsDTO.TypeOptions, icon: String, isSelected: Bool) {
        self.option = option
        self.icon = icon
        self.isSelected = isSelected
    }
}
