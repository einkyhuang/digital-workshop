import Foundation

/// Debounced directory watcher (DispatchSource) — off main; only notifies feedId.
final class FeedWatcher {
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var dirFDs: [String: Int32] = [:]
    private let queue = DispatchQueue(label: "com.ky.superworkbench.feeds", qos: .utility)
    private var debounceWork: [String: DispatchWorkItem] = [:]
    var onChange: ((String) -> Void)?

    func watch(feedId: String, directory: URL) {
        queue.async {
            self.stopLocked(feedId: feedId)
            let path = directory.path
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { return }
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .rename, .delete, .extend, .attrib, .link, .revoke],
                queue: self.queue
            )
            src.setEventHandler { [weak self] in
                self?.scheduleNotify(feedId: feedId)
            }
            src.setCancelHandler {
                close(fd)
            }
            self.dirFDs[feedId] = fd
            self.sources[feedId] = src
            src.resume()
        }
    }

    func stop(feedId: String) {
        queue.async { self.stopLocked(feedId: feedId) }
    }

    func stopAll() {
        queue.async {
            for id in self.sources.keys { self.stopLocked(feedId: id) }
        }
    }

    private func stopLocked(feedId: String) {
        sources[feedId]?.cancel()
        sources[feedId] = nil
        dirFDs[feedId] = nil
        debounceWork[feedId]?.cancel()
        debounceWork[feedId] = nil
    }

    private func scheduleNotify(feedId: String) {
        debounceWork[feedId]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange?(feedId)
        }
        debounceWork[feedId] = work
        queue.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    deinit { stopAll() }
}
