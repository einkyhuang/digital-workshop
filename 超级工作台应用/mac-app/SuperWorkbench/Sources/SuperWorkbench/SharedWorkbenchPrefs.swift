import Foundation

/// Non-provider workbench prefs (skills, switches, temperature) in Application Support.
enum SharedWorkbenchPrefs {
    static let fileName = "workbench-prefs.json"

    struct Prefs: Codable, Equatable {
        var secretMode: Bool = false
        var autoScan: Bool = true
        var doubleLinkage: Bool = true
        var vectorLimit: Int = 3
        var embeddingModel: String = "text-embedding-v4"
        var temperature: Double = 0.6
        var importedSkills: [SkillItem] = []
        var updatedAt: String = ""
    }

    struct SkillItem: Codable, Equatable, Identifiable {
        var id: String { value }
        var value: String
        var label: String
        var desc: String
        var source: String
    }

    static var fileURL: URL {
        SharedModelStore.supportDir.appendingPathComponent(fileName)
    }

    static func load() -> Prefs {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let prefs = try? JSONDecoder().decode(Prefs.self, from: data) else {
            return Prefs()
        }
        return prefs
    }

    @discardableResult
    static func save(_ prefs: Prefs) -> Bool {
        var p = prefs
        p.updatedAt = ISO8601DateFormatter().string(from: Date())
        do {
            try FileManager.default.createDirectory(at: SharedModelStore.supportDir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(p)
            try data.write(to: fileURL, options: .atomic)
            UserDefaults.standard.set(p.secretMode, forKey: "sw.prefs.secretMode")
            UserDefaults.standard.set(p.temperature, forKey: "sw.prefs.temperature")
            return true
        } catch {
            return false
        }
    }

    static let catalog: [SkillItem] = [
        .init(value: "a11y-debugging", label: "无障碍网页测试", desc: "根据 web.dev 指标诊断语义、focus 焦点及标签合理性", source: "catalog"),
        .init(value: "audit", label: "技术质量审计", desc: "诊断反模式、响应式兼容性以及无障碍等级等全套技术审计", source: "catalog"),
        .init(value: "optimize", label: "性能极限调优", desc: "定位 UI 加载延迟、排版渲染阻塞并执行极速代码体积调优", source: "catalog"),
        .init(value: "polish", label: "设计微小细节精修", desc: "一键完成高保真设计边缘、视觉节奏及磨砂半透明阴影细节打磨", source: "catalog"),
        .init(value: "harden", label: "多语言与健壮性防线", desc: "增加系统异常容错、本地化防线、文本溢出折断等健壮性加固", source: "catalog"),
        .init(value: "distill", label: "设计精简至简", desc: "削减不必要的视觉噪音及重复逻辑，还原极简轻盈本质", source: "catalog"),
        .init(value: "clarify", label: "文案清晰度重构", desc: "对冗长模糊的文字、指示错误、提示反馈等进行地道重写", source: "catalog"),
        .init(value: "typeset", label: "高保真字形排版校正", desc: "优化多语种字型比重、首行行间距及阅读流可视辨识度", source: "catalog"),
        .init(value: "deep-client-analysis", label: "深度客户分析与调研", desc: "基于步骤向导深度调研客商画像、产品与竞争格局，生成高品质 HTML 和 MD 报告", source: "catalog")
    ]
}

extension Notification.Name {
    static let swOpenGlobalSettings = Notification.Name("swOpenGlobalSettings")
}
