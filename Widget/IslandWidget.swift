import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct IslandWidgets: WidgetBundle {
    var body: some Widget { TranslationWidget() }
}

struct TranslationWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivity.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.preview).lineLimit(5)
                Button(intent: StopTranslationIntent()) { Label("停止翻译", systemImage: "stop.circle") }
            }.padding().widgetURL(URL(string: "islandtranslate://current"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("英 → 中").font(.caption) }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: StopTranslationIntent()) { Label("停止翻译", systemImage: "stop.circle") }.font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.preview).font(.callout).lineLimit(5)
                        Text(context.state.status).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: { Image(systemName: "translate") }
              compactTrailing: { Text("译") }
              minimal: { Image(systemName: "translate") }
            .widgetURL(URL(string: "islandtranslate://current"))
        }
    }
}
