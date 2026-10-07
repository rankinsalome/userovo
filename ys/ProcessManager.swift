import Darwin
import Foundation

struct ProcessInfoItem: Identifiable {
    let id: String

    let name: String
    let pid: Int32
    let bundleID: String?
}

final class ProcessManager {

    static let shared = ProcessManager()

    private init() {}

    func currentProcess() -> ProcessInfoItem {
        ProcessInfoItem(
            id: "self-\(ProcessInfo.processInfo.processIdentifier)",
            name: ProcessInfo.processInfo.processName,
            pid: Int32(ProcessInfo.processInfo.processIdentifier),
            bundleID: Bundle.main.bundleIdentifier
        )
    }

    func runningProcesses() -> [ProcessInfoItem] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0

        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0 else {
            return []
        }

        let count = max(size / MemoryLayout<kinfo_proc>.stride, 0)
        var processes = [kinfo_proc](repeating: kinfo_proc(), count: count)

        guard sysctl(&mib, UInt32(mib.count), &processes, &size, nil, 0) == 0 else {
            return []
        }

        return processes.compactMap { process in
            let pid = process.kp_proc.p_pid
            guard pid > 0 else {
                return nil
            }

            let name = withUnsafePointer(to: process.kp_proc.p_comm) { pointer in
                let raw = UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self)
                return String(cString: raw)
            }

            return ProcessInfoItem(
                id: "\(pid)",
                name: name.isEmpty ? "Unknown" : name,
                pid: pid,
                bundleID: nil
            )
        }
        .sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func processName(for bundleID: String) -> String? {
        let components = bundleID.split(separator: ".")

        guard let last = components.last else {
            return nil
        }

        return String(last)
    }
}