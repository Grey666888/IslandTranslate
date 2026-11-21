import AppIntents
import ActivityKit

struct StopTranslationIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "停止翻译"
    static var openAppWhenRun: Bool = false
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await TranslationModel.shared.stop()
        #endif
        for activity in Activity<TranslationActivity>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
