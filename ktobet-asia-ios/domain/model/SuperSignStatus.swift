import Foundation

struct SuperSignStatus {
    let endTime: Date?
    let isMaintenance: Bool
    
    init(bean: SuperSignMaintenanceBean, timezone: TimeZone) {
        let now = Date()
        let endDate = bean.endTime != nil ? Date(timeIntervalSince1970: bean.endTime!) : nil
        if let endDate = endDate, now < endDate, bean.isMaintenance {
            self.isMaintenance = true
            self.endTime = endDate
        } else {
            self.isMaintenance = false
            self.endTime = nil
        }
    }
}
