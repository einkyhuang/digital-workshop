import AppKit
import SwiftUI
import Foundation

struct PreviewRoot: View {
    let bots: [(String,String,String,String,Int)]
    let metrics: [(String,String)]
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 8).fill(.black).frame(width: 28, height: 28)
                    VStack(alignment: .leading) {
                        Text("超级工作台").font(.headline)
                        Text("v1.0 · 本地原生").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Text("个人主工作区\n\(bots.count) 员工 · 本地 JSON")
                    .font(.caption)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Group {
                    Text("工作台").font(.caption2).foregroundStyle(.secondary)
                    row("总览", true, nil)
                    row("员工档案", false, "\(bots.count)")
                    row("任务看板", false, "3")
                    Text("协作与运维").font(.caption2).foregroundStyle(.secondary)
                    row("群聊协作", false, "1")
                    row("定时巡检", false, nil)
                    Text("组织与规则").font(.caption2).foregroundStyle(.secondary)
                    row("招聘规划", false, "10")
                    row("规则与文档", false, nil)
                }
                Spacer()
                HStack { Circle().fill(.green).frame(width: 8, height: 8); Text("已连接 workspace.json").font(.caption2) }
                    .padding(8).background(Color.green.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                HStack {
                    Circle().fill(.black).frame(width: 24, height: 24).overlay(Text("KY").font(.caption2).foregroundStyle(.white))
                    Text("KY Workspace · ARM64").font(.caption)
                }
            }
            .padding(12)
            .frame(width: 240)
            .background(.white)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("工作台总览").font(.system(size: 28, weight: .bold))
                        Text("数字员工与协作总览 · 数据来自 workspace.json").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("⌘K 搜索").padding(8).background(.white).clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("同步").padding(8).background(Color.gray.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("+ 新建").padding(.horizontal, 12).padding(.vertical, 8).background(.black).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8))
                }
                HStack(spacing: 12) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { _, m in
                        VStack(alignment: .leading) {
                            Text(m.0).font(.system(size: 26, weight: .bold))
                            Text(m.1).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Text("员工速览").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(bots.enumerated()), id: \.offset) { _, b in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(b.1).font(.title2)
                                VStack(alignment: .leading) {
                                    Text(b.0).font(.headline)
                                    Text(b.2).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Text(b.3).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3).background(Color.blue.opacity(0.12)).clipShape(Capsule())
                            ProgressView(value: Double(b.4), total: 100)
                        }
                        .padding(12).background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.965, green: 0.968, blue: 0.973))
        }
        .frame(width: 1280, height: 800)
    }
    func row(_ t: String, _ on: Bool, _ badge: String?) -> some View {
        HStack {
            Text(t).font(.subheadline.weight(on ? .semibold : .regular))
            Spacer()
            if let badge { Text(badge).font(.caption2).padding(.horizontal, 6).background(Color.black.opacity(0.08)).clipShape(Capsule()) }
        }
        .padding(8)
        .background(on ? Color.black.opacity(0.06) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@main
struct PreviewMain {
    static func main() async throws {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/超级工作台/超级工作台应用/data/workspace.json")
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let botsRaw = json["bots"] as! [[String: Any]]
        let emoji = ["chief":"🧠","lead-hunt":"🔍","threadway":"🧵","seo":"📈","hoppi":"📕","mail":"✉️"]
        var bots: [(String,String,String,String,Int)] = []
        for b in botsRaw {
            let id = b["id"] as! String
            bots.append((b["name"] as! String, emoji[id] ?? "🤖", b["role"] as! String, b["layer"] as! String, b["progress"] as! Int))
        }
        let delivered = botsRaw.filter { ($0["lastDelivery"] as? String) != "暂无" }.count
        let metrics = [("\(botsRaw.count)","数字员工"), ("0","进行中"), ("\(delivered)","本周交付"), ("1","群聊数")]
        let pngData: Data = await MainActor.run {
            let view = PreviewRoot(bots: bots, metrics: metrics)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let img = renderer.nsImage,
                  let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                fatalError("render failed")
            }
            return png
        }
        let out = URL(fileURLWithPath: "/tmp/sw-shot/mac-app.png")
        try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: out)
        print("wrote \(out.path) bytes=\(pngData.count)")
    }
}
