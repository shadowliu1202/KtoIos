import Foundation
import RxSwift
import RxCocoa
import SharedBu

let adultAge = 18

class BirthdayValidator {
    func validateBirthday(_ date: Date?) -> BithdayValidError {
        var status: BithdayValidError
        if date != nil {
            if let date = date, let age = Date().calculateAge(birthday: date), age < adultAge {
                status = .notAdult
            } else {
                status = BithdayValidError.none
            }
        } else {
            status = .empty
        }
        return status
    }
}
