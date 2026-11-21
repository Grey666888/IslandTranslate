# 岛译 · iPhone 可行性验证版

面向 iPhone 16 Pro Max / iOS 27 的原生 SwiftUI 验证工程，最低 iOS 26。
目标：手动开启后，在其他 App 复制英语，本地翻成简体中文并更新灵动岛。
**尚未通过 Xcode 构建或真机验证。不是已验证能替代欧路的成品。**

## 已实现的代码

- Apple Translation 语言资源准备，以及设备端英译中。
- 每秒检查剪贴板变化；同样文字重新复制也可重新触发。
- 新复制使旧请求失效，避免旧译文覆盖新译文。
- 忽略非英语、纯网址和数字；支持通常约 300 英文单词的输入。
- ActivityKit 展示最多 220 字的预览，点击进入 App 查看完整译文。
- LiveActivityIntent 停止按钮；停止清空当前原文和译文。
- 不创建历史、数据库、账号、网络翻译接口，也不记录文本日志。

## 必须验证的限制

1. 普通后台轮询不保证运行，也不保证能够读取剪贴板。
2. 可选“实验性后台保持运行”使用内存生成的静音音频，仅作为实验；默认关闭。它不赋予剪贴板权限，可能影响耗电及音频行为。
3. ActivityKit 的 alertConfiguration 请求系统展开，不能保证始终展开。当前更新使用系统默认提示音，需实测提示体验。
4. 译文片段交给系统实时活动显示，可能出现在锁屏。无历史存储不等于系统从未缓存展示内容。
5. 本次未借用 Clip 的私有 API，也没有把手动粘贴伪装成后台自动翻译。
6. 进程被系统结束后，内存全文会丢失；再次开启会结束遗留实时活动。

## Windows 用户构建和安装路径

此目录尚未创建 GitHub 仓库，也未上传任何内容。

1. 将工程推送至自己的公开 GitHub 仓库（不上传账号凭据）。
2. Actions → Build unsigned iPhone verification app → Run workflow。
3. 工作流用 macOS 26、Xcode 和 XcodeGen 编译 **iphoneos 真机版本**，而非模拟器版本。
4. 下载 `IslandTranslate-unsigned` 构建产物并解压得到 IPA。
5. 用 Windows 上的 AltStore Classic / AltServer 配合自己的 Apple 账号重新签名安装；IPA 不能直接点击安装。需要保留 Widget 扩展，并按工具要求启用开发者模式。
6. 免费签名需定期刷新，通常 7 天；iOS 27 及扩展签名兼容性仍待实际验证。

当前配置不使用 App Groups、推送证书或服务器。停止意图通过 LiveActivityIntent 在主 App 执行。

可用 Mac 时：安装 Xcode 26+ 与 XcodeGen，运行 `xcodegen generate`，打开生成的工程，为两个 target 选择自己的签名团队后运行。

## 真机验收

见 [DEVICE-VALIDATION.md](DEVICE-VALIDATION.md)。核心条件未通过就不能宣布项目实现成功。

## 资料

- [Apple TranslationSession](https://developer.apple.com/documentation/translation/translationsession)
- [Apple Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Clip：后台复制事件与读取内容的区别](https://github.com/rileytestut/Clip)
- [画中画翻译参考项目](https://github.com/Adnan01-01/ClipboardTranslatorIOS)

本工程为独立编写，未复制上述项目源码。
