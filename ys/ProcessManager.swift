import Foundation

struct ProcessInfoItem: Identifiable {
    let id = UUID()

    let name: String
    let pid: Int32
    let bundleID: String?
}

final class ProcessManager {

    static let shared = ProcessManager()

    private init() {}

    func currentProcess() -> ProcessInfoItem {
        ProcessInfoItem(
            name: ProcessInfo.processInfo.processName,
            pid: Int32(ProcessInfo.processInfo.processIdentifier),
            bundleID: Bundle.main.bundleIdentifier
        )
    }

    func processName(for bundleID: String) -> String? {
        let components = bundleID.split(separator: ".")

        guard let last = components.last else {
            return nil
        }

        return String(last)
    }
}