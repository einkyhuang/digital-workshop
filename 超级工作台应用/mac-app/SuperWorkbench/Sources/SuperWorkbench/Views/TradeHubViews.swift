import SwiftUI
import AppKit

struct TradeLeadsView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "客户与线索",
            subtitle: "聚合计数可上 Pages；客户名/金额仅 private",
            cards: [
                ("线索总数", store.tradeLeadsIndex?.counts?.leadsTotal),
                ("已分层优质", store.tradeLeadsIndex?.counts?.leadsQualified),
                ("客户档案", store.tradeLeadsIndex?.counts?.profiles),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradePipelineView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "开发进度",
            subtitle: "进行中的背调 / 开发信 / 跟进（无客户名）",
            cards: [
                ("开发中", store.tradeLeadsIndex?.counts?.inProgressDev),
                ("员工（本台）", store.scopedBots.count),
                ("待办+进行中", store.scopedTasks.filter { $0.status == "进行中" || $0.status == "待办" }.count),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradeQuotesView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "询盘与报价",
            subtitle: "公开仓仅显示草稿/开口数量",
            cards: [
                ("开口询盘", store.tradeLeadsIndex?.counts?.inquiriesOpen),
                ("报价草稿", store.tradeLeadsIndex?.counts?.quotesDraft),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradeCountsPage: View {
    var title: String
    var subtitle: String
    var cards: [(String, Int?)]
    var activity: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title2.weight(.bold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(cards, id: \.0) { label, value in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(label).font(.caption).foregroundStyle(.secondary)
                            Text(value.map(String.init) ?? "—")
                                .font(.system(size: 28, weight: .bold))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.panel).stroke(SWTheme.borderSoft))
                    }
                }
                if let activity, !activity.isEmpty {
                    Text("最近动态：\(activity)")
                        .font(.caption)
                        .foregroundStyle(SWTheme.textMuted)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text("明细：超级工作台应用/data/private/trade-leads.local.json（gitignore）· 公开索引 trade-leads-index.json")
                    .font(.caption2)
                    .foregroundStyle(SWTheme.textMuted)
            }
            .padding(24)
        }
        .background(SWTheme.pageBg)
    }
}


struct CrmHubIndex: Codable {
    var version: Int?
    var total: Int?
    var pageSize: Int?
    var pageCount: Int?
    var sample: [CrmLeadRow]?
}

struct CrmLeadRow: Codable, Identifiable, Hashable {
    var id: Int
    var company: String?
    var country: String?
    var contact: String?
    var status: String?
    var email: String?
}

struct CrmPdfIndex: Codable {
    var total: Int?
    var items: [CrmPdfItem]?
}

struct CrmPdfItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var bytes: Int?
    var openOnDemand: Bool?
}

struct CrmThumbIndex: Codable {
    var total: Int?
    var failed: Int?
    var bytes: Int?
    var lazyOriginals: Bool?
}

struct CrmCustomersView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var leadsIndex: CrmHubIndex?
    @State private var pageRows: [CrmLeadRow] = []
    @State private var page: Int = 0
    @State private var pdfIndex: CrmPdfIndex?
    @State private var thumbIndex: CrmThumbIndex?
    @State private var loadMs: Double = 0
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .background(SWTheme.pageBg)
        .task { await loadInitial() }
        .onChange(of: page) { _, _ in
            Task { await loadPage(page) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("客户管理").font(.title2.weight(.bold))
            Text("MagicHub 合并优化版 · 客户分页 / 产品 WebP 缩略图 / PDF 仅索引 · 不拖慢工作台启动")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                metric("客户", leadsIndex?.total)
                metric("产品缩略图", thumbIndex?.total)
                metric("PDF 目录", pdfIndex?.total)
                metric("本页加载", loadMs > 0 ? Int(loadMs) : nil, suffix: "ms")
            }
        }
        .padding(24)
    }

    private func metric(_ label: String, _ value: Int?, suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value.map { "\($0)\(suffix)" } ?? "—")
                .font(.system(size: 22, weight: .bold))
        }
        .padding(12)
        .frame(minWidth: 110, alignment: .leading)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
    }

    @ViewBuilder
    private var content: some View {
        if let errorText {
            Text(errorText).foregroundStyle(.red).padding(24)
        } else {
            HStack(alignment: .top, spacing: 0) {
                leadsPane
                Divider()
                sidePane
            }
        }
    }

    private var leadsPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("客户列表（分页）").font(.headline)
                Spacer()
                Button("上一页") { page = max(0, page - 1) }.disabled(page <= 0)
                Text("第 \(page + 1) / \(max(leadsIndex?.pageCount ?? 1, 1)) 页")
                    .font(.caption).foregroundStyle(.secondary)
                Button("下一页") {
                    let maxP = max((leadsIndex?.pageCount ?? 1) - 1, 0)
                    page = min(maxP, page + 1)
                }
                .disabled(page >= max((leadsIndex?.pageCount ?? 1) - 1, 0))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            List(pageRows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.company?.isEmpty == false ? (row.company ?? "") : "未命名客户")
                        .font(.body.weight(.semibold))
                    HStack(spacing: 10) {
                        if let c = row.country, !c.isEmpty { Text(c).font(.caption).foregroundStyle(.secondary) }
                        if let s = row.status, !s.isEmpty { Text(s).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.black.opacity(0.06)).clipShape(Capsule()) }
                        if let e = row.email, !e.isEmpty { Text(e).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var sidePane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("PDF 索引（点开再读原文）").font(.headline)
                if let items = pdfIndex?.items, !items.isEmpty {
                    ForEach(items) { pdf in
                        Button {
                            openPDF(pdf)
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext")
                                VStack(alignment: .leading) {
                                    Text(pdf.name).lineLimit(2).multilineTextAlignment(.leading)
                                    Text(byteLabel(pdf.bytes)).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding(10)
                            .background(SWTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("无 PDF 索引").foregroundStyle(.secondary)
                }
                Text("缩略图 \(thumbIndex?.total.map(String.init) ?? "—") 张 · 原图按需 · private/crm/thumbs")
                    .font(.caption).foregroundStyle(.secondary)
                Text("数据：超级工作台应用/data/private/crm/（gitignore）")
                    .font(.caption2).foregroundStyle(SWTheme.textMuted)
            }
            .padding(20)
            .frame(width: 320, alignment: .leading)
        }
    }

    private func byteLabel(_ n: Int?) -> String {
        guard let n else { return "" }
        if n >= 1_048_576 { return String(format: "%.1f MB", Double(n) / 1_048_576) }
        if n >= 1024 { return String(format: "%.0f KB", Double(n) / 1024) }
        return "\(n) B"
    }

    private func openPDF(_ pdf: CrmPdfItem) {
        let url = store.repoRoot
            .appendingPathComponent("超级工作台应用/data/private/crm/pdfs/originals")
            .appendingPathComponent(pdf.name)
        NSWorkspace.shared.open(url)
    }

    @MainActor
    private func loadInitial() async {
        let t0 = CFAbsoluteTimeGetCurrent()
        let root = store.repoRoot.appendingPathComponent("超级工作台应用/data/private/crm")
        let pub = store.repoRoot.appendingPathComponent("超级工作台应用/data/crm")
        do {
            let idxURL = root.appendingPathComponent("leads/leads-index.json")
            let data: Data
            if FileManager.default.fileExists(atPath: idxURL.path) {
                data = try Data(contentsOf: idxURL)
            } else {
                data = try Data(contentsOf: pub.appendingPathComponent("leads-index.json"))
            }
            leadsIndex = try JSONDecoder().decode(CrmHubIndex.self, from: data)
            let pdfPriv = root.appendingPathComponent("pdfs/pdf-index.json")
            let pdfPub = pub.appendingPathComponent("pdf-index.json")
            if let pdfData = try? Data(contentsOf: FileManager.default.fileExists(atPath: pdfPriv.path) ? pdfPriv : pdfPub) {
                pdfIndex = try? JSONDecoder().decode(CrmPdfIndex.self, from: pdfData)
            }
            let thPriv = root.appendingPathComponent("thumbs/thumb-index.json")
            let thPub = pub.appendingPathComponent("thumb-index.json")
            if let th = try? Data(contentsOf: FileManager.default.fileExists(atPath: thPriv.path) ? thPriv : thPub) {
                thumbIndex = try? JSONDecoder().decode(CrmThumbIndex.self, from: th)
            }
            await loadPage(0)
            loadMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        } catch {
            errorText = "未找到 CRM 索引（请确认 private/crm 已生成本地数据）：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func loadPage(_ pageId: Int) async {
        let t0 = CFAbsoluteTimeGetCurrent()
        let root = store.repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/leads")
        let url = root.appendingPathComponent(String(format: "page-%04d.json", pageId))
        guard let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([CrmLeadRow].self, from: data) else {
            // fallback sample from public index
            pageRows = leadsIndex?.sample ?? []
            loadMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            return
        }
        pageRows = rows
        loadMs = (CFAbsoluteTimeGetCurrent() - t0) * 1000
    }
}
