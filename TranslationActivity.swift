import ActivityKit
import Foundation

struct TranslationActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var preview: String
        var status: String
    }
    var sessionID: UUID
}
