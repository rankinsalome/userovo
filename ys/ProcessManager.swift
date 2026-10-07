import Darwin
import Foundation

struct ProcessInfoItem: Identifiable {
    let id: String

    let name: String
    let pid: Int32
    let bundleID: String?
    let executablePath: String?
}

final class ProcessManager {

    static let shared = ProcessManager()

    private init() {}

    func currentProcess() -> ProcessInfoItem {
        ProcessInfoItem(
            id: "self-\(ProcessInfo.processInfo.processIdentifier)",
            name: ProcessInfo.processInfo.processName,
            pid: Int32(ProcessInfo.processInfo.processIdentifier),
            bundleID: Bundle.main.bundleIdentifier,
            executablePath: Bundle.main.bundlePath
        )
    }

    func runningProcesses() -> [ProcessInfoItem] {
        var ids = [pid_t]()
        var bufferSize = 0

        let countResult = proc_listpids(
            UInt32(PROC_ALL_PIDS),
            0,
            nil,
            0
        )

        guard countResult > 0 else {
            return []
        }

        bufferSize = Int(countResult) * MemoryLayout<pid_t>.size
        ids = Array(repeating: 0, count: bufferSize / MemoryLayout<pid_t>.size)

        let writeResult = proc_listpids(
            UInt32(PROC_ALL_PIDS),
            0,
            &ids,
            Int32(bufferSize)
        )

        guard writeResult > 0 else {
            return []
        }

        let pidCount = min(writeResult / MemoryLayout<pid_t>.size, ids.count)
        var processes: [ProcessInfoItem] = []
        processes.reserveCapacity(pidCount)

        for index in 0..<pidCount {
            let pid = ids[index]
            guard pid > 0 else {
                continue
            }

            var nameBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
            let nameLength = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            let processName = nameLength > 0
                ? String(cString: nameBuffer)
                : "Unknown"

            var executableBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
            let executableLength = proc_pidpath(pid, &executableBuffer, UInt32(executableBuffer.count))
            let executablePath = executableLength > 0
                ? String(cString: executableBuffer)
                : nil

            let bundleID = executablePath.flatMap { path -> String? in
                let pathURL = URL(fileURLWithPath: path)
                guard let appName = pathURL.deletingPathExtension().lastPathComponent
                        .split(separator: ".").first,
                      !appName.isEmpty else {
                    return nil
                }
                return String(appName)
            }

            processes.append(
                ProcessInfoItem(
                    id: "\(pid)",
                    name: processName,
                    pid: pid,
                    bundleID: bundleID,
                    executablePath: executablePath
                )
            )
        }

        return processes.sorted {
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