import ActivityKit
import Combine
import NaturalLanguage
import Translation
import UIKit

@MainActor
final class TranslationModel: ObservableObject {
    static let shared = TranslationModel()
    @Published var running = false
    @Published var starting = false
    @Published var useAudioExperiment = false
    @Published var status = "尚未开启"
    @Published var original = ""
    @Published var translated = ""
    @Published var readCount = 0
    @Published var translationCount = 0
    private var timer: Timer?
    private var task: Task<Void, Never>?
    private var revision = UUID()
    private var lastChange = 0
    private var activity: Activity<TranslationActivity>?
    private let audio = BackgroundAudioExperiment()

    func start() async {
        guard !running, !starting else { return }
        starting = true
        defer { starting = false }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "请在系统设置中允许本 App 的实时活动。"; return
        }
        let availability = await LanguageAvailability().status(from: .init(identifier: "en"), to: .init(identifier: "zh-Hans"))
        guard availability == .installed else {
            status = "请先准备英中离线语言包。"; return
        }
        do {
            for old in Activity<TranslationActivity>.activities {
                await old.end(nil, dismissalPolicy: .immediate)
            }
            activity = try Activity.request(attributes: TranslationActivity(sessionID: UUID()),
                content: ActivityContent(state: .init(preview: "等待复制英语", status: "已开启"), staleDate: nil), pushType: nil)
            if useAudioExperiment { try audio.start() }
            running = true
            readCount = 0
            translationCount = 0
            lastChange = UIPasteboard.general.changeCount
            status = "等待新的复制。后台读取和持续展开尚待真机验证。"
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.poll() }
            }
        } catch {
            await stop()
            status = "启动失败：\(error.localizedDescription)"
        }
    }

    private func poll() {
        guard running else { return }
        readCount += 1
        let board = UIPasteboard.general
        guard board.changeCount != lastChange else { return }
        // Do not mark a change consumed until a string is actually readable.
        guard let value = board.string else {
            status = "复制变化已检测到，但文字不可读（可能是系统限制或非文本）。"
            return
        }
        lastChange = board.changeCount
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Every new copy invalidates any pending result, even if the new value is ignored.
        revision = UUID()
        task?.cancel()
        guard TextPolicy.accepts(text) else { status = "已忽略非英语、网址或数字。"; return }
        let token = revision
        original = text
        translated = ""
        status = "正在本地翻译"
        task = Task {
            if let activity {
                await activity.update(ActivityContent(state: .init(preview: "正在本地翻译…", status: "处理中"), staleDate: nil))
            }
            do {
                let session = TranslationSession(installedSource: .init(identifier: "en"), target: .init(identifier: "zh-Hans"))
                let response = try await session.translate(text)
                guard !Task.isCancelled, running, token == revision else { return }
                translated = response.targetText
                translationCount += 1
                status = "本地翻译完成"
                let state = TranslationActivity.ContentState(preview: String(response.targetText.prefix(220)), status: "点击查看全文")
                // Alert requests an expanded presentation; there is no permanent-expanded API.
                await activity?.update(ActivityContent(state: state, staleDate: nil),
                    alertConfiguration: AlertConfiguration(title: "翻译完成", body: "中文译文已更新", sound: .default))
            } catch {
                guard !Task.isCancelled, running, token == revision else { return }
                status = "本地翻译失败：\(error.localizedDescription)"
                await activity?.update(ActivityContent(state: .init(preview: "翻译失败，请打开 App 查看状态", status: "失败"), staleDate: nil))
            }
        }
    }

    func stop() async {
        running = false
        revision = UUID()
        timer?.invalidate(); timer = nil
        task?.cancel(); task = nil
        audio.stop()
        original = ""; translated = ""
        let old = activity
        activity = nil
        status = "已停止，当前内容已清除"
        await old?.end(nil, dismissalPolicy: .immediate)
    }
}

enum TextPolicy {
    static func accepts(_ text: String) -> Bool {
        guard !text.isEmpty, text.count <= 20000 else { return false }
        if text.range(of: #"^(https?://|www\.)\S+$"#, options: [.regularExpression, .caseInsensitive]) != nil { return false }
        guard text.range(of: "[A-Za-z]", options: .regularExpression) != nil else { return false }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage == .english
    }
}
