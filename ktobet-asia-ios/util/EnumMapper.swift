import Foundation
import SharedBu

class EnumMapper {
    static func convert(messageType: Int32) -> SharedBu.MessageType {
        try! EnumMapper.convert(messageType: messageType).1
    }
    
    static func convert(messageType: SharedBu.MessageType) -> Int32 {
        try! EnumMapper.convert(messageType: messageType).0
    }
    
    private static func convert(messageType: Any) throws -> (Int32, SharedBu.MessageType) {
        switch messageType {
        case let type as SharedBu.MessageType:
            switch type {
            case .text:
                return (0, .text)
            case .image:
                return (1, .image)
            case .link:
                return (2, .link)
            default:
                throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
            }
        case let i as Int32:
            switch i {
            case 0:
                return (0, .text)
            case 1:
                return (1, .image)
            case 2:
                return (2, .link)
            default:
                throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
            }
        default:
            throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
        }
    }
    
    static func convert(speakerType: Int32) -> SpeakerType {
        try! EnumMapper.convert(speakerType: speakerType).1
    }
    
    static func convert(speakerType: SpeakerType) -> Int32 {
        try! EnumMapper.convert(speakerType: speakerType).0
    }
    
    private static func convert(speakerType: Any) throws -> (Int32, SpeakerType) {
        switch speakerType {
        case let type as SpeakerType:
            switch type {
            case .player:
                return (0, .player)
            case .handler:
                return (1, .handler)
            case .system:
                return (2, .system)
            default:
                throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
            }
        case let i as Int32:
            switch i {
            case 0:
                return (0, .player)
            case 1:
                return (1, .handler)
            case 2:
                return (2, .system)
            default:
                throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
            }
        default:
            throw KtoException.init(errorMsg: "Unknown type", errorCode: "")
        }
    }
}
