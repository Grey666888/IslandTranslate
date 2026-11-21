import SwiftUI
import Translation

@main
struct IslandTranslateApp: App {
    @StateObject private var model = TranslationModel.shared
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { _ in } // Opening the island reveals the in-memory full text.
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: TranslationModel
    @State private var configuration: TranslationSession.Configuration?
    var body: some View {
        NavigationStack {
            Form {
                Section("使用") {
                    Button("准备英中离线语言包") {
                        configuration = .init(source: .init(identifier: "en"), target: .init(identifier: "zh-Hans"))
                    }
                    Toggle("实验性后台保持运行", isOn: $model.useAudioExperiment)
                        .disabled(model.running)
                    Text("此实验播放静音音频，不保证后台剪贴板可读。灵动岛展开时长由系统决定。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button(model.running ? "停止翻译" : "开启翻译") {
                        Task { if model.running { await model.stop() } else { await model.start() } }
                    }
                    .disabled(model.starting)
                }
                Section("当前状态") {
                    Text(model.status)
                    Text("本次读取次数：\(model.readCount) · 成功翻译：\(model.translationCount)")
                        .font(.caption)
                }
                Section("中文译文") {
                    Text(model.translated.isEmpty ? "开启后，在其他 App 中复制英语。" : model.translated)
                        .textSelection(.enabled)
                }
                if !model.original.isEmpty {
                    Section("当前原文") { Text(model.original).textSelection(.enabled) }
                }
                Section {
                    Text("仅在内存中保留当前原文和译文，停止即清除。系统实时活动会承载译文片段，并可能出现在锁屏；不创建历史数据库。")
                        .font(.caption)
                }
            }
            .navigationTitle("岛译 · 可行性验证")
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                    model.status = "离线语言资源已准备，可开启翻译。"
                } catch { model.status = "语言包准备失败：\(error.localizedDescription)" }
                configuration = nil
            }
        }
    }
}
