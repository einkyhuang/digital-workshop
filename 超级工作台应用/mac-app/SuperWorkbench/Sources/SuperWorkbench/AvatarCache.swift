import SwiftUI
import AppKit
import Foundation

/// Loads and downsamples bot avatars off the main thread.
/// Synchronous NSImage(contentsOf:) on iCloud paths was freezing launch / overview.
enum AvatarCache {
    private static let lock = NSLock()
    private static var memory: [String: NSImage] = [:]
    private static var inflight: [String: [(NSImage?) -> Void]] = [:]

    static func cached(url: URL) -> NSImage? {
        lock.lock(); defer { lock.unlock() }
        return memory[url.path]
    }

    static func load(url: URL, maxPixel: CGFloat = 256, completion: @escaping (NSImage?) -> Void) {
        let key = url.path
        lock.lock()
        if let hit = memory[key] {
            lock.unlock()
            completion(hit)
            return
        }
        if inflight[key] != nil {
            inflight[key, default: []].append(completion)
            lock.unlock()
            return
        }
        inflight[key] = [completion]
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            let prepared: NSImage? = {
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                guard let src = NSImage(contentsOf: url) else { return nil }
                return downsample(src, maxPixel: maxPixel) ?? src
            }()
            lock.lock()
            if let prepared { memory[key] = prepared }
            let waiters = inflight.removeValue(forKey: key) ?? []
            lock.unlock()
            DispatchQueue.main.async {
                for w in waiters { w(prepared) }
            }
        }
    }

    private static func downsample(_ image: NSImage, maxPixel: CGFloat) -> NSImage? {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxPixel, longest > 0 else { return image }
        let scale = maxPixel / longest
        let target = NSSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let out = NSImage(size: target)
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .medium
        image.draw(
            in: NSRect(origin: .zero, size: target),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        out.unlockFocus()
        return out
    }
}

struct BotAvatarView: View {
    let url: URL
    var fallbackLetter: String
    var fontSize: CGFloat = 32

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.85), .purple.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(String(fallbackLetter.prefix(1)))
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear { startLoad() }
        .onChange(of: url.path) { _, _ in
            image = AvatarCache.cached(url: url)
            startLoad()
        }
    }

    private func startLoad() {
        if let hit = AvatarCache.cached(url: url) {
            image = hit
            return
        }
        AvatarCache.load(url: url) { img in
            image = img
        }
    }
}
